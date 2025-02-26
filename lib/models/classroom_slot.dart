import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 教室のスロット（時間枠）を表すモデルクラス
class ClassroomSlot extends Equatable {
  final String slotId;
  final int capacity;
  final String courseId;
  final String courseName;
  final DateTime createdAt;
  final int currentBookings;
  final DateTime endDateTime;
  final DateTime startDateTime;
  final DateTime updatedAt;

  const ClassroomSlot({
    required this.slotId,
    required this.capacity,
    required this.courseId,
    required this.courseName,
    required this.createdAt,
    required this.currentBookings,
    required this.endDateTime,
    required this.startDateTime,
    required this.updatedAt,
  });

  /// オブジェクトの一部プロパティを変更した新しいインスタンスを作成
  ClassroomSlot copyWith({
    String? slotId,
    int? capacity,
    String? courseId,
    String? courseName,
    DateTime? createdAt,
    int? currentBookings,
    DateTime? endDateTime,
    DateTime? startDateTime,
    DateTime? updatedAt,
  }) {
    return ClassroomSlot(
      slotId: slotId ?? this.slotId,
      capacity: capacity ?? this.capacity,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      createdAt: createdAt ?? this.createdAt,
      currentBookings: currentBookings ?? this.currentBookings,
      endDateTime: endDateTime ?? this.endDateTime,
      startDateTime: startDateTime ?? this.startDateTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// オブジェクトをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'capacity': capacity,
      'courseId': courseId,
      'courseName': courseName,
      'currentBookings': currentBookings,
      // Firestoreに保存する際はDateTimeからTimestampに変換
      'createdAt': Timestamp.fromDate(createdAt),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// FirestoreドキュメントからClassroomSlotを作成
  factory ClassroomSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassroomSlot(
      slotId: doc.id,
      capacity: data['capacity']?.toInt() ?? 0,
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      currentBookings: data['currentBookings']?.toInt() ?? 0,
      endDateTime: data['endDateTime'] is Timestamp
          ? (data['endDateTime'] as Timestamp).toDate()
          : DateTime.now(),
      startDateTime: data['startDateTime'] is Timestamp
          ? (data['startDateTime'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSONシリアライズ用
  String toJson() => json.encode(toMap());

  /// JSONデシリアライズ用
  factory ClassroomSlot.fromJson(String source) =>
      ClassroomSlot.fromMap(json.decode(source));

  /// MapからClassroomSlotを作成（JSONデシリアライズ内部処理用）
  factory ClassroomSlot.fromMap(Map<String, dynamic> map) {
    return ClassroomSlot(
      slotId: map['slotId'] ?? '',
      capacity: map['capacity']?.toInt() ?? 0,
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      // JSON形式の場合はString → DateTimeに変換
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now()),
      currentBookings: map['currentBookings']?.toInt() ?? 0,
      endDateTime: map['endDateTime'] is String
          ? DateTime.parse(map['endDateTime'])
          : (map['endDateTime'] is Timestamp
              ? (map['endDateTime'] as Timestamp).toDate()
              : DateTime.now()),
      startDateTime: map['startDateTime'] is String
          ? DateTime.parse(map['startDateTime'])
          : (map['startDateTime'] is Timestamp
              ? (map['startDateTime'] as Timestamp).toDate()
              : DateTime.now()),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.now()),
    );
  }

  @override
  List<Object> get props => [
        slotId,
        capacity,
        courseId,
        courseName,
        createdAt,
        currentBookings,
        endDateTime,
        startDateTime,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ClassroomSlot(slotId: $slotId, capacity: $capacity, courseId: $courseId, courseName: $courseName, createdAt: $createdAt, currentBookings: $currentBookings, endDateTime: $endDateTime, startDateTime: $startDateTime, updatedAt: $updatedAt)';
  }
}
