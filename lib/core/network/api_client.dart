import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../routes/global_keys.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ApiClient {
  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String? token) {
    _token = token;
  }

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      final context = GlobalKeys.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
    return response;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<http.Response> postMultipart(String endpoint, {Map<String, String>? fields, Map<String, String>? files}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    final headers = {
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    request.headers.addAll(headers);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
      }
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
