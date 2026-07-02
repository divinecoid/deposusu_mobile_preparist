class OrderModel {
  final int id;
  final String orderNumber;
  final String customerName;
  final String status;
  final List<OrderItemModel> items;
  final double totalAmount;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      customerName: json['customer_name'],
      status: json['status'],
      items: (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList(),
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class OrderItemModel {
  final int id;
  final String productName;
  final int quantity;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productName: json['product']['name'],
      quantity: int.parse(json['quantity'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}
