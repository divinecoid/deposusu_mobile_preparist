import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'login_page.dart';
import '../../../../main.dart'; // To access MainNavigationPage
import '../../../../core/network/api_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Delay for a short duration to show splash screen (optional)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final token = await authProvider.repository.getToken();

    if (!mounted) return;

    if (token != null) {
      // Re-initialize API client with token just in case
      context.read<ApiClient>().setToken(token);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}
