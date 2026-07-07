import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';
import 'packing_detail_page.dart';
import '../../../../features/dashboard/presentation/provider/dashboard_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class PackingListPage extends StatefulWidget {
  const PackingListPage({super.key});

  @override
  State<PackingListPage> createState() => _PackingListPageState();
}

class _PackingListPageState extends State<PackingListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NavigationProvider _navProvider;

  @override
  void initState() {
    super.initState();
    _navProvider = context.read<NavigationProvider>();
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: _navProvider.packingTabIndex,
    );
    
    _navProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (_tabController.index != _navProvider.packingTabIndex) {
      _tabController.animateTo(_navProvider.packingTabIndex);
    }
  }

  @override
  void dispose() {
    _navProvider.removeListener(_onNavChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean Packing'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Pesanan Baru', textAlign: TextAlign.center))),
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Tugas Saya', textAlign: TextAlign.center))),
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Menunggu Driver', textAlign: TextAlign.center))),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _OrderListTab(status: 'onprocess'),
          _OrderListTab(status: 'onpreparation'),
          _OrderListTab(status: 'prepared'),
        ],
      ),
    );
  }
}

class _OrderListTab extends StatefulWidget {
  final String status;
  const _OrderListTab({required this.status});

  @override
  State<_OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<_OrderListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(status: widget.status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        final navProvider = context.watch<NavigationProvider>();
        final dashboardStats = context.watch<DashboardProvider>().stats;
        bool forceEmpty = false;

        if (dashboardStats != null) {
          if (widget.status == 'onprocess' && dashboardStats.newOrders == 0) {
            forceEmpty = true;
          } else if (widget.status == 'onpreparation' && dashboardStats.processingOrders == 0) {
            forceEmpty = true;
          }
        }

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredOrders = provider.orders.where((o) {
          if (o.status != widget.status) return false;
          
          if (widget.status == 'onprocess' && navProvider.filterPrioritas) {
             final isDelayed = DateTime.now().difference(o.createdAt).inMinutes >= 15;
             final isPriorityType = o.deliveryType == 'instant' || o.deliveryType == 'sameday';
             if (!isDelayed && !isPriorityType) {
               return false;
             }
          }
          
          return true;
        }).toList();

        if (filteredOrders.isEmpty || forceEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                provider.fetchOrders(status: widget.status),
                context.read<DashboardProvider>().fetchStats(),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.inventory_2_rounded, size: 64, color: Colors.blue[300]),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          navProvider.filterPrioritas && widget.status == 'onprocess' ? 'Tidak ada pesanan prioritas' : 'Belum ada pesanan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tarik ke bawah untuk memperbarui',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              provider.fetchOrders(status: widget.status),
              context.read<DashboardProvider>().fetchStats(),
            ]);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return _PremiumOrderCard(order: order);
            },
          ),
        );
      },
    );
  }
}


class _PremiumOrderCard extends StatelessWidget {
  final OrderModel order;
  const _PremiumOrderCard({required this.order});

  Widget _buildSourceBadge(String source) {
    String text = source.toUpperCase();
    Color bgColor = Colors.grey[200]!;
    Color textColor = Colors.black87;
    IconData icon = Icons.storefront_rounded;

    if (text.contains('APP')) {
      bgColor = const Color(0xFF0EA5E9).withOpacity(0.1);
      textColor = const Color(0xFF0284C7);
      icon = Icons.smartphone_rounded;
    } else if (text.contains('WEB')) {
      bgColor = const Color(0xFF8B5CF6).withOpacity(0.1);
      textColor = const Color(0xFF6D28D9);
      icon = Icons.language_rounded;
    } else if (text.contains('SHOPEE')) {
      bgColor = const Color(0xFFF97316).withOpacity(0.1);
      textColor = const Color(0xFFC2410C);
      icon = Icons.shopping_cart_rounded;
    } else if (text.contains('TOKOPEDIA')) {
      bgColor = const Color(0xFF10B981).withOpacity(0.1);
      textColor = const Color(0xFF047857);
      icon = Icons.shopping_bag_rounded;
    } else if (text.contains('TIKTOK')) {
      bgColor = Colors.black.withOpacity(0.05);
      textColor = Colors.black87;
      icon = Icons.music_note_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPreparation = order.status == 'onpreparation';
    final isPrepared = order.status == 'prepared';
    final isDelayed = DateTime.now().difference(order.createdAt).inMinutes > 30;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Can always see details now!
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PackingDetailPage(orderId: order.id)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPrepared ? const Color(0xFF8B5CF6).withOpacity(0.15) : (isPreparation ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFF3B82F6).withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPrepared ? '🟣 MENUNGGU DRIVER' : (isPreparation ? '🟠 PREPARING' : '🟡 NEW ORDER'),
                        style: TextStyle(
                          color: isPrepared ? const Color(0xFF6D28D9) : (isPreparation ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.access_time_rounded, size: 18, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Pickup: ${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')} WIB', 
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (order.deliveryType == 'instant' || order.deliveryType == 'sameday')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        child: const Text('🔥 Prioritas Tinggi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                  ],
                ),
                if (isDelayed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Menunggu terlalu lama! (${DateTime.now().difference(order.createdAt).inMinutes} mnt)',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_rounded, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(order.customerName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSourceBadge(order.orderSource),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.shopping_bag_rounded, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Text('${order.items.length} Barang', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  ],
                ),
                if (order.assignedTo != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.assignment_ind_rounded, size: 18, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Assigned to: ${order.assignedTo}', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700))),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (isPrepared)
                  const SizedBox() // no buttons for prepared status, just waiting
                else if (!isPreparation)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        final userName = authProvider.user?['name'] ?? 'Staf Gudang';

                        final success = await context.read<OrderProvider>().startOrder(order.id, userName);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Tugas Packing Diambil oleh $userName!' : 'Gagal memproses'),
                              backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Ambil Tugas Packing', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PackingDetailPage(orderId: order.id)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lanjutkan Packing', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
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
