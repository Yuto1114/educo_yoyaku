import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educo_yoyaku/models/classroom.dart';
import 'package:educo_yoyaku/models/classroom_slot.dart';

/// 教室関連のFirestoreアクセスを担当するリポジトリクラス
class ClassroomRepository {
  final FirebaseFirestore _firestore;

  /// コンストラクタ - 依存性注入に対応
  ClassroomRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 全クラスルームを取得
  Future<List<Classroom>> getClassrooms({bool isSortedByName = true}) async {
    Query query = _firestore.collection('classrooms');
    if (isSortedByName) {
      query = query.orderBy('name');
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Classroom.fromFirestore(doc)).toList();
  }

  /// 単一クラスルームを取得
  Future<Classroom?> getClassroomById(String id) async {
    final doc = await _firestore.collection('classrooms').doc(id).get();
    if (!doc.exists) return null;
    return Classroom.fromFirestore(doc);
  }

  /// スロット情報も含めたクラスルームを取得
  Future<Classroom?> getClassroomWithSlotsById(String id) async {
    // クラスルームを取得
    final doc = await _firestore.collection('classrooms').doc(id).get();
    if (!doc.exists) return null;

    final classroom = Classroom.fromFirestore(doc);

    // スロットを取得
    final slotsSnapshot = await _firestore
        .collection('classrooms')
        .doc(id)
        .collection('slots')
        .get();

    // スロットオブジェクトを作成してリストに追加
    final slots = slotsSnapshot.docs
        .map((slotDoc) => ClassroomSlot.fromFirestore(slotDoc))
        .toList();

    // スロット情報を含む新しいClassroomオブジェクトを返す
    return classroom.copyWith(slots: slots);
  }

  /// スロット情報も含めた全クラスルームを取得
  Future<List<Classroom>> getClassroomsWithSlots(
      {bool isSortedByName = true}) async {
    // まず全クラスルームを取得
    final classrooms = await getClassrooms(isSortedByName: isSortedByName);

    // 各クラスルームのスロット情報を取得
    final List<Classroom> classroomsWithSlots = [];

    for (final classroom in classrooms) {
      final slotsSnapshot = await _firestore
          .collection('classrooms')
          .doc(classroom.classroomId)
          .collection('slots')
          .get();

      final slots = slotsSnapshot.docs
          .map((slotDoc) => ClassroomSlot.fromFirestore(slotDoc))
          .toList();

      // スロット情報を含む新しいClassroomオブジェクトを作成
      classroomsWithSlots.add(classroom.copyWith(slots: slots));
    }

    return classroomsWithSlots;
  }

  /// クラスルーム追加
  Future<DocumentReference> addClassroom(Classroom classroom) async {
    return await _firestore
        .collection('classrooms')
        .add(classroom.toFirestore());
  }

  /// クラスルーム更新
  Future<void> updateClassroom(Classroom classroom) async {
    await _firestore
        .collection('classrooms')
        .doc(classroom.classroomId)
        .update(classroom.toFirestore());
  }

  /// クラスルーム削除
  Future<void> deleteClassroom(String id) async {
    // スロットのサブコレクションも削除する必要がある
    // Note: 完全に削除するにはCloud Functionsなどでサブコレクションも削除する必要があります
    final slotsSnapshot = await _firestore
        .collection('classrooms')
        .doc(id)
        .collection('slots')
        .get();

    // バッチ処理でスロットを削除
    final batch = _firestore.batch();
    for (final doc in slotsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // クラスルーム自体も削除
    batch.delete(_firestore.collection('classrooms').doc(id));

    // バッチ処理を実行
    await batch.commit();
  }

  /// スロット追加
  Future<DocumentReference> addSlot(
      String classroomId, ClassroomSlot slot) async {
    return await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .collection('slots')
        .add(slot.toMap());
  }

  /// スロット更新
  Future<void> updateSlot(String classroomId, ClassroomSlot slot) async {
    await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .collection('slots')
        .doc(slot.slotId)
        .update(slot.toMap());
  }

  /// スロット削除
  Future<void> deleteSlot(String classroomId, String slotId) async {
    await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .collection('slots')
        .doc(slotId)
        .delete();
  }

  /// クラスルームに紐づく全スロットを取得
  Future<List<ClassroomSlot>> getSlotsByClassroomId(String classroomId) async {
    final slotsSnapshot = await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .collection('slots')
        .get();

    return slotsSnapshot.docs
        .map((slotDoc) => ClassroomSlot.fromFirestore(slotDoc))
        .toList();
  }
}
