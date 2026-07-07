import 'package:flutter/material.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository repository;

  OrderProvider(this.repository);

  List<OrderModel> _onProcessOrders = [];
  List<OrderModel> _onPreparationOrders = [];
  List<OrderModel> _preparedOrders = [];
  List<OrderModel> _historyOrders = [];
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  String? _lastUploadError;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastUploadError => _lastUploadError;



  Future<void> fetchOrders({String status = 'onprocess'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiOrders = await repository.getOrders(status);
      if (status == 'onprocess') {
        _onProcessOrders = apiOrders;
        _orders = List.from(_onProcessOrders);
      } else if (status == 'onpreparation') {
        _onPreparationOrders = apiOrders;
        _orders = List.from(_onPreparationOrders);
      } else if (status == 'prepared') {
        _preparedOrders = apiOrders;
        _orders = List.from(_preparedOrders);
      } else if (status == 'history') {
        _historyOrders = apiOrders;
        _orders = List.from(_historyOrders);
      } else {
        _orders = [];
      }
    } catch (e) {
      print('API Error: $e');
      _error = e.toString();
      // Reset the relevant cache so counter and list stay in sync
      if (status == 'onprocess') {
        _onProcessOrders = [];
      } else if (status == 'onpreparation') {
        _onPreparationOrders = [];
      } else if (status == 'prepared') {
        _preparedOrders = [];
      }
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startOrder(int id, String adminName) async {
    _isLoading = true;
    notifyListeners();

    try {
      await repository.startPreparation(id, adminName);
      final idx = _onProcessOrders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final order = _onProcessOrders.removeAt(idx);
        _onPreparationOrders.add(order.copyWith(status: 'onpreparation', assignedTo: adminName));
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
    _lastUploadError = null;
    notifyListeners();

    try {
      final success = await repository.finishPreparation(orderId, photoIsiPath, photoFinalPath);
      if (success) {
        final idx = _onPreparationOrders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          final order = _onPreparationOrders.removeAt(idx);
          _preparedOrders.add(order.copyWith(status: 'prepared'));
        }
        _orders = List.from(_onPreparationOrders);
        return true;
      }
      _lastUploadError = 'Server menolak upload foto. Cek koneksi atau coba lagi.';
      return false;
    } catch (e) {
      print('API Error finishPacking: $e');
      _error = e.toString();
      if (e.toString().contains('TimeoutException')) {
        _lastUploadError = 'Koneksi timeout saat upload foto. Pastikan WiFi stabil lalu coba lagi.';
      } else if (e.toString().contains('SocketException')) {
        _lastUploadError = 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
      } else if (e.toString().contains('HTTP 403')) {
        _lastUploadError = 'Akses ditolak (403). Pesanan ini tidak di-assign ke akun kamu.';
      } else if (e.toString().contains('HTTP 422')) {
        _lastUploadError = 'Validasi gagal (422). Format foto tidak diterima server.';
      } else if (e.toString().contains('HTTP 5')) {
        _lastUploadError = 'Server error. Coba lagi beberapa saat.';
      } else {
        _lastUploadError = 'Gagal upload foto: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
