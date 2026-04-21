// lib/models/models.dart

class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? about;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? respondSpeed; // e.g. "Slow to respond"

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.about,
    this.isOnline = false,
    this.lastSeen,
    this.respondSpeed,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        avatarUrl: json['avatar_url'],
        phone: json['phone'],
        about: json['about'],
        isOnline: json['is_online'] ?? false,
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'])
            : null,
        respondSpeed: json['respond_speed'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'phone': phone,
        'about': about,
        'is_online': isOnline,
        'last_seen': lastSeen?.toIso8601String(),
        'respond_speed': respondSpeed,
      };
}

enum MessageType { text, image, video, audio, document, sticker }

enum MessageStatus { sending, sent, delivered, read }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final String? mediaUrl;
  final String? mediaThumb;
  final Message? replyTo;
  final List<Reaction> reactions;
  final bool isDeleted;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.mediaUrl,
    this.mediaThumb,
    this.replyTo,
    this.reactions = const [],
    this.isDeleted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        chatId: json['chat_id'],
        senderId: json['sender_id'],
        text: json['text'],
        type: MessageType.values.firstWhere(
          (e) => e.name == (json['type'] ?? 'text'),
          orElse: () => MessageType.text,
        ),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == (json['status'] ?? 'sent'),
          orElse: () => MessageStatus.sent,
        ),
        createdAt: DateTime.parse(json['created_at']),
        mediaUrl: json['media_url'],
        mediaThumb: json['media_thumb'],
        reactions: (json['reactions'] as List<dynamic>? ?? [])
            .map((r) => Reaction.fromJson(r))
            .toList(),
        isDeleted: json['is_deleted'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'text': text,
        'type': type.name,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'media_url': mediaUrl,
        'media_thumb': mediaThumb,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'is_deleted': isDeleted,
      };

  Message copyWith({MessageStatus? status}) => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        text: text,
        type: type,
        status: status ?? this.status,
        createdAt: createdAt,
        mediaUrl: mediaUrl,
        mediaThumb: mediaThumb,
        replyTo: replyTo,
        reactions: reactions,
        isDeleted: isDeleted,
      );
}

class Reaction {
  final String userId;
  final String emoji;

  Reaction({required this.userId, required this.emoji});

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      Reaction(userId: json['user_id'], emoji: json['emoji']);

  Map<String, dynamic> toJson() => {'user_id': userId, 'emoji': emoji};
}

class Chat {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatarUrl;
  final List<String> participantIds;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool isMuted;
  final bool isPinned;

  // Resolved participant (for 1-on-1)
  final User? otherUser;

  Chat({
    required this.id,
    required this.isGroup,
    this.groupName,
    this.groupAvatarUrl,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.isMuted = false,
    this.isPinned = false,
    this.otherUser,
  });

  String get displayName => isGroup ? (groupName ?? 'Group') : (otherUser?.name ?? 'Unknown');
  String? get displayAvatar => isGroup ? groupAvatarUrl : otherUser?.avatarUrl;

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'],
        isGroup: json['is_group'] ?? false,
        groupName: json['group_name'],
        groupAvatarUrl: json['group_avatar_url'],
        participantIds: List<String>.from(json['participant_ids'] ?? []),
        lastMessage: json['last_message'] != null
            ? Message.fromJson(json['last_message'])
            : null,
        unreadCount: json['unread_count'] ?? 0,
        updatedAt: DateTime.parse(json['updated_at']),
        isMuted: json['is_muted'] ?? false,
        isPinned: json['is_pinned'] ?? false,
        otherUser: json['other_user'] != null
            ? User.fromJson(json['other_user'])
            : null,
      );
}

class StatusUpdate {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? mediaUrl;
  final String? text;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;

  StatusUpdate({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.mediaUrl,
    this.text,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isViewed => viewedBy.isNotEmpty; // simplified

  factory StatusUpdate.fromJson(Map<String, dynamic> json) => StatusUpdate(
        id: json['id'],
        userId: json['user_id'],
        userName: json['user_name'],
        userAvatar: json['user_avatar'],
        mediaUrl: json['media_url'],
        text: json['text'],
        createdAt: DateTime.parse(json['created_at']),
        expiresAt: DateTime.parse(json['expires_at']),
        viewedBy: List<String>.from(json['viewed_by'] ?? []),
      );
}
