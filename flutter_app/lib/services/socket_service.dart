// lib/services/socket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

typedef MessageCallback = void Function(Message message);
typedef TypingCallback = void Function(String chatId, String userId, bool isTyping);
typedef StatusCallback = void Function(String userId, bool isOnline);

class SocketService {
  static const String _wsUrl = 'wss://iechilli-api.vercel.app/api/ws';

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _token;

  final StreamController<Message> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _presenceController = StreamController.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    _token = token;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_wsUrl?token=$token'),
      );
      _isConnected = true;

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _isConnected = false;
      // Will retry connection
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String;

      switch (type) {
        case 'new_message':
          _messageController.add(Message.fromJson(json['data']));
          break;
        case 'message_status':
          // Handle read receipts
          _messageController.add(Message.fromJson(json['data']));
          break;
        case 'typing':
          _typingController.add({
            'chat_id': json['chat_id'],
            'user_id': json['user_id'],
            'is_typing': json['is_typing'],
          });
          break;
        case 'presence':
          _presenceController.add({
            'user_id': json['user_id'],
            'is_online': json['is_online'],
            'last_seen': json['last_seen'],
          });
          break;
      }
    } catch (e) {
      // ignore malformed messages
    }
  }

  void _onError(error) {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_token != null) connect(_token!);
    });
  }

  void sendTyping(String chatId, bool isTyping) {
    _send({'type': 'typing', 'chat_id': chatId, 'is_typing': isTyping});
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _token = null;
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _presenceController.close();
  }
}
