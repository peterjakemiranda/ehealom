import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'dart:async';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  
  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateStream => _authStateController.stream;
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;

  AuthController() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _token = await _authService.getToken();
      if (_token != null) {
        await _fetchUser();
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUser() async {
    debugPrint('AuthController: Starting fetch user');
    try {
      final userData = await _authService.getCurrentUser();
      debugPrint('AuthController: User data received - ${userData['uuid']}');
      _user = userData;
      _isAuthenticated = true;
    } catch (e) {
      debugPrint('AuthController: Fetch user error - $e');
      _isAuthenticated = false;
      _user = null;
      _token = null;
      await _authService.clearToken();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    debugPrint('AuthController: Starting login process');
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthController: Calling login service');
      final response = await _authService.login(email, password);
      debugPrint('AuthController: Login successful, token received');
      _token = response['token'];
      
      debugPrint('AuthController: Fetching user data');
      await _fetchUser();
      _isAuthenticated = true;
      debugPrint('AuthController: Login process completed successfully');
    } catch (e) {
      debugPrint('AuthController: Login error - $e');
      _isAuthenticated = false;
      _user = null;
      _token = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('AuthController: Login process finished');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🚀 AuthController: Starting registration process');
      final response = await _authService.register(userData);
      
      debugPrint('🔑 AuthController: Registration response received: $response');
      debugPrint('💾 AuthController: Saving token: ${response['token']}');
      _token = response['token'];
      
      debugPrint('👤 AuthController: Fetching user data');
      await _fetchUser();
      _isAuthenticated = true;
      
      debugPrint('✅ AuthController: Registration and login completed successfully');
      // Broadcast auth state change
      _authStateController.add(true);
      
    } catch (e) {
      debugPrint('❌ AuthController: Registration error - $e');
      _isAuthenticated = false;
      _user = null;
      _token = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      // Clear stored data
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'user');
      
      // Update state
      _isAuthenticated = false;
      _user = null;
      _token = null;
      _isLoading = false;
      
      // Broadcast auth state change
      _authStateController.add(false);
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? username,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
    int? age,
    String? studentId,
    String? department,
    String? course,
    String? major,
    String? yearLevel,
    String? academicRank,
    String? sex,
    String? maritalStatus,
  }) async {
    try {
      final Map<String, dynamic> data = {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (username != null) 'username': username,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
        if (newPasswordConfirmation != null) 'new_password_confirmation': newPasswordConfirmation,
        if (age != null) 'age': age,
        if (studentId != null) 'student_id': studentId,
        if (department != null) 'department': department,
        if (course != null) 'course': course,
        if (major != null) 'major': major,
        if (yearLevel != null) 'year_level': yearLevel,
        if (academicRank != null) 'academic_rank': academicRank,
        if (sex != null) 'sex': sex,
        if (maritalStatus != null) 'marital_status': maritalStatus,
      };

      final response = await _authService.updateProfile(data);
      _user = response['user'];
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshUserData() async {
    try {
      await _fetchUser();
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      rethrow;
    }
  }

  void _handleAuthResponse(Map<String, dynamic> response) {
    _token = response['token'];
    _user = response['user'];
    _isAuthenticated = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
