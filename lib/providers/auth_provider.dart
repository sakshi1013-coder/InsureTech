import 'package:flutter/material.dart';
import 'package:insurex_app/models/user_model.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/services/demo_data_service.dart';
import 'package:insurex_app/core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final DemoDataService _demoData = DemoDataService();

  UserModel? _user;
  OfficerModel? _officerProfile;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  OfficerModel? get officerProfile => _officerProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String get role => _user?.role ?? '';

  Future<void> init() async {
    _setLoading(true);
    try {
      _user = await _authService.getCurrentUserModel();
      if (_user != null) {
        await _loadExtra();
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> _loadExtra() async {
    if (_user!.role == AppConstants.roleOfficer) {
      _officerProfile = await _firestoreService.getOfficerByUserId(_user!.id);
    }
    // Seed global demo data
    await _demoData.seedAll();
    // Seed user specific data
    if (_user!.role == AppConstants.roleCustomer) {
      await _demoData.seedUserData(_user!.id, _user!.name);
    }
  }

  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _authService.signIn(email, password);
      if (_user == null) {
        _error = 'User not found. Please register.';
        _setLoading(false);
        return _error;
      }
      try {
        await _loadExtra();
      } catch (e) {
        debugPrint('Load extra fallback: $e');
      }
      _setLoading(false);
      return null;
    } catch (e) {
      _error = _parseError(e.toString());
      _setLoading(false);
      return _error;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: AppConstants.roleCustomer,
      );
      try {
        await _demoData.seedAll();
        await _demoData.seedUserData(_user!.id, _user!.name);
      } catch (e) {
        debugPrint('Seeding fallback: $e');
      }
      _setLoading(false);
      return null;
    } catch (e) {
      _error = _parseError(e.toString());
      _setLoading(false);
      return _error;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _officerProfile = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _authService.updateProfile(_user!.id, data);
    _user = await _firestoreService.getUserById(_user!.id);
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _parseError(String e) {
    if (e.contains('user-not-found')) return 'No account found for this email.';
    if (e.contains('wrong-password')) return 'Incorrect password. Please try again.';
    if (e.contains('email-already-in-use')) return 'Email already registered. Please sign in.';
    if (e.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (e.contains('invalid-email')) return 'Please enter a valid email address.';
    if (e.contains('network-request-failed')) return 'Network error. Please check your connection.';
    if (e.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    return 'Something went wrong. Please try again.';
  }
}
