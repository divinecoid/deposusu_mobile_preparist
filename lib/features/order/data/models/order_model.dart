class OrderModel {
  final int id;
  final String orderNumber;
  final String customerName;
  final String status;
  final List<OrderItemModel> items;
  final double totalAmount;
  final DateTime createdAt;
  final String orderSource;
  final String? assignedTo;
  final String? packerName;
  final String? packingProofPhoto;
  final String? packingProofPhotoFinal;
  final DateTime? packedAt;
  final List<String> editLogs;
  final DateTime pickupTime;
  final String deliveryType;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.orderSource = 'Kasir',
    this.assignedTo,
    this.packerName,
    this.packingProofPhoto,
    this.packingProofPhotoFinal,
    this.packedAt,
    this.editLogs = const [],
    required this.pickupTime,
    this.deliveryType = 'regular',
  });

  OrderModel copyWith({
    int? id,
    String? orderNumber,
    String? customerName,
    String? status,
    List<OrderItemModel>? items,
    double? totalAmount,
    DateTime? createdAt,
    String? orderSource,
    String? assignedTo,
    String? packerName,
    String? packingProofPhoto,
    String? packingProofPhotoFinal,
    DateTime? packedAt,
    List<String>? editLogs,
    DateTime? pickupTime,
    String? deliveryType,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      orderSource: orderSource ?? this.orderSource,
      assignedTo: assignedTo ?? this.assignedTo,
      packerName: packerName ?? this.packerName,
      packingProofPhoto: packingProofPhoto ?? this.packingProofPhoto,
      packingProofPhotoFinal: packingProofPhotoFinal ?? this.packingProofPhotoFinal,
      packedAt: packedAt ?? this.packedAt,
      editLogs: editLogs ?? this.editLogs,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryType: deliveryType ?? this.deliveryType,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      customerName: json['customer_name'],
      status: json['status'],
      items: (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      orderSource: json['order_source'] ?? 'Kasir',
      assignedTo: json['assigned_to'],
      editLogs: [],
      pickupTime: json['pickup_time'] != null ? DateTime.parse(json['pickup_time']) : DateTime.now().add(const Duration(minutes: 30)),
      deliveryType: json['delivery_type'] ?? 'regular',
    );
  }
}

class OrderItemModel {
  final int id;
  final String productName;
  final int quantity;
  final double subtotal;
  final int checkedQuantity;
  final String? warehouseName;
  final String? rackName;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.subtotal,
    this.checkedQuantity = 0,
    this.warehouseName,
    this.rackName,
  });

  OrderItemModel copyWith({
    int? id,
    String? productName,
    int? quantity,
    double? subtotal,
    int? checkedQuantity,
    String? warehouseName,
    String? rackName,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      checkedQuantity: checkedQuantity ?? this.checkedQuantity,
      warehouseName: warehouseName ?? this.warehouseName,
      rackName: rackName ?? this.rackName,
    );
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productName: json['product']['name'],
      quantity: json['quantity'],
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}
