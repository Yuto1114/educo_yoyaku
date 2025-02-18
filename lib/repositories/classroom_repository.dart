import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educo_yoyaku/models/classroom.dart';

class ClassroomRepository {
  final _firestore = FirebaseFirestore.instance;

  // 全クラスルーム取得
  Future<List<Classroom>> getClassrooms() async {
    final snapshot = await _firestore.collection('classrooms').get();
    return snapshot.docs.map((doc) => Classroom.fromFirestore(doc)).toList();
  }

  // 単一クラスルーム取得
  Future<Classroom?> getClassroomById(String id) async {
    final doc = await _firestore.collection('classrooms').doc(id).get();
    if (!doc.exists) return null;
    return Classroom.fromFirestore(doc);
  }

  // クラスルーム追加
  Future<void> addClassroom(Classroom classroom) async {
    await _firestore.collection('classrooms').add(classroom.toFirestore());
  }

  // クラスルーム更新
  Future<void> updateClassroom(Classroom classroom) async {
    await _firestore
        .collection('classrooms')
        .doc(classroom.classroomId)
        .update(classroom.toFirestore());
  }

  // クラスルーム削除
  Future<void> deleteClassroom(String id) async {
    await _firestore.collection('classrooms').doc(id).delete();
  }
}
