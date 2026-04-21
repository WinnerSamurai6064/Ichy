// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // ── Change this to your Vercel deployment URL ──
  static const String baseUrl = 'https://iechilli-api.vercel.app/api';

  static String? _authToken;

  static Future<String?> get authToken async {
    _authToken ??= (await SharedPreferences.getInstance()).getString('auth_token');
    return _authToken;
  }

  static Future<Map<String, String>> get _headers async {
    final token = await authToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ─── Auth ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers,
      body: jsonEncode({'name': name, 'phone': phone, 'password': password}),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = _parse(res);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  // ─── Chats ───────────────────────────────────────────────
  static Future<List<Chat>> getChats() async {
    final res = await http.get(
      Uri.parse('$baseUrl/chats'),
      headers: await _headers,
    );
    final data = _parse(res);
    return (data['chats'] as List).map((c) => Chat.fromJson(c)).toList();
  }

  static Future<Chat> createChat({
    required String targetUserId,
    bool isGroup = false,
    String? groupName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chats'),
      headers: await _headers,
      body: jsonEncode({
        'target_user_id': targetUserId,
        'is_group': isGroup,
        'group_name': groupName,
      }),
    );
    return Chat.fromJson(_parse(res)['chat']);
  }

  // ─── Messages ────────────────────────────────────────────
  static Future<List<Message>> getMessages(String chatId, {int page = 1}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/messages/$chatId?page=$page&limit=50'),
      headers: await _headers,
    );
    final data = _parse(res);
    return (data['messages'] as List).map((m) => Message.fromJson(m)).toList();
  }

  static Future<Message> sendMessage({
    required String chatId,
    String? text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/messages/$chatId'),
      headers: await _headers,
      body: jsonEncode({
        'text': text,
        'type': type.name,
        'media_url': mediaUrl,
      }),
    );
    return Message.fromJson(_parse(res)['message']);
  }

  static Future<void> markRead(String chatId) async {
    await http.put(
      Uri.parse('$baseUrl/messages/$chatId/read'),
      headers: await _headers,
    );
  }

  // ─── Media Upload (Cloudflare R2 via Vercel) ─────────────
  static Future<String> uploadMedia(File file, String mimeType) async {
    final headers = await _headers;
    // Step 1: Request presigned URL from our Vercel function
    final res = await http.post(
      Uri.parse('$baseUrl/upload/presign'),
      headers: headers,
      body: jsonEncode({'mime_type': mimeType, 'file_size': file.lengthSync()}),
    );
    final data = _parse(res);
    final presignedUrl = data['upload_url'] as String;
    final publicUrl = data['public_url'] as String;

    // Step 2: Upload directly to R2 using the presigned URL
    final uploadRes = await http.put(
      Uri.parse(presignedUrl),
      headers: {'Content-Type': mimeType},
      body: await file.readAsBytes(),
    );
    if (uploadRes.statusCode != 200 && uploadRes.statusCode != 204) {
      throw Exception('R2 upload failed: ${uploadRes.statusCode}');
    }

    return publicUrl;
  }

  // ─── Users ───────────────────────────────────────────────
  static Future<User> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers,
    );
    return User.fromJson(_parse(res)['user']);
  }

  static Future<List<User>> searchUsers(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/search?q=${Uri.encodeComponent(query)}'),
      headers: await _headers,
    );
    final data = _parse(res);
    return (data['users'] as List).map((u) => User.fromJson(u)).toList();
  }

  static Future<User> updateProfile({
    String? name,
    String? about,
    String? avatarUrl,
    String? respondSpeed,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers,
      body: jsonEncode({
        if (name != null) 'name': name,
        if (about != null) 'about': about,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (respondSpeed != null) 'respond_speed': respondSpeed,
      }),
    );
    return User.fromJson(_parse(res)['user']);
  }

  // ─── Status ──────────────────────────────────────────────
  static Future<List<StatusUpdate>> getStatuses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/statuses'),
      headers: await _headers,
    );
    final data = _parse(res);
    return (data['statuses'] as List).map((s) => StatusUpdate.fromJson(s)).toList();
  }

  static Future<StatusUpdate> postStatus({
    String? text,
    String? mediaUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/statuses'),
      headers: await _headers,
      body: jsonEncode({'text': text, 'media_url': mediaUrl}),
    );
    return StatusUpdate.fromJson(_parse(res)['status']);
  }

  // ─── Helpers ─────────────────────────────────────────────
  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(body['error'] ?? 'Request failed', res.statusCode);
    }
    return body;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
