import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSourceImpl(this.apiClient);

  @override
  Future<DashboardStatsModel> getStats() async {
    final response = await apiClient.get(AppConstants.dashboard);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true) {
        return DashboardStatsModel.fromJson(decoded['performance']);
      }
    }
    throw Exception('Failed to load dashboard stats');
  }
}
