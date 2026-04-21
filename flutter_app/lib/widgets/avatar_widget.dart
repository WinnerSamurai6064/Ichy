// lib/widgets/avatar_widget.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final bool isOnline;

  const AvatarWidget({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
    this.isOnline = false,
  });

  Color _colorFromName(String name) {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF8E24AA),
      const Color(0xFF1E88E5),
      const Color(0xFF00897B),
      const Color(0xFFF4511E),
      const Color(0xFF6D4C41),
      const Color(0xFF3949AB),
      const Color(0xFF00ACC1),
    ];
    final idx = name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _colorFromName(name),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _initials_(context),
                  placeholder: (_, __) => _initials_(context),
                )
              : _initials_(context),
        ),
        if (isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: IEChilliTheme.online,
                shape: BoxShape.circle,
                border: Border.all(color: IEChilliTheme.bgSecondary, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials_(BuildContext context) {
    return Center(
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}
