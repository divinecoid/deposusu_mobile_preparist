import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/constants/app_constants.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedStatus = 'all'; // 'all', 'prepared', 'ondelivery', 'completed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(status: 'history');
    });
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Foto Packing', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
          context.read<OrderProvider>().fetchOrders(
            status: 'history',
            historyStatus: value == 'all' ? null : value,
          );
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.grey[100],
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Packing'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Column(
        children: [
          // Horizontal Status Filter
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Menunggu Driver', 'prepared'),
                const SizedBox(width: 8),
                _buildFilterChip('Sedang Dikirim', 'ondelivery'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai', 'completed'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                final navProvider = context.watch<NavigationProvider>();
                final filteredOrders = provider.orders.where((o) {
                  if (!(o.status == 'prepared' || o.status == 'ondelivery' || o.status == 'delivered' || o.status == 'done')) return false;

                  if (navProvider.filterHariIni) {
                     final today = DateTime.now();
                     final dateToUse = o.packedAt ?? o.createdAt;
                     if (dateToUse.year != today.year || dateToUse.month != today.month || dateToUse.day != today.day) {
                       return false;
                     }
                  }
                  return true;
                }).toList();

                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filteredOrders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchOrders(
                      status: 'history',
                      historyStatus: _selectedStatus == 'all' ? null : _selectedStatus,
                    ),
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
                                    color: Colors.grey.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Belum ada riwayat',
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
                  onRefresh: () => provider.fetchOrders(
                    status: 'history',
                    historyStatus: _selectedStatus == 'all' ? null : _selectedStatus,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
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
                                    color: order.status == 'prepared' 
                                        ? const Color(0xFF8B5CF6).withOpacity(0.15)
                                        : const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.status == 'prepared' 
                                        ? '🟣 MENUNGGU DRIVER' 
                                        : '🟢 DISERAHKAN KE DRIVER',
                                    style: TextStyle(
                                      color: order.status == 'prepared' 
                                          ? const Color(0xFF6D28D9)
                                          : const Color(0xFF10B981),
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
                                const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(order.customerName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (order.assignedTo != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.assignment_ind_rounded, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('Packer: ${order.assignedTo}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Text('Foto Bukti Packing:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (order.packingProofPhoto != null)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showFullScreenImage(context, AppConstants.storageUrl + order.packingProofPhoto!),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          AppConstants.storageUrl + order.packingProofPhoto!,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                if (order.packingProofPhotoFinal != null)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showFullScreenImage(context, AppConstants.storageUrl + order.packingProofPhotoFinal!),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          AppConstants.storageUrl + order.packingProofPhotoFinal!,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

