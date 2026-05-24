import 'package:flutter/foundation.dart';

@immutable
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final DateTime? serverTimestamp;
  final String? attachmentUrl;
  final String? attachmentType;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.serverTimestamp,
    this.attachmentUrl,
    this.attachmentType,
    this.readBy = const [],
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    DateTime? serverTimestamp,
    String? attachmentUrl,
    String? attachmentType,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      // serverTimestamp is intentionally populated by Firestore using a sentinel value,
      // but if we are just creating a map to save, we should use FieldValue.serverTimestamp()
      // Wait, we can't easily import FieldValue here without depending on cloud_firestore.
      // So we will add it at the DatabaseService level when sending.
      'serverTimestamp': null, 
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'readBy': readBy,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      serverTimestamp: map['serverTimestamp'] != null
          ? (map['serverTimestamp'] as dynamic).toDate() // Handle Firestore Timestamp
          : null,
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.text == text &&
        other.timestamp == timestamp &&
        other.serverTimestamp == serverTimestamp &&
        other.attachmentUrl == attachmentUrl &&
        other.attachmentType == attachmentType &&
        listEquals(other.readBy, readBy);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        senderName.hashCode ^
        text.hashCode ^
        timestamp.hashCode ^
        serverTimestamp.hashCode ^
        attachmentUrl.hashCode ^
        attachmentType.hashCode ^
        readBy.hashCode;
  }
}
