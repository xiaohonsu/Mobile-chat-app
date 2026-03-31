import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';

/// Level 1 — Authentication Service
/// Uses Firebase Auth + Firestore to persist user profiles.

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Stream theo dõi trạng thái đăng nhập.
  /// Tự động emit khi user login/logout — dùng với StreamBuilder ở main.
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        return null;
      }
      final doc =
          await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) return null;
      _currentUser = UserModel.fromMap({
        'uid': firebaseUser.uid,
        ...doc.data()!,
      });
      return _currentUser;
    });
  }

  /// Đăng nhập
  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Cập nhật online status
    await _db.collection('users').doc(cred.user!.uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    _currentUser = UserModel.fromMap({
      'uid': cred.user!.uid,
      ...doc.data()!,
    });
    return _currentUser!;
  }

  /// Đăng ký tài khoản mới
  Future<UserModel> signUp(
      String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Lưu profile vào Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName': displayName.trim(),
      'email': email.trim(),
      'avatarUrl': '',
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _currentUser = UserModel(
      uid: cred.user!.uid,
      displayName: displayName.trim(),
      email: email.trim(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    return _currentUser!;
  }

  /// Đăng xuất — cập nhật offline status trước khi logout
  Future<void> signOut() async {
    if (_auth.currentUser != null) {
      await _db.collection('users').doc(_auth.currentUser!.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
    _currentUser = null;
  }

  /// Lấy danh sách tất cả users (để tìm kiếm / tạo chat mới)
  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db
        .collection('users')
        .where('uid', isNotEqualTo: _auth.currentUser?.uid ?? '')
        .get();
    return snap.docs.map((doc) {
      return UserModel.fromMap({'uid': doc.id, ...doc.data()});
    }).toList();
  }
}
