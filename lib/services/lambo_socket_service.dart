import 'dart:io';

class LamboSocketService {
  Future<WebSocket> connect(Uri uri) => WebSocket.connect(uri.toString());
}
