import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signaling_service.dart';
import 'webrtc_service.dart';

class ConnectionManager {
  final SignalingService signaling;
  final WebRTCService webrtc;

  final String roomId;

  bool isInitiator = false;
  bool remoteDescriptionSet = false;

  final List<RTCIceCandidate> pendingCandidates = [];

  Function(String status)? onStatusChanged;
  Function(String message)? onMessageReceived;

  ConnectionManager({
    required this.signaling,
    required this.webrtc,
    required this.roomId,
  });

  Future<void> initialize() async {
    _setStatus('Initializing...');

    // 1. Create Socket.IO socket.
    signaling.connect();

    // 2. Register signaling listeners.
    _setupSignalingListeners();

    // 3. Register connection callback.
    signaling.onConnected(() {
      _setStatus(
        'Signaling server connected',
      );
    });

    // 4. Initialize WebRTC.
    await webrtc.initialize();

    // 5. Register WebRTC listeners.
    _setupWebRTCListeners();

    _setStatus(
      'Ready to connect',
    );
  }

  void _setupSignalingListeners() {
    signaling.onPeerReady(
          (initiator) async {
        isInitiator = initiator;

        print(
          'CONNECTION: Peer ready',
        );

        print(
          'CONNECTION: Initiator = $isInitiator',
        );

        if (isInitiator) {
          await _createOffer();
        } else {
          _setStatus(
            'Peer found. Waiting for offer...',
          );
        }
      },
    );

    signaling.onSignal(
          (data) async {
        await _handleSignal(data);
      },
    );

    signaling.onPeerLeft(
          () {
        _setStatus(
          'Peer disconnected',
        );
      },
    );
  }

  void _setupWebRTCListeners() {
    webrtc.onIceCandidate = (
        RTCIceCandidate candidate,
        ) {
      signaling.sendSignal(
        roomId,
        {
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    webrtc.onConnectionStateChanged = (
        state,
        ) {
      print(
        'CONNECTION STATE: $state',
      );

      _setStatus(
        'WebRTC: $state',
      );
    };

    webrtc.onDataChannelOpened = () {
      _setStatus(
        'Connected',
      );
    };

    webrtc.onMessageReceived = (
        message,
        ) {
      onMessageReceived?.call(message);
    };
  }

  void join() {
    _setStatus(
      'Joining room $roomId...',
    );

    signaling.joinRoom(roomId);
  }

  Future<void> _createOffer() async {
    _setStatus(
      'Creating connection...',
    );

    await webrtc.createDataChannel();

    final offer =
    await webrtc.createOffer();

    signaling.sendSignal(
      roomId,
      {
        'type': 'offer',
        'sdp': offer.sdp,
      },
    );

    _setStatus(
      'Waiting for peer...',
    );
  }

  Future<void> _handleSignal(
      Map<String, dynamic> data,
      ) async {
    final type = data['type'];

    print(
      'SIGNAL RECEIVED: $type',
    );

    switch (type) {
      case 'offer':
        await _handleOffer(data);
        break;

      case 'answer':
        await _handleAnswer(data);
        break;

      case 'candidate':
        await _handleCandidate(data);
        break;
    }
  }

  Future<void> _handleOffer(
      Map<String, dynamic> data,
      ) async {
    _setStatus(
      'Receiving connection request...',
    );

    final sdp = data['sdp'];

    await webrtc.setRemoteDescription(
      sdp,
      'offer',
    );

    remoteDescriptionSet = true;

    await _flushPendingCandidates();

    final answer =
    await webrtc.createAnswer();

    signaling.sendSignal(
      roomId,
      {
        'type': 'answer',
        'sdp': answer.sdp,
      },
    );

    _setStatus(
      'Connecting...',
    );
  }

  Future<void> _handleAnswer(
      Map<String, dynamic> data,
      ) async {
    final sdp = data['sdp'];

    await webrtc.setRemoteDescription(
      sdp,
      'answer',
    );

    remoteDescriptionSet = true;

    await _flushPendingCandidates();

    _setStatus(
      'Connecting...',
    );
  }

  Future<void> _handleCandidate(
      Map<String, dynamic> data,
      ) async {
    final candidateValue =
    data['candidate'];

    if (candidateValue == null) {
      return;
    }

    final candidate = RTCIceCandidate(
      candidateValue,
      data['sdpMid'],
      data['sdpMLineIndex'],
    );

    if (!remoteDescriptionSet) {
      pendingCandidates.add(candidate);

      return;
    }

    await webrtc.peerConnection!
        .addCandidate(candidate);
  }

  Future<void> _flushPendingCandidates() async {
    for (final candidate
    in pendingCandidates) {
      await webrtc.peerConnection!
          .addCandidate(candidate);
    }

    pendingCandidates.clear();
  }

  void sendText(String text) {
    webrtc.sendText(text);
  }

  void _setStatus(String status) {
    print(
      'QUICKDROP STATUS: $status',
    );

    onStatusChanged?.call(status);
  }

  Future<void> dispose() async {
    await webrtc.dispose();
    signaling.dispose();
  }
}