import 'package:flutter/material.dart';
import '../network/api_client.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  AuthProvider(this._apiClient) {
    _fetchUser();
  }

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> _fetchUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/user');
      _user = response.data;
    } catch (e) {
      debugPrint("Failed to fetch user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBasicProfile(String name, String? photoPath) async {
    try {
      FormData formData = FormData.fromMap({
        'name': name,
        if (photoPath != null)
          'photo': await MultipartFile.fromFile(photoPath),
      });

      final response = await _apiClient.post('/profile/update-basic', data: formData);
      if (response.data['success'] == true) {
        _user = response.data['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Update basic profile error: $e");
    }
    return false;
  }

  Future<bool> requestOtp(String type, String newValue) async {
    try {
      final response = await _apiClient.post('/profile/request-otp', data: {
        'type': type,
        'new_value': newValue,
      });
      return response.data['success'] == true;
    } catch (e) {
      debugPrint("Request OTP error: $e");
      return false;
    }
  }

  Future<bool> verifyAndUpdateSecureProfile(String type, String newValue, String otp) async {
    try {
      final response = await _apiClient.post('/profile/verify-otp', data: {
        'type': type,
        'new_value': newValue,
        'otp': otp,
      });
      if (response.data['success'] == true) {
        _user = response.data['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Verify OTP error: $e");
    }
    return false;
  }
}
