class AppConstants {
  static const String baseUrl = 'http://192.168.1.50:8000/api';

  // Auth Endpoints
  static const String login = '/login';

  // Preparist Endpoints
  static const String dashboard = '/preparist/dashboard';
  static const String orders = '/preparist/orders';

  static String startOrder(int id) => '/preparist/orders/$id/start';
  static String finishOrder(int id) => '/preparist/orders/$id/finish';
}
