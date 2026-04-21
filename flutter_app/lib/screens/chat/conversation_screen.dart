// lib/screens/chat/conversation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/message_bubble.dart';

class ConversationScreen extends StatefulWidget {
  final Chat chat;
  const ConversationScreen({super.key, required this.chat});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showAttachMenu = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages(widget.chat.id);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (animated) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  void _onTextChanged(String v) {
    final auth = context.read<AuthProvider>();
    if (v.isNotEmpty && !_isTyping) {
      _isTyping = true;
      auth.socketService.sendTyping(widget.chat.id, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        auth.socketService.sendTyping(widget.chat.id, false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _isTyping = false;
    context.read<AuthProvider>().socketService.sendTyping(widget.chat.id, false);

    await context.read<MessageProvider>().sendMessage(
      chatId: widget.chat.id,
      text: text,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: IEChilliTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: IEChilliTheme.bgSecondary,
        leadingWidth: 32,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {}, // Open contact/group info
          child: Row(
            children: [
              AvatarWidget(
                name: widget.chat.displayName,
                avatarUrl: widget.chat.displayAvatar,
                size: 38,
                isOnline: widget.chat.otherUser?.isOnline ?? false,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.displayName,
                    style: const TextStyle(
                      color: IEChilliTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<MessageProvider>(
                    builder: (_, mp, __) {
                      final typing = mp.isTyping(widget.chat.id);
                      return Text(
                        typing
                            ? 'typing...'
                            : (widget.chat.otherUser?.isOnline == true
                                ? 'online'
                                : 'tap for info'),
                        style: TextStyle(
                          color: typing
                              ? IEChilliTheme.chilliGlow
                              : IEChilliTheme.textMuted,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat background pattern
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, mp, _) {
                final messages = mp.messagesFor(widget.chat.id);

                if (mp.isLoading && messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: IEChilliTheme.chilliRed),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final prevMsg = i > 0 ? messages[i - 1] : null;
                    final isMe = msg.senderId == me?.id;

                    // Date separator
                    final showDate = prevMsg == null ||
                        !_isSameDay(prevMsg.createdAt, msg.createdAt);

                    return Column(
                      children: [
                        if (showDate) _DateSeparator(date: msg.createdAt),
                        MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showSenderName: widget.chat.isGroup && !isMe,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildInputBar() {
    return Container(
      color: IEChilliTheme.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach button
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: IEChilliTheme.textMuted),
              onPressed: () => setState(() => _showAttachMenu = !_showAttachMenu),
            ),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: IEChilliTheme.bgInput,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        onChanged: _onTextChanged,
                        maxLines: null,
                        style: const TextStyle(
                          color: IEChilliTheme.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 6),
                      child: IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined,
                            color: IEChilliTheme.textMuted, size: 22),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Send / Mic button
            ValueListenableBuilder(
              valueListenable: _textCtrl,
              builder: (_, value, __) {
                final hasText = value.text.isNotEmpty;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    key: ValueKey(hasText),
                    onTap: hasText ? _sendMessage : null,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: IEChilliTheme.chilliRed,
                        boxShadow: [
                          BoxShadow(
                            color: IEChilliTheme.chilliRed.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        hasText ? Icons.send : Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _format() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: IEChilliTheme.border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: IEChilliTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _format(),
                style: const TextStyle(
                  color: IEChilliTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: IEChilliTheme.border, height: 1)),
        ],
      ),
    );
  }
}
