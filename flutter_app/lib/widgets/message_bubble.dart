// lib/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showOptions(context),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? IEChilliTheme.bubbleSent : IEChilliTheme.bubbleReceived,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSenderName)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderId, // ideally resolved name
                        style: const TextStyle(
                          color: IEChilliTheme.chilliGlow,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  if (message.isDeleted)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 14, color: IEChilliTheme.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'This message was deleted',
                          style: TextStyle(
                            color: IEChilliTheme.textMuted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    _buildContent(),

                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.createdAt),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.6)
                              : IEChilliTheme.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        _buildStatusIcon(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: message.mediaUrl != null
                  ? Image.network(
                      message.mediaUrl!,
                      width: 220,
                      height: 160,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(width: 220, height: 160, child: Center(
                      child: Icon(Icons.broken_image, color: IEChilliTheme.textMuted),
                    )),
            ),
            if (message.text != null && message.text!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message.text!,
                style: const TextStyle(color: IEChilliTheme.textPrimary, fontSize: 14),
              ),
            ],
          ],
        );

      case MessageType.audio:
        return Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('0:00', style: TextStyle(color: IEChilliTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return Text(
          message.text ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : IEChilliTheme.textPrimary,
            fontSize: 14.5,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white54);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white54);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: IEChilliTheme.tickRead);
    }
  }

  void _showOptions(BuildContext context) {
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
            _option(context, Icons.reply, 'Reply', () {}),
            _option(context, Icons.copy, 'Copy', () {}),
            _option(context, Icons.star_border, 'Star message', () {}),
            _option(context, Icons.forward, 'Forward', () {}),
            if (isMe)
              _option(context, Icons.delete_outline, 'Delete', () {}, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? IEChilliTheme.chilliRed : IEChilliTheme.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? IEChilliTheme.chilliRed : IEChilliTheme.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }
}
