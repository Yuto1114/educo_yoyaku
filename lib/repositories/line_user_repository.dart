import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educo_yoyaku/models/line_user.dart';

class LineUserRepository {
  final _firestore = FirebaseFirestore.instance;

  // 単一ユーザー取得
  Future<LineUser?> getUser(String userId) async {
    final doc = await _firestore.collection('line_users').doc(userId).get();
    if (!doc.exists) return null;
    return LineUser.fromFirestore(doc);
  }

  // 全ユーザー取得
  Future<List<LineUser>> getAllUsers({bool isSortedByDict = true}) async {
    Query query = _firestore.collection('line_users');
    if (isSortedByDict) {
      query = query.orderBy('displayName');
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => LineUser.fromFirestore(doc)).toList();
  }

  // リアルタイム監視
  Stream<List<LineUser>> watchUsers() {
    return _firestore.collection('line_users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => LineUser.fromFirestore(doc)).toList());
  }

  // ユーザー追加/更新
  Future<void> saveUser(LineUser user) async {
    await _firestore
        .collection('line_users')
        .doc(user.userId)
        .set(user.toFirestore());
  }

  // ユーザー削除
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('line_users').doc(userId).delete();
  }
}
