import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class LineUser extends Equatable {
  final String userId;
  final String displayName;
  final String language;
  final String lineId;
  final String pictureUrl;
  final String statusMessage;
  final String course;

  const LineUser({
    required this.userId,
    required this.displayName,
    required this.language,
    required this.lineId,
    required this.pictureUrl,
    required this.statusMessage,
    required this.course,
  });

  LineUser copyWith({
    String? userId,
    String? displayName,
    String? language,
    String? lineId,
    String? pictureUrl,
    String? statusMessage,
    String? course,
  }) {
    return LineUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      language: language ?? this.language,
      lineId: lineId ?? this.lineId,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      course: course ?? this.course,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'language': language,
      'lineId': lineId,
      'pictureUrl': pictureUrl,
      'statusMessage': statusMessage,
      'course': course,
    };
  }

  factory LineUser.fromMap(Map<String, dynamic> map) {
    return LineUser(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      language: map['language'] ?? '',
      lineId: map['lineId'] ?? '',
      pictureUrl: map['pictureUrl'] ?? '',
      statusMessage: map['statusMessage'] ?? '',
      course: map['course'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LineUser.fromJson(String source) =>
      LineUser.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LineUser(userId: $userId, displayName: $displayName, language: $language, lineId: $lineId, pictureUrl: $pictureUrl, statusMessage: $statusMessage, course: $course)';
  }

  @override
  List<Object> get props {
    return [
      userId,
      displayName,
      language,
      lineId,
      pictureUrl,
      statusMessage,
      course,
    ];
  }

  factory LineUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LineUser(
      userId: doc.id, // FirestoreのドキュメントidをuserIdとして使用
      displayName: data['displayName'] ?? '',
      language: data['language'] ?? '',
      lineId: data['lineId'] ?? '',
      pictureUrl: data['pictureUrl'] ?? '',
      statusMessage: data['statusMessage'] ?? '',
      course: data['course'] ?? '',
    );
  }

  // Firestore用のMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'language': language,
      'lineId': lineId,
      'pictureUrl': pictureUrl,
      'statusMessage': statusMessage,
      'course': course,
    };
  }
}
