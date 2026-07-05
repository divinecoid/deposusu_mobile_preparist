class DashboardStatsModel {
  final int newOrders;
  final int processingOrders;
  final int waitingDriverOrders;
  final int completedTodayOrders;

  DashboardStatsModel({
    required this.newOrders,
    required this.processingOrders,
    required this.waitingDriverOrders,
    required this.completedTodayOrders,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      newOrders: json['newOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? 0,
      waitingDriverOrders: json['waitingDriverOrders'] ?? 0,
      completedTodayOrders: json['completedTodayOrders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newOrders': newOrders,
      'processingOrders': processingOrders,
      'waitingDriverOrders': waitingDriverOrders,
      'completedTodayOrders': completedTodayOrders,
    };
  }
}
