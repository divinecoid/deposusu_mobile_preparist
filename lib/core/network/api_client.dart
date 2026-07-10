import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiClient {
  final http.Client _client;
  String? _token;
  VoidCallback? onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  bool _isAuthenticating = false;
  Completer<void>? _authCompleter;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  Future<void> ensureAuthenticated() async {
    if (_token != null) return;
    if (_isAuthenticating) {
      return _authCompleter?.future;
    }

    _isAuthenticating = true;
    _authCompleter = Completer<void>();

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/login');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': 'gudang@deposusu.com',
          'password': 'password',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _token = data['token'];
          print('Silent login successful for preparist: $_token');
        }
      }
    } catch (e) {
      print('Silent login failed: $e');
    } finally {
      _isAuthenticating = false;
      _authCompleter?.complete();
      _authCompleter = null;
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  void _handleResponse(String endpoint, int statusCode) {
    if (statusCode == 401 && endpoint != '/login') {
      _token = null;
      onUnauthorized?.call();
    }
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    await ensureAuthenticated();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    _handleResponse(endpoint, response.statusCode);
    return response;
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    if (endpoint != '/login') {
      await ensureAuthenticated();
    }
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));
    _handleResponse(endpoint, response.statusCode);
    return response;
  }

  Future<http.StreamedResponse> postMultipart(String endpoint, {Map<String, String>? fields, List<http.MultipartFile>? files}) async {
    await ensureAuthenticated();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    final response = await _client.send(request).timeout(const Duration(seconds: 60));
    _handleResponse(endpoint, response.statusCode);
    return response;
  }
}
