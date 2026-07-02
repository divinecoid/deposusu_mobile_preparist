import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api'; // Replace with actual domain from .env

  // Auth Endpoints
  static const String login = '/login';

  // Preparist Endpoints
  static const String dashboard = '/preparist/dashboard';
  static const String orders = '/preparist/orders';

  static String startOrder(int id) => '/preparist/orders/$id/start';
  static String cancelOrder(int id) => '/preparist/orders/$id/cancel';
  static String finishOrder(int id) => '/preparist/orders/$id/finish';
}
