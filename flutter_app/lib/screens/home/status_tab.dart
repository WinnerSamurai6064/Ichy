// lib/screens/home/status_tab.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IEChilliTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: IEChilliTheme.bgSecondary,
        title: const Text('Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: IEChilliTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // My status
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: IEChilliTheme.border, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: IEChilliTheme.bgCard,
                    child: Icon(Icons.person, color: IEChilliTheme.textMuted),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: IEChilliTheme.chilliRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            title: const Text(
              'My status',
              style: TextStyle(color: IEChilliTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Tap to add status update',
              style: TextStyle(color: IEChilliTheme.textMuted, fontSize: 12),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recent updates',
              style: TextStyle(
                color: IEChilliTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Placeholder
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  Text('🌶️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text(
                    'No recent status updates',
                    style: TextStyle(color: IEChilliTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: IEChilliTheme.chilliRed,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
