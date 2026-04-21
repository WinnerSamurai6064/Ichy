// lib/screens/home/groups_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/conversation_screen.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = context
        .watch<ChatProvider>()
        .chats
        .where((c) => c.isGroup)
        .toList();

    return Scaffold(
      backgroundColor: IEChilliTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: IEChilliTheme.bgSecondary,
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: groups.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('👥', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                      color: IEChilliTheme.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create a group to get started',
                    style: TextStyle(color: IEChilliTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];
                return ListTile(
                  leading: AvatarWidget(
                    name: g.displayName,
                    avatarUrl: g.displayAvatar,
                    size: 50,
                  ),
                  title: Text(
                    g.displayName,
                    style: const TextStyle(
                      color: IEChilliTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${g.participantIds.length} members',
                    style: const TextStyle(color: IEChilliTheme.textMuted, fontSize: 12),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(chat: g),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: IEChilliTheme.chilliRed,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }
}
