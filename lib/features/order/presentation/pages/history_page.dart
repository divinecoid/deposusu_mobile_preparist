import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(status: 'ready');
    });
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
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
            child: Image.file(File(imagePath)),
          ),
        ),
      ),
    ));
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
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final filteredOrders = provider.orders.where((o) => o.status == 'ready').toList();

          if (filteredOrders.isEmpty) {
            return Center(
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
                    'Pesanan yang selesai akan tampil di sini',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchOrders(status: 'ready'),
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
                          Text(
                            order.orderNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🟢 SELESAI',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
                                onTap: () => _showFullScreenImage(context, order.packingProofPhoto!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(order.packingProofPhoto!), height: 100, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          if (order.packingProofPhotoFinal != null)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showFullScreenImage(context, order.packingProofPhotoFinal!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(order.packingProofPhotoFinal!), height: 100, fit: BoxFit.cover),
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
    );
  }
}
