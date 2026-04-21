// lib/screens/home/chats_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../chat/conversation_screen.dart';
import '../../widgets/avatar_widget.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IEChilliTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: IEChilliTheme.bgSecondary,
        title: const Text(
          'IEchilli',
          style: TextStyle(
            color: IEChilliTheme.chilliGlow,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: IEChilliTheme.textSecondary),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, cp, _) {
          if (cp.isLoading && cp.chats.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: IEChilliTheme.chilliRed),
            );
          }

          final chats = _query.isEmpty
              ? cp.chats
              : cp.chats
                  .where((c) => c.displayName
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🌶️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      color: IEChilliTheme.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Start a new conversation',
                    style: TextStyle(color: IEChilliTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: IEChilliTheme.chilliRed,
            onRefresh: () => cp.loadChats(),
            child: ListView(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: IEChilliTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search or start new chat',
                      prefixIcon: const Icon(Icons.search, color: IEChilliTheme.textMuted, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: IEChilliTheme.textMuted, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                ...chats.map((chat) => _ChatTile(chat: chat)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newChat(context),
        backgroundColor: IEChilliTheme.chilliRed,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.chat),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: IEChilliTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(Icons.group_add_outlined, 'New group', () {}),
            _menuItem(Icons.archive_outlined, 'Archived chats', () {}),
            _menuItem(Icons.star_border, 'Starred messages', () {}),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: IEChilliTheme.textSecondary),
      title: Text(label, style: const TextStyle(color: IEChilliTheme.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _newChat(BuildContext context) {
    // Navigate to new chat / contact search
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final lastMsg = chat.lastMessage;
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(chat: chat),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AvatarWidget(
              name: chat.displayName,
              avatarUrl: chat.displayAvatar,
              size: 52,
              isOnline: chat.otherUser?.isOnline ?? false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (chat.isPinned) ...[
                        const Icon(Icons.push_pin, size: 12, color: IEChilliTheme.textMuted),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          chat.displayName,
                          style: const TextStyle(
                            color: IEChilliTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastMsg != null
                            ? timeago.format(lastMsg.createdAt, locale: 'en_short')
                            : '',
                        style: TextStyle(
                          color: hasUnread
                              ? IEChilliTheme.chilliRed
                              : IEChilliTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Tick icons for sent messages
                      if (lastMsg != null && lastMsg.senderId ==
                          context.read<AuthProvider>().currentUser?.id) ...[
                        _buildTick(lastMsg.status),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          _previewText(lastMsg),
                          style: TextStyle(
                            color: hasUnread
                                ? IEChilliTheme.textSecondary
                                : IEChilliTheme.textMuted,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: chat.isMuted
                                ? IEChilliTheme.textMuted
                                : IEChilliTheme.chilliRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTick(MessageStatus status) {
    if (status == MessageStatus.sending) {
      return const Icon(Icons.access_time, size: 14, color: IEChilliTheme.textMuted);
    }
    if (status == MessageStatus.sent) {
      return const Icon(Icons.check, size: 14, color: IEChilliTheme.textMuted);
    }
    if (status == MessageStatus.delivered) {
      return const Icon(Icons.done_all, size: 14, color: IEChilliTheme.textMuted);
    }
    return const Icon(Icons.done_all, size: 14, color: IEChilliTheme.tickRead);
  }

  String _previewText(Message? msg) {
    if (msg == null) return '';
    if (msg.isDeleted) return '🚫 This message was deleted';
    switch (msg.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎙️ Audio';
      case MessageType.document:
        return '📄 Document';
      case MessageType.sticker:
        return '😄 Sticker';
      default:
        return msg.text ?? '';
    }
  }
}
