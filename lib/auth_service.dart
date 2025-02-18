import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _loginKey = 'isLoggedIn';

  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _storage.write(key: _loginKey, value: 'true');
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ログイン状態をチェック
  Future<bool> isLoggedIn() async {
    final storedValue = await _storage.read(key: _loginKey);
    return storedValue == 'true';
  }

  // ログアウト時にSecureStorageから削除
  Future<void> logout() async {
    await _auth.signOut();
    await _storage.delete(key: _loginKey);
  }

  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('ユーザーが見つかりません');
      case 'wrong-password':
        return Exception('パスワードが間違っています');
      case 'invalid-email':
        return Exception('メールアドレスの形式が正しくありません');
      case 'user-disabled':
        return Exception('このアカウントは無効化されています');
      default:
        return Exception('認証エラーが発生しました: ${e.message}');
    }
  }
}
