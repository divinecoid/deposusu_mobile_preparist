import 'package:flutter/material.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/models/dashboard_stats_model.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository repository;

  DashboardProvider(this.repository);

  DashboardStatsModel? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mocked data instead of hitting backend
      await Future.delayed(const Duration(milliseconds: 500));
      _stats = DashboardStatsModel(newOrders: 12, processingOrders: 5, priorityOrders: 2, completedTodayOrders: 38);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
