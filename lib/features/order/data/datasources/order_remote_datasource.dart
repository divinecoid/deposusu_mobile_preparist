import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders({String status = 'onprocess'});
  Future<bool> startPreparation(int orderId, String adminName);
  Future<bool> finishPreparation(int orderId, String photoIsiPath, String photoFinalPath);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<OrderModel>> getOrders({String status = 'onprocess'}) async {
    final response = await apiClient.get(AppConstants.orders, queryParams: {
      'status': status,
      'sort': 'desc',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true) {
        final List data = decoded['data']['data'] ?? decoded['data'];
        return data.map((item) => OrderModel.fromJson(item)).toList();
      }
    }
    throw Exception('Failed to load orders: ${response.statusCode} - ${response.body}');
  }

  @override
  Future<bool> startPreparation(int orderId, String adminName) async {
    final response = await apiClient.post(
      AppConstants.startOrder(orderId),
      body: {'assigned_to': adminName},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> finishPreparation(int orderId, String photoIsiPath, String photoFinalPath) async {
    final files = <http.MultipartFile>[];
    
    if (photoIsiPath.isNotEmpty) {
      files.add(await http.MultipartFile.fromPath('photo_isi', photoIsiPath));
    }
    if (photoFinalPath.isNotEmpty) {
      files.add(await http.MultipartFile.fromPath('photo_final', photoFinalPath));
    }

    final response = await apiClient.postMultipart(
      AppConstants.finishOrder(orderId),
      files: files,
    );
    
    final statusCode = response.statusCode;
    final responseBody = await response.stream.bytesToString();
    
    print('[finishPreparation] status: $statusCode, body: $responseBody');
    
    if (statusCode != 200) {
      throw Exception('Upload foto gagal (HTTP $statusCode): $responseBody');
    }
    
    return true;
  }
}
