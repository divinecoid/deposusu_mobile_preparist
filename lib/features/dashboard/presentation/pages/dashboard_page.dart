import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/dashboard_provider.dart';
import '../../../../core/providers/navigation_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchStats(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                    title: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, Preparist! 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Siap menyiapkan pesanan hari ini?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContent(provider, context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(DashboardProvider provider, BuildContext context) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: TextStyle(color: Colors.red[800])),
            TextButton(
              onPressed: () => provider.fetchStats(),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    final stats = provider.stats;
    if (stats == null) {
      return const Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ModernStatCard(
                title: 'Pesanan Baru',
                subtitle: 'Pesanan baru masuk',
                value: stats.newOrders.toString(),
                gradient: const [Color(0xFFF97316), Color(0xFFC2410C)], // Orange
                icon: Icons.inbox_outlined,
                onTap: () => context.read<NavigationProvider>().navigateToPacking(0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Sedang Diproses',
                subtitle: 'Pesanan sedang dikerjakan',
                value: stats.processingOrders.toString(),
                gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue
                icon: Icons.loop_outlined,
                onTap: () => context.read<NavigationProvider>().navigateToPacking(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModernStatCard(
                title: 'Prioritas',
                subtitle: 'Pesanan harus didahulukan',
                value: stats.priorityOrders.toString(),
                gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)], // Red
                icon: Icons.warning_amber_rounded,
                onTap: () => context.read<NavigationProvider>().navigateToPacking(0, filterPrioritas: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Selesai Hari Ini',
                subtitle: 'Pesanan sudah selesai',
                value: stats.completedTodayOrders.toString(),
                gradient: const [Color(0xFF10B981), Color(0xFF047857)], // Green
                icon: Icons.check_circle_outline,
                onTap: () => context.read<NavigationProvider>().navigateToHistory(filterHariIni: true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback? onTap;

  const _ModernStatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.gradient,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    icon,
                    size: 80,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(height: 16),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
