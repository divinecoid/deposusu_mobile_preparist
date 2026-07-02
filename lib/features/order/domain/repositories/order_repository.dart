import 'dart:io';
import '../../data/models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders(String status);
  Future<bool> startPreparation(int orderId);
  Future<bool> cancelPreparation(int orderId);
  Future<bool> finishPreparation(int orderId, {File? photoFinal});
}
