import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Reservation extends Equatable {
  final String reservationId; // 予約ID
  final String userId; // ユーザーID
  final String classroomId; // 教室ID
  final String courseName; // コース名
  final DateTime startTime; // 予約開始時間
  final DateTime endTime; // 予約終了時間
  final String slotId; // スロットID
  final String status; // 予約ステータス
  final DateTime createdAt; // 作成日時
  final DateTime updatedAt; // 更新日時

  const Reservation({
    required this.reservationId,
    required this.userId,
    required this.classroomId,
    required this.courseName,
    required this.startTime,
    required this.endTime,
    required this.slotId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Reservation copyWith({
    String? reservationId,
    String? userId,
    String? classroomId,
    String? courseName,
    DateTime? startTime,
    DateTime? endTime,
    String? slotId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      classroomId: classroomId ?? this.classroomId,
      courseName: courseName ?? this.courseName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'userId': userId,
      'classroomId': classroomId,
      'courseName': courseName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'slotId': slotId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      reservationId: map['reservationId'] ?? '',
      userId: map['userId'] ?? '',
      classroomId: map['classroomId'] ?? '',
      courseName: map['courseName'] ?? '',
      startTime: DateTime.parse(map['startDateTime']),
      endTime: DateTime.parse(map['endDateTime']),
      slotId: map['slotId'] ?? '',
      status: map['status'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Reservation.fromJson(String source) =>
      Reservation.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Reservation(reservationId: $reservationId, userId: $userId, classroomId: $classroomId, courseName: $courseName, startTime: $startTime, endTime: $endTime, slotId: $slotId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  List<Object> get props {
    return [
      reservationId,
      userId,
      classroomId,
      courseName,
      startTime,
      endTime,
      slotId,
      status,
      createdAt,
      updatedAt,
    ];
  }

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      reservationId: doc.id, // FirestoreのドキュメントidをreservationIdとして使用
      userId: data['userId'] ?? '',
      classroomId: data['classroomId'] ?? '',
      courseName: data['courseName'] ?? '',
      startTime: _parseFirestoreTimestamp(data['startDateTime']),
      endTime: _parseFirestoreTimestamp(data['endDateTime']),
      slotId: data['slotId'] ?? '',
      status: data['status'] ?? '',
      createdAt: _parseFirestoreTimestamp(data['createdAt']),
      updatedAt: _parseFirestoreTimestamp(data['updatedAt']),
    );
  }

  // Firestore用のMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'classroomId': classroomId,
      'courseName': courseName,
      'startDateTime': startTime, // DateTime型のままFirestoreに保存
      'endDateTime': endTime, // DateTime型のままFirestoreに保存
      'slotId': slotId,
      'status': status,
      'createdAt': createdAt, // DateTime型のままFirestoreに保存
      'updatedAt': updatedAt, // DateTime型のままFirestoreに保存
    };
  }

  // Timestamp型またはString型のデータをDateTime型に変換するヘルパーメソッド
  static DateTime _parseFirestoreTimestamp(dynamic value) {
    if (value is Timestamp) {
      // Timestampの場合はtoDateを使用
      return value.toDate();
    } else if (value is String) {
      // 文字列の場合はDateTime.parseを使用
      return DateTime.parse(value);
    } else {
      // その他の場合は現在時刻を返す
      return DateTime.now();
    }
  }
}
