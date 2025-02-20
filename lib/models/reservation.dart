import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Reservation extends Equatable {
  final String reservationId; // 予約ID
  final String userId; // ユーザーID
  final String classroomId; // 教室ID
  final DateTime startTime; // 予約開始時間
  final DateTime endTime; // 予約終了時間
  final String status; // 予約ステータス

  const Reservation({
    required this.reservationId,
    required this.userId,
    required this.classroomId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  Reservation copyWith({
    String? reservationId,
    String? userId,
    String? classroomId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) {
    return Reservation(
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      classroomId: classroomId ?? this.classroomId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'userId': userId,
      'classroomId': classroomId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      reservationId: map['reservationId'] ?? '',
      userId: map['userId'] ?? '',
      classroomId: map['classroomId'] ?? '',
      startTime: DateTime.parse(map['startDateTime']),
      endTime: DateTime.parse(map['endDateTime']),
      status: map['status'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Reservation.fromJson(String source) =>
      Reservation.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Reservation(reservationId: $reservationId, userId: $userId, classroomId: $classroomId, startTime: $startTime, endTime: $endTime, status: $status)';
  }

  @override
  List<Object> get props {
    return [
      reservationId,
      userId,
      classroomId,
      startTime,
      endTime,
      status,
    ];
  }

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      reservationId: doc.id, // FirestoreのドキュメントidをreservationIdとして使用
      userId: data['userId'] ?? '',
      classroomId: data['classroomId'] ?? '',
      startTime: DateTime.parse(data['startDateTime']),
      endTime: DateTime.parse(data['endDateTime']),
      status: data['status'] ?? '',
    );
  }

  // Firestore用のMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'classroomId': classroomId,
      'startDateTime': startTime.toIso8601String(),
      'endDateTime': endTime.toIso8601String(),
      'status': status,
    };
  }
}
