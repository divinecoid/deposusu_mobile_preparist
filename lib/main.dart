import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core
import 'core/network/api_client.dart';
import 'core/routes/global_keys.dart';

// Dashboard
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/presentation/provider/dashboard_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';

// Order/Packing
import 'features/order/data/datasources/order_remote_datasource.dart';
import 'features/order/data/repositories/order_repository_impl.dart';
import 'features/order/presentation/provider/order_provider.dart';
import 'features/order/presentation/pages/packing_list_page.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'features/auth/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Core
  final apiClient = ApiClient();
  await apiClient.initToken();

  // Initialize Auth
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient);
  final authRepository = AuthRepositoryImpl(authRemoteDataSource, apiClient);

  // Initialize Dashboard
  final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl(apiClient);
  final dashboardRepository = DashboardRepositoryImpl(dashboardRemoteDataSource);

  // Initialize Order
  final orderRemoteDataSource = OrderRemoteDataSourceImpl(apiClient);
  final orderRepository = OrderRepositoryImpl(orderRemoteDataSource);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardRepository)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deposusu Preparist',
      navigatorKey: GlobalKeys.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const PackingListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Packing',
          ),
        ],
      ),
    );
  }
}
