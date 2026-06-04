import 'package:flutter/material.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository repository;

  OrderProvider(this.repository);

  List<OrderModel> _onProcessOrders = [];
  List<OrderModel> _onPreparationOrders = [];
  List<OrderModel> _historyOrders = [];
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _initialized = false;

  void _initMockData() {
    // Mock data disabled to use actual data only
  }

  Future<void> fetchOrders({String status = 'onprocess'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiOrders = await repository.getOrders(status);
      if (status == 'onprocess') {
        _onProcessOrders = apiOrders;
        _onProcessOrders.sort(_sortScore);
        _orders = List.from(_onProcessOrders);
      } else if (status == 'onpreparation') {
        _onPreparationOrders = apiOrders;
        _onPreparationOrders.sort(_sortScore);
        _orders = List.from(_onPreparationOrders);
      } else if (status == 'ready') {
        _historyOrders = apiOrders;
        _orders = List.from(_historyOrders);
      } else {
        _orders = [];
      }
    } catch (e) {
      print('API Error: $e');
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _sortScore(OrderModel a, OrderModel b) {
    int scoreA = a.pickupTime.difference(DateTime.now()).inMinutes;
    if (DateTime.now().difference(a.createdAt).inMinutes > 30) scoreA -= 45;
    scoreA += a.items.fold(0, (sum, item) => sum + item.quantity);
    if (a.deliveryType == 'regular') scoreA += 60;

    int scoreB = b.pickupTime.difference(DateTime.now()).inMinutes;
    if (DateTime.now().difference(b.createdAt).inMinutes > 30) scoreB -= 45;
    scoreB += b.items.fold(0, (sum, item) => sum + item.quantity);
    if (b.deliveryType == 'regular') scoreB += 60;

    return scoreA.compareTo(scoreB);
  }

  Future<bool> startOrder(int id, String adminName) async {
    _isLoading = true;
    notifyListeners();

    try {
      await repository.startPreparation(id);
      final idx = _onProcessOrders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final order = _onProcessOrders.removeAt(idx);
        _onPreparationOrders.add(order.copyWith(status: 'onpreparation', assignedTo: adminName));
        _onPreparationOrders.sort(_sortScore);
      }
      _orders = List.from(_onProcessOrders);
      return true;
    } catch (e) {
      print('API Error startOrder: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateItemChecklist(int orderId, int itemId, int newQuantity) {
    final orderIdx = _onPreparationOrders.indexWhere((o) => o.id == orderId);
    if (orderIdx != -1) {
      final order = _onPreparationOrders[orderIdx];
      final newItems = order.items.map((item) {
        if (item.id == itemId) {
          int qty = newQuantity;
          if (qty < 0) qty = 0;
          if (qty > item.quantity) qty = item.quantity;
          
          // Add log for accountability if it changed
          if (item.checkedQuantity != qty) {
            String timeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
            String actionStr = qty > item.checkedQuantity ? 'Menambah' : 'Mengurangi';
            _addLogInternal(orderId, '[$timeStr] $actionStr ${item.productName} dari ${item.checkedQuantity} ke $qty');
          }
          
          return item.copyWith(checkedQuantity: qty);
        }
        return item;
      }).toList();
      
      _onPreparationOrders[orderIdx] = _onPreparationOrders[orderIdx].copyWith(items: newItems);
      // update _orders if currently showing
      final displayIdx = _orders.indexWhere((o) => o.id == orderId);
      if (displayIdx != -1) {
        _orders[displayIdx] = _onPreparationOrders[orderIdx];
      }
      notifyListeners();
    }
  }

  void _addLogInternal(int orderId, String log) {
    final orderIdx = _onPreparationOrders.indexWhere((o) => o.id == orderId);
    if (orderIdx != -1) {
      final order = _onPreparationOrders[orderIdx];
      final newLogs = List<String>.from(order.editLogs)..add(log);
      _onPreparationOrders[orderIdx] = order.copyWith(editLogs: newLogs);
    }
  }

  void addManualLog(int orderId, String logMsg) {
    String timeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    _addLogInternal(orderId, '[$timeStr] $logMsg');
    
    final displayIdx = _orders.indexWhere((o) => o.id == orderId);
    if (displayIdx != -1) {
      final orderIdx = _onPreparationOrders.indexWhere((o) => o.id == orderId);
      if (orderIdx != -1) _orders[displayIdx] = _onPreparationOrders[orderIdx];
    }
    notifyListeners();
  }

  void updateItemLocation(int orderId, int itemId, {String? warehouseName, String? rackName}) {
    final orderIdx = _onPreparationOrders.indexWhere((o) => o.id == orderId);
    if (orderIdx != -1) {
      final order = _onPreparationOrders[orderIdx];
      final newItems = order.items.map((item) {
        if (item.id == itemId) {
          String timeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
          if (warehouseName != null || rackName != null) {
            _addLogInternal(orderId, '[$timeStr] Lokasi ${item.productName}: Gudang "${warehouseName ?? item.warehouseName ?? '-'}", Rak "${rackName ?? item.rackName ?? '-'}"');
          }
          return item.copyWith(
            warehouseName: warehouseName ?? item.warehouseName,
            rackName: rackName ?? item.rackName,
          );
        }
        return item;
      }).toList();
      _onPreparationOrders[orderIdx] = order.copyWith(items: newItems);
      final displayIdx = _orders.indexWhere((o) => o.id == orderId);
      if (displayIdx != -1) {
        _orders[displayIdx] = _onPreparationOrders[orderIdx];
      }
      notifyListeners();
    }
  }

  void updatePackerName(int orderId, String name) {
    final orderIdx = _onPreparationOrders.indexWhere((o) => o.id == orderId);
    if (orderIdx != -1) {
      _onPreparationOrders[orderIdx] = _onPreparationOrders[orderIdx].copyWith(packerName: name);
      final displayIdx = _orders.indexWhere((o) => o.id == orderId);
      if (displayIdx != -1) {
        _orders[displayIdx] = _onPreparationOrders[orderIdx];
      }
      notifyListeners();
    }
  }

  Future<bool> finishPacking(int orderId, String photoIsiPath, String photoFinalPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await repository.finishPreparation(orderId, photoIsiPath, photoFinalPath);
      if (success) {
        _onPreparationOrders.removeWhere((o) => o.id == orderId);
        _orders = List.from(_onPreparationOrders);
        return true;
      }
      return false;
    } catch (e) {
      print('API Error finishPacking: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
