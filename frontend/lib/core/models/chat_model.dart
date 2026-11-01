import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final int? id;
  final int? conversationId;
  final String senderRole; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime createdAt;
  final bool isPending;
  final bool isError;
  final String? errorMessage;

  const ChatMessage({
    this.id,
    this.conversationId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.isPending = false,
    this.isError = false,
    this.errorMessage,
  });

  bool get isUser => senderRole == 'user';
  bool get isAssistant => senderRole == 'assistant';

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    String? senderRole,
    String? content,
    DateTime? createdAt,
    bool? isPending,
    bool? isError,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      senderRole: json['sender_role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      isPending: false,
      isError: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_role': senderRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class ChatConversationSummary {
  final int id;
  final String title;
  final int? childId;
  final String? childName;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversationSummary({
    required this.id,
    required this.title,
    this.childId,
    this.childName,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ChatConversationSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Conversation',
      childId: json['child_id'] is int
          ? json['child_id'] as int
          : int.tryParse(json['child_id']?.toString() ?? ''),
      childName: json['child_name']?.toString(),
      lastMessage: json['last_message']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'child_id': childId,
      'child_name': childName,
      'last_message': lastMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatSendResult {
  final bool success;
  final int? conversationId;
  final int? messageId;
  final String? reply;
  final int? childId;
  final String? childName;
  final String? errorMessage;

  const ChatSendResult({
    required this.success,
    this.conversationId,
    this.messageId,
    this.reply,
    this.childId,
    this.childName,
    this.errorMessage,
  });
}

