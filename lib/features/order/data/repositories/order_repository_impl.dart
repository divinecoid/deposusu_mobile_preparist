import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<OrderModel>> getOrders(String status) async {
    return await remoteDataSource.getOrders(status: status);
  }

  @override
  Future<bool> startPreparation(int orderId, String adminName) async {
    return await remoteDataSource.startPreparation(orderId, adminName);
  }

  @override
  Future<bool> finishPreparation(int orderId, String photoIsiPath, String photoFinalPath) async {
    return await remoteDataSource.finishPreparation(orderId, photoIsiPath, photoFinalPath);
  }
}
