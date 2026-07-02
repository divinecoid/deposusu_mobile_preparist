import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';

class PackingListPage extends StatefulWidget {
  const PackingListPage({super.key});

  @override
  State<PackingListPage> createState() => _PackingListPageState();
}

class _PackingListPageState extends State<PackingListPage> with SingleTickerProviderStateMixin {
  String _selectedStatus = 'onprocess';
  Timer? _timer;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        final newStatus = _tabController!.index == 0 ? 'onprocess' : 'onpreparation';
        if (_selectedStatus != newStatus) {
          setState(() => _selectedStatus = newStatus);
          context.read<OrderProvider>().fetchOrders(status: _selectedStatus);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(status: _selectedStatus);
    });
    
    // Auto-refresh every 10 seconds so new orders appear automatically
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      context.read<OrderProvider>().fetchOrders(status: _selectedStatus);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OrderProvider>().fetchOrders(status: _selectedStatus);
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'On Process'),
            Tab(text: 'On Preparation'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (_tabController == null) return const SizedBox.shrink();

          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildList(provider),
              _buildList(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(OrderProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchOrders(status: _selectedStatus),
      child: provider.orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(child: Text('No orders found')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${order.customerName} • ${order.items.length} items'),
        trailing: _buildActionButtons(order),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.quantity}x ${item.productName}'),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.status == 'onprocess') {
      return ElevatedButton(
        onPressed: () => _handleStart(order.id),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        child: const Text('Start'),
      );
    } else if (order.status == 'onpreparation') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _handleCancel(order.id),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _handleFinish(order.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Finish'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleStart(int id) async {
    final success = await context.read<OrderProvider>().startOrder(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Preparation started' : 'Failed to start preparation')),
    );
  }

  Future<void> _handleFinish(int id) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 1024, maxHeight: 1024);

    if (pickedFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo is required to finish the order')),
      );
      return;
    }

    final file = File(pickedFile.path);
    
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Packing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Is this photo correct?'),
            const SizedBox(height: 16),
            Image.file(file, height: 200, fit: BoxFit.cover),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retake / Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirm Finish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await context.read<OrderProvider>().finishOrder(id, photoFinal: file);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Order finished' : 'Failed to finish order')),
    );
  }

  Future<void> _handleCancel(int id) async {
    final success = await context.read<OrderProvider>().cancelOrder(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Preparation canceled' : 'Failed to cancel preparation')),
    );
  }
}
