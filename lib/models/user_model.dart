import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastActive;
  final String? fcmToken;
  final String? activeChatId;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isOnline = false,
    this.lastActive,
    this.fcmToken,
    this.activeChatId,
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastActive,
    String? fcmToken,
    String? activeChatId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      fcmToken: fcmToken ?? this.fcmToken,
      activeChatId: activeChatId ?? this.activeChatId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'activeChatId': activeChatId,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['name'] ?? map['displayName'],
      photoUrl: map['photoUrl'],
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'] as int)
          : null,
      fcmToken: map['fcmToken'],
      activeChatId: map['activeChatId'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.isOnline == isOnline &&
        other.lastActive == lastActive &&
        other.fcmToken == fcmToken &&
        other.activeChatId == activeChatId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        isOnline.hashCode ^
        lastActive.hashCode ^
        fcmToken.hashCode ^
        activeChatId.hashCode ^
        createdAt.hashCode;
  }
}
