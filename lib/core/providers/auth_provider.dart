import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';

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
