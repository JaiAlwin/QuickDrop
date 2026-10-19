import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'services/connection_manager.dart';
import 'services/signaling_service.dart';
import 'services/webrtc_service.dart';

void main() {
  runApp(
    const QuickDropApp(),
  );
}

class QuickDropApp extends StatelessWidget {
  const QuickDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickDrop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final roomController =
  TextEditingController(
    text: 'quickdrop-test',
  );

  ConnectionManager? connectionManager;

  String status = 'Not connected';

  String receivedMessage = '';

  void connect() async {
    final roomId =
    roomController.text.trim();

    if (roomId.isEmpty) {
      return;
    }

    final signaling = SignalingService(
      serverUrl:
      AppConstants.signalingServer,
    );

    final webrtc = WebRTCService();

    final manager = ConnectionManager(
      signaling: signaling,
      webrtc: webrtc,
      roomId: roomId,
    );

    connectionManager = manager;

    manager.onStatusChanged = (newStatus) {
      if (!mounted) return;

      setState(() {
        status = newStatus;
      });
    };

    manager.onMessageReceived = (message) {
      if (!mounted) return;

      setState(() {
        receivedMessage = message;
      });
    };

    await manager.initialize();

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    manager.join();
  }

  void sendTestMessage() {
    connectionManager?.sendText(
      'Hello from QuickDrop!',
    );
  }

  @override
  void dispose() {
    roomController.dispose();
    connectionManager?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickDrop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.devices_rounded,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'QuickDrop',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Pair once. Pipe anywhere. Use. Done.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: connect,
              icon: const Icon(
                Icons.link,
              ),
              label: const Text(
                'Connect Device',
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Status: $status',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            if (status == 'Connected')
              FilledButton(
                onPressed:
                sendTestMessage,
                child: const Text(
                  'Send Test Message',
                ),
              ),

            const SizedBox(height: 20),

            if (receivedMessage.isNotEmpty)
              Text(
                'Received:\n$receivedMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}