import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': 'stun:stun.l.google.com:19302',
      },
    ],
  };

  Function(RTCIceCandidate candidate)? onIceCandidate;
  Function(String state)? onConnectionStateChanged;
  Function(String message)? onMessageReceived;
  Function()? onDataChannelOpened;

  Future<void> initialize() async {
    peerConnection = await createPeerConnection(
      configuration,
    );

    peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        print(
          'WEBRTC: ICE candidate generated',
        );

        onIceCandidate?.call(candidate);
      }
    };

    peerConnection!.onConnectionState = (state) {
      print(
        'WEBRTC: Connection state = $state',
      );

      onConnectionStateChanged?.call(
        state.toString(),
      );
    };

    peerConnection!.onIceConnectionState = (state) {
      print(
        'WEBRTC: ICE connection state = $state',
      );
    };

    peerConnection!.onDataChannel = (channel) {
      print(
        'WEBRTC: DataChannel received',
      );

      dataChannel = channel;

      _configureDataChannel(channel);
    };
  }

  Future<void> createDataChannel() async {
    if (peerConnection == null) {
      throw Exception(
        'PeerConnection has not been initialized',
      );
    }

    final channel =
    await peerConnection!.createDataChannel(
      'quickdrop',
      RTCDataChannelInit(),
    );

    dataChannel = channel;

    _configureDataChannel(channel);
  }

  void _configureDataChannel(
      RTCDataChannel channel,
      ) {
    channel.onDataChannelState = (state) {
      print(
        'DATACHANNEL: $state',
      );

      if (state ==
          RTCDataChannelState.RTCDataChannelOpen) {
        print(
          'DATACHANNEL: OPEN',
        );

        onDataChannelOpened?.call();
      }
    };

    channel.onMessage = (message) {
      print(
        'DATACHANNEL RECEIVED: ${message.text}',
      );

      onMessageReceived?.call(
        message.text,
      );
    };
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer =
    await peerConnection!.createOffer();

    await peerConnection!.setLocalDescription(
      offer,
    );

    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer =
    await peerConnection!.createAnswer();

    await peerConnection!.setLocalDescription(
      answer,
    );

    return answer;
  }

  Future<void> setRemoteDescription(
      String sdp,
      String type,
      ) async {
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        sdp,
        type,
      ),
    );
  }

  Future<void> addIceCandidate(
      String candidate,
      String? sdpMid,
      int? sdpMLineIndex,
      ) async {
    await peerConnection!.addCandidate(
      RTCIceCandidate(
        candidate,
        sdpMid,
        sdpMLineIndex,
      ),
    );
  }

  void sendText(String text) {
    if (dataChannel == null) {
      print(
        'DATACHANNEL: Not available',
      );
      return;
    }

    dataChannel!.send(
      RTCDataChannelMessage(text),
    );
  }

  Future<void> dispose() async {
    await dataChannel?.close();
    await peerConnection?.close();

    dataChannel = null;
    peerConnection = null;
  }
}