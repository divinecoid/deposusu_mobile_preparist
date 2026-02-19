class DashboardStatsModel {
  final int hour;
  final int day;
  final int week;
  final int month;

  DashboardStatsModel({
    required this.hour,
    required this.day,
    required this.week,
    required this.month,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      hour: json['hour'] ?? 0,
      day: json['day'] ?? 0,
      week: json['week'] ?? 0,
      month: json['month'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'day': day,
      'week': week,
      'month': month,
    };
  }
}
