import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'classroom_slot.dart';

/// 教室を表すモデルクラス
class Classroom extends Equatable {
  final String classroomId;
  final String classroomName;
  final String lore; // 教室の詳細情報（住所など）
  final List<ClassroomSlot> slots; // この教室に紐づく時間枠のリスト

  const Classroom({
    required this.classroomId,
    required this.classroomName,
    this.lore = '',
    this.slots = const [],
  });

  /// オブジェクトの一部プロパティを変更した新しいインスタンスを作成
  Classroom copyWith({
    String? classroomId,
    String? classroomName,
    String? lore,
    List<ClassroomSlot>? slots,
  }) {
    return Classroom(
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
      lore: lore ?? this.lore,
      slots: slots ?? this.slots,
    );
  }

  /// オブジェクトをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'name': classroomName, // Firestoreのフィールド名に合わせる
      'lore': lore,
    };
  }

  /// 基本的なFirestoreからの変換（スロットなし）
  factory Classroom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Classroom(
      classroomId: doc.id,
      classroomName: data['name'] ?? '', // Firestoreのフィールド名に合わせる
      lore: data['lore'] ?? '',
    );
  }

  /// JSONシリアライズ用
  String toJson() => json.encode(toMap());

  /// JSONデシリアライズ用
  factory Classroom.fromJson(String source) =>
      Classroom.fromMap(json.decode(source));

  /// MapからClassroomを作成（JSONデシリアライズ内部処理用）
  factory Classroom.fromMap(Map<String, dynamic> map) {
    return Classroom(
      classroomId: map['classroomId'] ?? '',
      classroomName: map['name'] ?? map['classroomName'] ?? '', // 両方のキー名をサポート
      lore: map['lore'] ?? '',
      slots: map['slots'] != null
          ? List<ClassroomSlot>.from(
              map['slots']?.map((x) => ClassroomSlot.fromMap(x)) ?? const [])
          : const [],
    );
  }

  /// Firestore用のMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': classroomName, // Firestoreのフィールド名に合わせる
      'lore': lore,
    };
  }

  @override
  String toString() =>
      'Classroom(classroomId: $classroomId, classroomName: $classroomName, lore: $lore, slots: ${slots.length}個)';

  @override
  List<Object> get props => [classroomId, classroomName, lore, slots];
}
