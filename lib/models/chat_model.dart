class Chat {
  final String id;
  final String chatId;
  final String participantId;
  final String participantName;
  final String? participantImage;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isGroupChat;
  final List<Map<String, dynamic>> participants;

  const Chat({
    required this.id,
    required this.chatId,
    required this.participantId,
    required this.participantName,
    this.participantImage,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isGroupChat,
    required this.participants,
  });

  /// Creates a copy of this Chat with the given fields replaced by new values
  Chat copyWith({
    String? id,
    String? chatId,
    String? participantId,
    String? participantName,
    String? participantImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isGroupChat,
    List<Map<String, dynamic>>? participants,
  }) {
    return Chat(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantImage: participantImage ?? this.participantImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      participants: participants ?? this.participants,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      // Extract participant information from the participants array
      String participantId = '';
      String participantName = '';
      String? participantImage;
      
      if (json['participants'] != null && json['participants'] is List) {
        final participants = json['participants'] as List;
        if (participants.isNotEmpty) {
          final participant = participants.first;
          if (participant is Map<String, dynamic>) {
            participantId = participant['_id']?.toString() ?? '';
            participantName = participant['name']?.toString() ?? '';
            participantImage = participant['profile']?.toString();
          }
        }
      }

      // Handle lastMessage which might be a Map or String
      String lastMessage = '';
      if (json['lastMessage'] != null) {
        if (json['lastMessage'] is String) {
          lastMessage = json['lastMessage'];
        } else if (json['lastMessage'] is Map<String, dynamic>) {
          // Extract content from message object
          lastMessage = json['lastMessage']['content']?.toString() ?? '';
        }
      }

      // Handle lastMessageTime which might be a Map or String
      DateTime? lastMessageTime;
      if (json['lastMessageTime'] != null) {
        if (json['lastMessageTime'] is String) {
          lastMessageTime = DateTime.tryParse(json['lastMessageTime']);
        } else if (json['lastMessageTime'] is Map<String, dynamic>) {
          // Extract timestamp from message object
          final timestamp = json['lastMessageTime']['timestamp'] ?? json['lastMessageTime']['sentAt'];
          if (timestamp != null) {
            lastMessageTime = DateTime.tryParse(timestamp.toString());
          }
        }
      }

      // Safely handle participants list with proper type conversion
      List<Map<String, dynamic>> participants = [];
      if (json['participants'] != null && json['participants'] is List) {
        final participantsList = json['participants'] as List;
        participants = participantsList.map((p) {
          if (p is Map<String, dynamic>) {
            return Map<String, dynamic>.from(p);
          } else if (p is Map) {
            // Handle case where p is a Map but not Map<String, dynamic>
            return Map<String, dynamic>.from(p.cast<String, dynamic>());
          } else {
            // Skip invalid participants
            return <String, dynamic>{};
          }
        }).where((p) => p.isNotEmpty).toList();
      }

      return Chat(
        id: json['_id']?.toString() ?? '',
        chatId: json['_id']?.toString() ?? '', // Use _id as chatId
        participantId: participantId,
        participantName: participantName,
        participantImage: participantImage,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: json['unreadCount'] is int ? json['unreadCount'] : 0,
        isGroupChat: json['isGroupChat'] is bool ? json['isGroupChat'] : false,
        participants: participants,
      );
    } catch (e) {
      print('Error parsing chat: $e');
      print('Chat data: $json');
      // Return a default chat object to prevent app crash
      return Chat(
        id: json['_id']?.toString() ?? '',
        chatId: json['_id']?.toString() ?? '',
        participantId: '',
        participantName: 'Unknown User',
        participantImage: null,
        lastMessage: 'Error loading chat',
        lastMessageTime: null,
        unreadCount: 0,
        isGroupChat: false,
        participants: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'participantId': participantId,
      'participantName': participantName,
      'participantImage': participantImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isGroupChat': isGroupChat,
      'participants': participants,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.chatId == chatId &&
        other.participantId == participantId &&
        other.participantName == participantName &&
        other.participantImage == participantImage &&
        other.lastMessage == lastMessage &&
        other.lastMessageTime == lastMessageTime &&
        other.unreadCount == unreadCount &&
        other.isGroupChat == isGroupChat &&
        other.participants == participants;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        participantId.hashCode ^
        participantName.hashCode ^
        participantImage.hashCode ^
        lastMessage.hashCode ^
        lastMessageTime.hashCode ^
        unreadCount.hashCode ^
        isGroupChat.hashCode ^
        participants.hashCode;
  }

  @override
  String toString() {
    return 'Chat(id: $id, chatId: $chatId, participantId: $participantId, participantName: $participantName, lastMessage: $lastMessage)';
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final String? fileUrl;
  final DateTime timestamp;
  final bool isRead;
  final String status;
  final DateTime? sentAt;
  final DateTime? seenAt;
  final List<String> seenBy;
  final List<String> deletedBy;
  final List<Map<String, dynamic>> reactions;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.fileUrl,
    required this.timestamp,
    required this.isRead,
    this.status = 'sent',
    this.sentAt,
    this.seenAt,
    this.seenBy = const [],
    this.deletedBy = const [],
    this.reactions = const [],
  });

  /// Creates a copy of this Message with the given fields replaced by new values
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? messageType,
    String? fileUrl,
    DateTime? timestamp,
    bool? isRead,
    String? status,
    DateTime? sentAt,
    DateTime? seenAt,
    List<String>? seenBy,
    List<String>? deletedBy,
    List<Map<String, dynamic>>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      seenAt: seenAt ?? this.seenAt,
      seenBy: seenBy ?? this.seenBy,
      deletedBy: deletedBy ?? this.deletedBy,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      // Safely handle list fields with proper type conversion
      List<String> seenBy = [];
      if (json['seenBy'] != null) {
        if (json['seenBy'] is List) {
          final seenByList = json['seenBy'] as List;
          seenBy = seenByList.map((item) {
            if (item is String) {
              return item;
            } else {
              return item.toString();
            }
          }).toList();
        } else if (json['seenBy'] is String) {
          // Handle case where seenBy might be a single string
          seenBy = [json['seenBy']];
        }
      }

      List<String> deletedBy = [];
      if (json['deletedBy'] != null) {
        if (json['deletedBy'] is List) {
          final deletedByList = json['deletedBy'] as List;
          deletedBy = deletedByList.map((item) {
            if (item is String) {
              return item;
            } else {
              return item.toString();
            }
          }).toList();
        } else if (json['deletedBy'] is String) {
          // Handle case where deletedBy might be a single string
          deletedBy = [json['deletedBy']];
        }
      }

      List<Map<String, dynamic>> reactions = [];
      if (json['reactions'] != null && json['reactions'] is List) {
        final reactionsList = json['reactions'] as List;
        reactions = reactionsList.map((r) {
          if (r is Map<String, dynamic>) {
            return Map<String, dynamic>.from(r);
          } else if (r is Map) {
            try {
              return Map<String, dynamic>.from(r.cast<String, dynamic>());
            } catch (e) {
              // If casting fails, create an empty map
              return <String, dynamic>{};
            }
          } else {
            // Skip invalid reactions
            return <String, dynamic>{};
          }
        }).where((r) => r.isNotEmpty).toList();
      }

      return Message(
        id: json['id'] ?? json['_id'] ?? '',
        chatId: json['chatId'] ?? '',
        senderId: json['senderId'] ?? '',
        content: json['content'] ?? '',
        messageType: json['messageType'] ?? 'text',
        fileUrl: json['fileUrl'],
        timestamp: DateTime.tryParse(json['timestamp'] ?? json['sentAt'] ?? '') ?? DateTime.now(),
        isRead: json['isRead'] ?? json['status'] == 'seen' || json['seenAt'] != null,
        status: json['status'] ?? 'sent',
        sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
        seenAt: json['seenAt'] != null ? DateTime.tryParse(json['seenAt']) : null,
        seenBy: seenBy,
        deletedBy: deletedBy,
        reactions: reactions,
      );
    } catch (e) {
      print('Error parsing message: $e');
      print('Message data: $json');
      // Return a default message object to prevent app crash
      return Message(
        id: json['_id'] ?? '',
        chatId: json['chatId'] ?? '',
        senderId: json['senderId'] ?? '',
        content: 'Error loading message',
        messageType: 'text',
        fileUrl: null,
        timestamp: DateTime.now(),
        isRead: false,
        status: 'sent',
        sentAt: null,
        seenAt: null,
        seenBy: [],
        deletedBy: [],
        reactions: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'status': status,
      'sentAt': sentAt?.toIso8601String(),
      'seenAt': seenAt?.toIso8601String(),
      'seenBy': seenBy,
      'deletedBy': deletedBy,
      'reactions': reactions,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.content == content &&
        other.messageType == messageType &&
        other.fileUrl == fileUrl &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.status == status &&
        other.sentAt == sentAt &&
        other.seenAt == seenAt &&
        other.seenBy == seenBy &&
        other.deletedBy == deletedBy &&
        other.reactions == reactions;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        senderId.hashCode ^
        content.hashCode ^
        messageType.hashCode ^
        fileUrl.hashCode ^
        timestamp.hashCode ^
        isRead.hashCode ^
        status.hashCode ^
        sentAt.hashCode ^
        seenAt.hashCode ^
        seenBy.hashCode ^
        deletedBy.hashCode ^
        reactions.hashCode;
  }

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderId: $senderId, content: $content, timestamp: $timestamp)';
  }
}

class SendMessageRequest {
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final String fileUrl;

  SendMessageRequest({
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.fileUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'messageType': messageType,
      'fileUrl': fileUrl,
    };
  }
}
