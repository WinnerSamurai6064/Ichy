// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'socket_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final SocketService socketService = SocketService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;
    try {
      _currentUser = await ApiService.getMe();
      await socketService.connect(token);
      notifyListeners();
    } catch (_) {
      await ApiService.clearToken();
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.login(phone: phone, password: password);
      _currentUser = User.fromJson(data['user']);
      await socketService.connect(data['token']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.register(name: name, phone: phone, password: password);
      _currentUser = User.fromJson(data['user']);
      await socketService.connect(data['token']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    socketService.disconnect();
    await ApiService.clearToken();
    _currentUser = null;
    notifyListeners();
  }
}

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  bool _isLoading = false;

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;

  List<Chat> get pinnedChats => _chats.where((c) => c.isPinned).toList();
  List<Chat> get unpinnedChats => _chats.where((c) => !c.isPinned).toList();

  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();
    try {
      _chats = await ApiService.getChats();
      _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void onNewMessage(Message msg) {
    final idx = _chats.indexWhere((c) => c.id == msg.chatId);
    if (idx != -1) {
      // Refresh chat list
      loadChats();
    }
  }
}

class MessageProvider extends ChangeNotifier {
  final Map<String, List<Message>> _messages = {};
  final Map<String, bool> _typing = {};
  bool _isLoading = false;

  List<Message> messagesFor(String chatId) => _messages[chatId] ?? [];
  bool isTyping(String chatId) => _typing[chatId] ?? false;
  bool get isLoading => _isLoading;

  Future<void> loadMessages(String chatId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final msgs = await ApiService.getMessages(chatId);
      _messages[chatId] = msgs.reversed.toList(); // newest last
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void addMessage(Message msg) {
    final list = _messages[msg.chatId] ?? [];
    // Avoid duplicates
    if (!list.any((m) => m.id == msg.id)) {
      list.add(msg);
      _messages[msg.chatId] = list;
      notifyListeners();
    }
  }

  void updateMessage(Message msg) {
    final list = _messages[msg.chatId] ?? [];
    final idx = list.indexWhere((m) => m.id == msg.id);
    if (idx != -1) {
      list[idx] = msg;
      _messages[msg.chatId] = list;
      notifyListeners();
    }
  }

  void setTyping(String chatId, bool typing) {
    _typing[chatId] = typing;
    notifyListeners();
  }

  Future<Message?> sendMessage({
    required String chatId,
    String? text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      final msg = await ApiService.sendMessage(
        chatId: chatId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
      );
      addMessage(msg);
      return msg;
    } catch (_) {
      return null;
    }
  }
}
