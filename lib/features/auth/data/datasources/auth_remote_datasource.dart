import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.post(
      AppConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final message = jsonDecode(response.body)['message'] ?? 'Login failed';
      throw Exception(message);
    }
  }
}
