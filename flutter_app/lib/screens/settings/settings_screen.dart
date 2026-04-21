// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../widgets/avatar_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: IEChilliTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: IEChilliTheme.bgSecondary,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: IEChilliTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // Profile card
          _ProfileCard(user: user),

          const SizedBox(height: 24),

          // Settings sections
          _SettingsSection(items: [
            _SettingsItem(
              icon: Icons.star_border,
              iconColor: const Color(0xFFFFD700),
              label: 'Starred',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.history,
              iconColor: const Color(0xFF4FC3F7),
              label: 'Chat history',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 16),

          _SettingsSection(items: [
            _SettingsItem(
              icon: Icons.key_outlined,
              iconColor: IEChilliTheme.chilliRed,
              label: 'Account',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.lock_outline,
              iconColor: const Color(0xFF81C784),
              label: 'Privacy',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.chat_bubble_outline,
              iconColor: const Color(0xFFBA68C8),
              label: 'Chats',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              iconColor: const Color(0xFFFFB74D),
              label: 'Notifications',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 16),

          _SettingsSection(items: [
            _SettingsItem(
              icon: Icons.storage_outlined,
              iconColor: const Color(0xFF4DB6AC),
              label: 'Storage and data',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.help_outline,
              iconColor: const Color(0xFF64B5F6),
              label: 'Help',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.people_outline,
              iconColor: IEChilliTheme.chilliRed,
              label: 'Invite friends',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: IEChilliTheme.chilliRed),
              label: const Text(
                'Log out',
                style: TextStyle(
                  color: IEChilliTheme.chilliRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Version
          const Center(
            child: Text(
              'IEchilli v1.0.0 · by TEKDEV',
              style: TextStyle(color: IEChilliTheme.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: IEChilliTheme.bgCard,
        title: const Text('Log out?', style: TextStyle(color: IEChilliTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: IEChilliTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: IEChilliTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Log out', style: TextStyle(color: IEChilliTheme.chilliRed)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IEChilliTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IEChilliTheme.border),
      ),
      child: Row(
        children: [
          AvatarWidget(
            name: user?.name ?? 'User',
            avatarUrl: user?.avatarUrl,
            size: 62,
            isOnline: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Loading...',
                  style: const TextStyle(
                    color: IEChilliTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (user?.respondSpeed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: IEChilliTheme.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⏰', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          user!.respondSpeed!,
                          style: const TextStyle(
                            color: IEChilliTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    user?.phone ?? '',
                    style: const TextStyle(color: IEChilliTheme.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: IEChilliTheme.textMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: IEChilliTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IEChilliTheme.border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 0.5, color: IEChilliTheme.divider, indent: 54),
              _buildTile(item),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTile(_SettingsItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: item.iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 18),
      ),
      title: Text(
        item.label,
        style: const TextStyle(
          color: IEChilliTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: IEChilliTheme.textMuted, size: 20),
      onTap: item.onTap,
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });
}
