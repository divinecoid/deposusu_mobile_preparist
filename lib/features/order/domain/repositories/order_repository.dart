import '../../data/models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders(String status, {String? historyStatus});
  Future<bool> startPreparation(int orderId, String adminName);
  Future<bool> finishPreparation(
    int orderId, 
    String photoIsiPath, 
    String photoFinalPath, {
    required List<Map<String, dynamic>> items,
    required List<String> logs,
  });
}
