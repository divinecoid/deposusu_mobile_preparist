import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../routes/global_keys.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiClient) {
    _apiClient.onUnauthorized = () {
      logout();
    };
    _init();
  }

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _apiClient.token != null;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _apiClient.setToken(token);
    }
    await _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final response = await _apiClient.get('/user');
      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Failed to fetch user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        final token = decoded['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          _apiClient.setToken(token);
        }
        _user = decoded['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = decoded['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _apiClient.setToken(null);
    _user = null;
    notifyListeners();
    
    // Redirect to login page
    GlobalKeys.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<bool> updateBasicProfile(String name, String? photoPath) async {
    try {
      final fields = {'name': name};
      final files = <http.MultipartFile>[];
      if (photoPath != null && photoPath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('photo', photoPath));
      }

      final response = await _apiClient.postMultipart(
        '/profile/update-basic',
        fields: fields,
        files: files,
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decoded = jsonDecode(responseBody);
        if (decoded['success'] == true) {
          _user = decoded['user'];
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Update basic profile error: $e");
    }
    return false;
  }

  Future<bool> requestOtp(String type, String newValue) async {
    try {
      final response = await _apiClient.post(
        '/profile/request-otp',
        body: {
          'type': type,
          'new_value': newValue,
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
    } catch (e) {
      debugPrint("Request OTP error: $e");
    }
    return false;
  }

  Future<bool> verifyAndUpdateSecureProfile(String type, String newValue, String otp) async {
    try {
      final response = await _apiClient.post(
        '/profile/verify-otp',
        body: {
          'type': type,
          'new_value': newValue,
          'otp': otp,
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          _user = decoded['user'];
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Verify OTP error: $e");
    }
    return false;
  }
}
