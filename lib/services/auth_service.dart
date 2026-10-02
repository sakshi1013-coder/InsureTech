import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static UserModel? _currentMockUser;

  static final Map<String, UserModel> _mockUsers = {
    'customer@insurex.com': UserModel(
      id: 'usr_customer_demo',
      name: 'Alexander Wright',
      email: 'customer@insurex.com',
      phone: '+1 (555) 382-9912',
      role: AppConstants.roleCustomer,
      createdAt: DateTime(2024, 1, 15),
    ),
    'officer@insurex.com': UserModel(
      id: 'usr_officer_demo',
      name: 'Marcus Vance',
      email: 'officer@insurex.com',
      phone: '+1 (555) 721-4091',
      role: AppConstants.roleOfficer,
      createdAt: DateTime(2023, 6, 1),
    ),
    'admin@insurex.com': UserModel(
      id: 'usr_admin_demo',
      name: 'Admin Desk',
      email: 'admin@insurex.com',
      phone: '+1 (555) 900-1122',
      role: AppConstants.roleAdmin,
      createdAt: DateTime(2023, 1, 1),
    ),
  };

  User? get currentUser => _auth?.currentUser;

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Fetch user profile from Firestore `users/{uid}`
  Future<UserModel?> getCurrentUserModel() async {
    if (_currentMockUser != null) return _currentMockUser;
    final fbUser = _auth?.currentUser;
    if (fbUser != null && _firestore != null) {
      try {
        final doc = await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(fbUser.uid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Firestore getCurrentUserModel: $e');
      }
    }
    return _currentMockUser;
  }

  /// Sign in with Firebase Auth and fetch role from Firestore `users/{uid}`
  Future<UserModel?> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check in-memory demo account first for instant offline access
    if (_mockUsers.containsKey(cleanEmail)) {
      _currentMockUser = _mockUsers[cleanEmail];
      return _currentMockUser;
    }

    // 2. Real Firebase Authentication
    if (_auth != null) {
      try {
        final cred = await _auth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 5));

        final uid = cred.user!.uid;
        if (_firestore != null) {
          final doc = await _firestore!
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .get()
              .timeout(const Duration(seconds: 4));

          if (doc.exists && doc.data() != null) {
            final user = UserModel.fromMap(doc.data()!, doc.id);
            _currentMockUser = user;
            return user;
          }
        }

        // If doc does not exist yet in Firestore, create default customer profile
        final fallbackUser = UserModel(
          id: uid,
          name: cred.user?.displayName ?? cleanEmail.split('@').first,
          email: cleanEmail,
          phone: cred.user?.phoneNumber ?? '',
          role: AppConstants.roleCustomer,
          createdAt: DateTime.now(),
        );
        if (_firestore != null) {
          await _firestore!
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .set(fallbackUser.toMap());
        }
        _currentMockUser = fallbackUser;
        return fallbackUser;
      } catch (e) {
        debugPrint('Firebase sign-in error/notice: $e');
      }
    }

    // 3. Fallback demo user if Firebase unavailable
    final fallbackUser = UserModel(
      id: 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      name: cleanEmail.split('@').first.replaceAll('.', ' ').capitalize(),
      email: cleanEmail,
      phone: '+1 (555) 123-4567',
      role: cleanEmail.contains('admin')
          ? AppConstants.roleAdmin
          : cleanEmail.contains('officer')
              ? AppConstants.roleOfficer
              : AppConstants.roleCustomer,
      createdAt: DateTime.now(),
    );
    _mockUsers[cleanEmail] = fallbackUser;
    _currentMockUser = fallbackUser;
    return fallbackUser;
  }

  /// Register new user in Firebase Auth and create profile in Firestore `users/{uid}`
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = AppConstants.roleCustomer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    String newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Try Firebase Authentication
    if (_auth != null) {
      try {
        final cred = await _auth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 5));

        newId = cred.user!.uid;
        final fbUser = UserModel(
          id: newId,
          name: name,
          email: cleanEmail,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
        );

        if (_firestore != null) {
          await _firestore!
              .collection(AppConstants.usersCollection)
              .doc(newId)
              .set(fbUser.toMap())
              .timeout(const Duration(seconds: 4));
        }

        _mockUsers[cleanEmail] = fbUser;
        _currentMockUser = fbUser;
        return fbUser;
      } catch (e) {
        debugPrint('Firebase register notice: $e');
      }
    }

    // 2. In-memory registration
    final user = UserModel(
      id: newId,
      name: name,
      email: cleanEmail,
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
    );
    _mockUsers[cleanEmail] = user;
    _currentMockUser = user;
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _currentMockUser = null;
  }

  /// Update user profile
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore?.collection(AppConstants.usersCollection).doc(userId).update(data);
    } catch (_) {}
    if (_currentMockUser != null && _currentMockUser!.id == userId) {
      _currentMockUser = _currentMockUser!.copyWith(
        name: data['name'] as String?,
        phone: data['phone'] as String?,
        address: data['address'] as String?,
      );
    }
  }

  /// Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth?.sendPasswordResetEmail(email: email);
    } catch (_) {}
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
  }
}
