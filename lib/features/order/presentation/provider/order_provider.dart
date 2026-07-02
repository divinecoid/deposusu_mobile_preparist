import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository repository;

  OrderProvider(this.repository);

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders({String status = 'onprocess'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await repository.getOrders(status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startOrder(int id) async {
    try {
      final success = await repository.startPreparation(id);
      if (success) {
        await fetchOrders(); // Refresh list
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelOrder(int id) async {
    try {
      final success = await repository.cancelPreparation(id);
      if (success) {
        await fetchOrders(status: 'onpreparation'); // Refresh list
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> finishOrder(int id, {File? photoFinal}) async {
    try {
      final success = await repository.finishPreparation(id, photoFinal: photoFinal);
      if (success) {
        await fetchOrders(); // Refresh list
      }
      return success;
    } catch (e, stacktrace) {
      print('Error in finishOrder: $e\n$stacktrace');
      return false;
    }
  }
}
