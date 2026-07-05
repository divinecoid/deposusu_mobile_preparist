import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Core
import 'core/network/api_client.dart';

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
import 'features/order/presentation/pages/history_page.dart';
import 'package:flutter/services.dart';

import 'core/providers/navigation_provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'core/routes/global_keys.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Initialize Core
    final apiClient = ApiClient();

  // Initialize Dashboard
  final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl(apiClient);
  final dashboardRepository = DashboardRepositoryImpl(dashboardRemoteDataSource);

  // Initialize Order
  final orderRemoteDataSource = OrderRemoteDataSourceImpl(apiClient);
  final orderRepository = OrderRepositoryImpl(orderRemoteDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient), lazy: false),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardRepository)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository)),
      ],
      child: const MyApp(),
    ),
  );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deposusu Preparist',
      navigatorKey: GlobalKeys.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // Blue - sesuai warna DEPOSUSU
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF10B981), // Emerald Green
          surface: const Color(0xFFF8FAFC),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const MainNavigationPage(),
      },
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final List<Widget> _pages = [
    const DashboardPage(),
    const PackingListPage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[navProvider.bottomNavIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: navProvider.bottomNavIndex,
            onTap: (index) => context.read<NavigationProvider>().setBottomNavIndex(index),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1976D2),
            unselectedItemColor: Colors.grey[400],
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.dashboard_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.dashboard_rounded, size: 28),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.inventory_2_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.inventory_2_rounded, size: 28),
                ),
                label: 'Packing',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.history_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.history_rounded, size: 28),
                ),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.person_outline),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.person, size: 28),
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
