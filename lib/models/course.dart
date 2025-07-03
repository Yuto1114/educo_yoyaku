import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// コースを表すモデルクラス
class Course extends Equatable {
  final String courseId;
  final String courseName;

  const Course({
    required this.courseId,
    required this.courseName,
  });

  /// オブジェクトの一部プロパティを変更した新しいインスタンスを作成
  Course copyWith({
    String? courseId,
    String? courseName,
  }) {
    return Course(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
    );
  }

  /// オブジェクトをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'name': courseName, // Firestoreのフィールド名に合わせる
    };
  }

  /// Firestoreからの変換
  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      courseId: doc.id,
      courseName: data['name'] ?? '', // Firestoreのフィールド名に合わせる
    );
  }

  /// JSONシリアライズ用
  String toJson() => json.encode(toMap());

  /// JSONデシリアライズ用
  factory Course.fromJson(String source) => Course.fromMap(json.decode(source));

  /// MapからCourseを作成（JSONデシリアライズ内部処理用）
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      courseId: map['courseId'] ?? '',
      courseName: map['name'] ?? map['courseName'] ?? '', // 両方のキー名をサポート
    );
  }

  /// Firestore用のMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': courseName, // Firestoreのフィールド名に合わせる
    };
  }

  @override
  String toString() => 'Course(courseId: $courseId, courseName: $courseName)';

  @override
  List<Object> get props => [courseId, courseName];
}
