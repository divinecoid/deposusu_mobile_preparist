class DashboardStatsModel {
  final int newOrders;
  final int processingOrders;
  final int priorityOrders;
  final int completedTodayOrders;

  DashboardStatsModel({
    required this.newOrders,
    required this.processingOrders,
    required this.priorityOrders,
    required this.completedTodayOrders,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      newOrders: json['newOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? 0,
      priorityOrders: json['priorityOrders'] ?? 0,
      completedTodayOrders: json['completedTodayOrders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newOrders': newOrders,
      'processingOrders': processingOrders,
      'priorityOrders': priorityOrders,
      'completedTodayOrders': completedTodayOrders,
    };
  }
}
