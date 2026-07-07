class PackingDurationModel {
  final String hour;
  final int count;

  PackingDurationModel({
    required this.hour,
    required this.count,
  });

  factory PackingDurationModel.fromJson(Map<String, dynamic> json) {
    return PackingDurationModel(
      hour: json['hour'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'count': count,
    };
  }
}

class DashboardStatsModel {
  final int newOrders;
  final int processingOrders;
  final int waitingDriverOrders;
  final int completedTodayOrders;
  final List<PackingDurationModel> packingHistory;

  DashboardStatsModel({
    required this.newOrders,
    required this.processingOrders,
    required this.waitingDriverOrders,
    required this.completedTodayOrders,
    required this.packingHistory,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final list = json['packingHistory'] as List?;
    final historyList = list != null
        ? List<PackingDurationModel>.from(
            list.map((item) => PackingDurationModel.fromJson(item as Map<String, dynamic>)),
          )
        : <PackingDurationModel>[];

    return DashboardStatsModel(
      newOrders: json['newOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? 0,
      waitingDriverOrders: json['waitingDriverOrders'] ?? 0,
      completedTodayOrders: json['completedTodayOrders'] ?? 0,
      packingHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newOrders': newOrders,
      'processingOrders': processingOrders,
      'waitingDriverOrders': waitingDriverOrders,
      'completedTodayOrders': completedTodayOrders,
      'packingHistory': packingHistory.map((item) => item.toJson()).toList(),
    };
  }
}
