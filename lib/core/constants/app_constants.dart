import 'dart:io';

class AppConstants {
  static String get signalingServer {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    if (Platform.isWindows) {
      return 'http://localhost:3000';
    }

    return 'http://localhost:3000';
  }
}