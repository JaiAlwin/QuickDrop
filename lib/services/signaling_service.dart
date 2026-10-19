import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignalingService {
  IO.Socket? socket;

  final String serverUrl;

  SignalingService({
    required this.serverUrl,
  });

  void connect() {
    if (socket != null) {
      return;
    }

    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print('SIGNALING: Connected');
    });

    socket!.onDisconnect((_) {
      print('SIGNALING: Disconnected');
    });

    socket!.onConnectError((error) {
      print(
        'SIGNALING: Connection error: $error',
      );
    });

    socket!.onError((error) {
      print(
        'SIGNALING: Error: $error',
      );
    });

    socket!.connect();
  }
  void onConnected(
      void Function() callback,
      ) {
    if (socket == null) {
      return;
    }

    socket!.on(
      'connect',
          (_) {
        callback();
      },
    );
  }
  void joinRoom(String roomId) {
    if (socket == null) {
      print(
        'SIGNALING: Cannot join room. Socket not initialized.',
      );
      return;
    }

    socket!.emit(
      'join-room',
      {
        'roomId': roomId,
      },
    );
  }

  void sendSignal(
      String roomId,
      Map<String, dynamic> data,
      ) {
    if (socket == null) {
      print(
        'SIGNALING: Cannot send signal. Socket not initialized.',
      );
      return;
    }

    socket!.emit(
      'signal',
      {
        'roomId': roomId,
        'data': data,
      },
    );
  }

  void onSignal(
      void Function(Map<String, dynamic> data) callback,
      ) {
    if (socket == null) {
      print(
        'SIGNALING: Cannot register signal listener.',
      );
      return;
    }

    socket!.on(
      'signal',
          (data) {
        if (data is Map &&
            data['data'] is Map) {
          callback(
            Map<String, dynamic>.from(
              data['data'] as Map,
            ),
          );
        }
      },
    );
  }

  void onPeerReady(
      void Function(bool initiator) callback,
      ) {
    if (socket == null) {
      print(
        'SIGNALING: Cannot register peer-ready listener.',
      );
      return;
    }

    socket!.on(
      'peer-ready',
          (data) {
        if (data is Map) {
          callback(
            data['initiator'] == true,
          );
        }
      },
    );
  }

  void onPeerLeft(
      void Function() callback,
      ) {
    if (socket == null) {
      print(
        'SIGNALING: Cannot register peer-left listener.',
      );
      return;
    }

    socket!.on(
      'peer-left',
          (_) {
        callback();
      },
    );
  }

  void dispose() {
    socket?.dispose();
    socket = null;
  }
}