import '../models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders(String status);
  Future<bool> startPreparation(int orderId);
  Future<bool> finishPreparation(int orderId);
}
