import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educo_yoyaku/models/course.dart';

/// コース関連のFirestoreアクセスを担当するリポジトリクラス
class CourseRepository {
  final FirebaseFirestore _firestore;

  /// コンストラクタ - 依存性注入に対応
  CourseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 全コースを取得
  Future<List<Course>> getCourses({bool isSortedByName = true}) async {
    Query query = _firestore.collection('courses');
    if (isSortedByName) {
      query = query.orderBy('name');
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
  }

  /// 単一コースをIDで取得
  Future<Course?> getCourseById(String id) async {
    final doc = await _firestore.collection('courses').doc(id).get();
    if (!doc.exists) return null;
    return Course.fromFirestore(doc);
  }

  /// コースをコースIDで検索
  Future<Course?> findCourseByCourseId(String courseId) async {
    final snapshot = await _firestore
        .collection('courses')
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();
        
    if (snapshot.docs.isEmpty) return null;
    return Course.fromFirestore(snapshot.docs.first);
  }

  /// コース追加
  Future<DocumentReference> addCourse(Course course) async {
    return await _firestore.collection('courses').add(course.toFirestore());
  }

  /// コース更新
  Future<void> updateCourse(Course course) async {
    await _firestore
        .collection('courses')
        .doc(course.courseId)
        .update(course.toFirestore());
  }

  /// コース削除
  Future<void> deleteCourse(String id) async {
    await _firestore.collection('courses').doc(id).delete();
  }

  /// コースをリアルタイムで監視するストリームを返す
  Stream<List<Course>> watchCourses({bool isSortedByName = true}) {
    Query query = _firestore.collection('courses');
    if (isSortedByName) {
      query = query.orderBy('name');
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    });
  }
  
  /// 特定のコースをリアルタイムで監視するストリームを返す
  Stream<Course?> watchCourseById(String id) {
    return _firestore.collection('courses').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Course.fromFirestore(doc);
    });
  }
}