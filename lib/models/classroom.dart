import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Classroom extends Equatable {
  final String classroomId;
  final String classroomName;

  const Classroom({
    required this.classroomId,
    required this.classroomName,
  });

  Classroom copyWith({
    String? classroomId,
    String? classroomName,
  }) {
    return Classroom(
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classroomId': classroomId,
      'classroomName': classroomName,
    };
  }

  factory Classroom.fromMap(Map<String, dynamic> map) {
    return Classroom(
      classroomId: map['classroomId'] ?? '',
      classroomName: map['classroomName'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Classroom.fromJson(String source) =>
      Classroom.fromMap(json.decode(source));

  @override
  String toString() =>
      'Classroom(classroomId: $classroomId, classroomName: $classroomName)';

  @override
  List<Object> get props => [classroomId, classroomName];

  factory Classroom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Classroom(
      classroomId: doc.id, // FirestoreのドキュメントidをclassroomIdとして使用
      classroomName: data['name'] ?? '',
    );
  }

  // Firestore用のMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'classroomName': classroomName,
    };
  }
}
