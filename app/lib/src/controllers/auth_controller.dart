import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  
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

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String userType,
  }) async {
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        userType: userType,
      );
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
      // Continue with logout even if API call fails
    } finally {
      _isAuthenticated = false;
      _user = null;
      _token = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
      };

      if (currentPassword != null && newPassword != null) {
        data['current_password'] = currentPassword;
        data['new_password'] = newPassword;
        data['new_password_confirmation'] = newPasswordConfirmation;
      }

      final response = await _authService.updateProfile(data);
      _user = response['user'];
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
