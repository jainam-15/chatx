import 'package:flutter/foundation.dart';

@immutable
class ChatRoomModel {
  final String id;
  final String? name;
  final bool isGroup;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;

  const ChatRoomModel({
    required this.id,
    this.name,
    required this.isGroup,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCounts = const {},
  });

  ChatRoomModel copyWith({
    String? id,
    String? name,
    bool? isGroup,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isGroup': isGroup,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      name: map['name'],
      isGroup: map['isGroup'] ?? false,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'] as int)
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoomModel &&
        other.id == id &&
        other.name == name &&
        other.isGroup == isGroup &&
        listEquals(other.participantIds, participantIds) &&
        other.lastMessage == lastMessage &&
        other.lastMessageTime == lastMessageTime &&
        other.lastMessageSenderId == lastMessageSenderId &&
        mapEquals(other.unreadCounts, unreadCounts);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        isGroup.hashCode ^
        participantIds.hashCode ^
        lastMessage.hashCode ^
        lastMessageTime.hashCode ^
        lastMessageSenderId.hashCode ^
        unreadCounts.hashCode;
  }
}
