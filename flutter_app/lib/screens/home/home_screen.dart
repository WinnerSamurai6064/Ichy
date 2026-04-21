// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import 'chats_tab.dart';
import 'status_tab.dart';
import 'groups_tab.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ChatsTab(),
    StatusTab(),
    GroupsTab(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChats();
      // Listen to incoming socket messages
      final auth = context.read<AuthProvider>();
      auth.socketService.messageStream.listen((msg) {
        context.read<MessageProvider>().addMessage(msg);
        context.read<ChatProvider>().onNewMessage(msg);
      });
      auth.socketService.typingStream.listen((data) {
        context.read<MessageProvider>().setTyping(
          data['chat_id'],
          data['is_typing'] == true,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chats'),
      _NavItem(icon: Icons.circle_outlined, activeIcon: Icons.circle, label: 'Status'),
      _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Groups'),
      _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: IEChilliTheme.bgSecondary,
        border: Border(top: BorderSide(color: IEChilliTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Unread badge for chats
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive
                                  ? IEChilliTheme.chilliRed
                                  : IEChilliTheme.textMuted,
                              size: 24,
                            ),
                            if (i == 0)
                              Consumer<ChatProvider>(
                                builder: (_, cp, __) {
                                  final total = cp.chats.fold<int>(
                                    0, (sum, c) => sum + c.unreadCount);
                                  if (total == 0) return const SizedBox();
                                  return Positioned(
                                    top: -4,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: IEChilliTheme.chilliRed,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        total > 99 ? '99+' : '$total',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? IEChilliTheme.chilliRed
                                : IEChilliTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
