import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders({String status = 'onprocess'});
  Future<bool> startPreparation(int orderId);
  Future<bool> cancelPreparation(int orderId);
  Future<bool> finishPreparation(int orderId, {File? photoFinal});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<OrderModel>> getOrders({String status = 'onprocess'}) async {
    final response = await apiClient.get(AppConstants.orders, queryParams: {'status': status});

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true) {
        final List data = decoded['data']['data'];
        return data.map((item) => OrderModel.fromJson(item)).toList();
      }
    }
    throw Exception('Failed to load orders');
  }

  @override
  Future<bool> startPreparation(int orderId) async {
    final response = await apiClient.post(AppConstants.startOrder(orderId));
    return response.statusCode == 200;
  }

  @override
  Future<bool> cancelPreparation(int orderId) async {
    final response = await apiClient.post(AppConstants.cancelOrder(orderId));
    return response.statusCode == 200;
  }

  @override
  Future<bool> finishPreparation(int orderId, {File? photoFinal}) async {
    final response = await apiClient.postMultipart(
      AppConstants.finishOrder(orderId),
      files: photoFinal != null ? {'photo_final': photoFinal.path} : null,
    );
    print('finishPreparation status: ${response.statusCode}');
    print('finishPreparation body: ${response.body}');
    return response.statusCode == 200;
  }
}
