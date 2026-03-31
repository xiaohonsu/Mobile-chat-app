import 'dart:async';
import '../../core/models/user_model.dart';

/// Level 1 — Authentication Service
///
/// DEMO MODE: Uses in-memory mock data.
/// PRODUCTION: Replace with Firebase Auth implementation below.
///
/// Firebase implementation:
/// ```dart
/// import 'package:firebase_auth/firebase_auth.dart';
/// import 'package:cloud_firestore/cloud_firestore.dart';
///
/// class AuthService {
///   final _auth = FirebaseAuth.instance;
///   final _db   = FirebaseFirestore.instance;
///
///   Stream<User?> get authStateChanges => _auth.authStateChanges();
///
///   Future<void> signIn(String email, String password) =>
///       _auth.signInWithEmailAndPassword(email: email, password: password);
///
///   Future<void> signUp(String email, String password, String name) async {
///     final cred = await _auth.createUserWithEmailAndPassword(
///         email: email, password: password);
///     await _db.collection('users').doc(cred.user!.uid).set({
///       'displayName': name,
///       'email': email,
///       'isOnline': true,
///       'lastSeen': FieldValue.serverTimestamp(),
///     });
///   }
///
///   Future<void> signOut() async {
///     await _db.collection('users').doc(_auth.currentUser!.uid)
///         .update({'isOnline': false, 'lastSeen': FieldValue.serverTimestamp()});
///     await _auth.signOut();
///   }
/// }
/// ```

// Mock users database
final _mockUsers = <String, Map<String, dynamic>>{
  'user1@demo.com': {
    'password': '123456',
    'uid': 'uid_alice',
    'displayName': 'Alice Nguyen',
  },
  'user2@demo.com': {
    'password': '123456',
    'uid': 'uid_bob',
    'displayName': 'Bob Tran',
  },
  'user3@demo.com': {
    'password': '123456',
    'uid': 'uid_carol',
    'displayName': 'Carol Le',
  },
};

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  /// Stream theo dõi trạng thái đăng nhập.
  /// (Firebase: FirebaseAuth.instance.authStateChanges())
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  UserModel? get currentUser => _currentUser;

  /// Đăng nhập — Firebase: signInWithEmailAndPassword
  Future<UserModel> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simulate network

    final userData = _mockUsers[email.toLowerCase()];
    if (userData == null || userData['password'] != password) {
      throw Exception('Invalid email or password');
    }

    final user = UserModel(
      uid: userData['uid'] as String,
      displayName: userData['displayName'] as String,
      email: email,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  /// Đăng ký — Firebase: createUserWithEmailAndPassword + Firestore write
  Future<UserModel> signUp(
      String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_mockUsers.containsKey(email.toLowerCase())) {
      throw Exception('Email already registered');
    }

    final uid = 'uid_${DateTime.now().millisecondsSinceEpoch}';
    _mockUsers[email.toLowerCase()] = {
      'password': password,
      'uid': uid,
      'displayName': displayName,
    };

    final user = UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  /// Đăng xuất — Firebase: FirebaseAuth.instance.signOut()
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
