import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/dashboard_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer2<DashboardProvider, AuthProvider>(
        builder: (context, provider, authProvider, child) {
          final user = authProvider.user;

          return RefreshIndicator(
            onRefresh: () => provider.fetchStats(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFFE0F2FE),
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE0F2FE), // Biru langit cerah
                            Color(0xFFEFF6FF), // Biru muda pastel
                          ],
                        ),
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user?['name']?.split(' ')?.first ?? 'Preparist'}!',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A), // Slate gelap kontras
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Kemasan rapi, pelanggan happy! Semangat hari ini.',
                                style: TextStyle(
                                  color: Color(0xFF0284C7), // Biru cerah kontras
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            backgroundImage: user?['photo'] != null 
                                ? NetworkImage(AppConstants.storageUrl + user!['photo']) 
                                : null,
                            child: user?['photo'] == null 
                                ? const Icon(Icons.person, size: 16, color: Color(0xFF0284C7)) 
                                : null,
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
                        const SizedBox(height: 32),
                        const Text(
                          'Performa Waktu Packing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPackingPerformanceChart(provider),
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

  Widget _buildPackingPerformanceChart(DashboardProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = provider.stats;
    if (stats == null || stats.packingHistory.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat packing hari ini',
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    int maxCount = stats.packingHistory
        .map((e) => e.count)
        .fold(0, (max, e) => e > max ? e : max);
    if (maxCount < 3) maxCount = 3;

    int totalPackedToday = stats.packingHistory
        .map((e) => e.count)
        .fold(0, (sum, e) => sum + e);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paket Selesai per Jam Kerja',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Hari Ini: $totalPackedToday pkt',
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Scrollable Chart Row for hourly bars
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: 160,
              width: 500, // Fixed width to give bars enough breathing room
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = (constraints.maxWidth - (12 * (stats.packingHistory.length - 1))) / stats.packingHistory.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: stats.packingHistory.map((item) {
                      final heightPercent = item.count / maxCount;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Count badge on top of bar (visible only if count > 0 for premium clean look)
                          Text(
                            item.count > 0 ? '${item.count}' : '-',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.count > 0 ? const Color(0xFF0284C7) : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Bar
                          Container(
                            width: barWidth,
                            height: (item.count > 0) ? (100 * heightPercent) : 4.0, // tiny base if 0
                            decoration: BoxDecoration(
                              gradient: item.count > 0
                                  ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF0284C7),
                                        Color(0xFF38BDF8),
                                      ],
                                    )
                                  : null,
                              color: item.count == 0 ? Colors.grey[200] : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Hour Label
                          Text(
                            item.hour,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
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
                gradient: const [Color(0xFFF97316), Color(0xFFEA580C)], // Orange
                icon: Icons.inbox_outlined,
                onTap: () => context.read<NavigationProvider>().navigateToPacking(0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Sedang Diproses',
                subtitle: 'Pesanan dikerjakan',
                value: stats.processingOrders.toString(),
                gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue
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
                title: 'Menunggu Driver',
                subtitle: 'Siap di-pickup',
                value: stats.waitingDriverOrders.toString(),
                gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple/Violet
                icon: Icons.delivery_dining_outlined,
                onTap: () => context.read<NavigationProvider>().navigateToPacking(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Selesai Hari Ini',
                subtitle: 'Tugas selesai',
                value: stats.completedTodayOrders.toString(),
                gradient: const [Color(0xFF10B981), Color(0xFF059669)], // Green
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
