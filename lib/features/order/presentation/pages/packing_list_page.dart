import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/order_provider.dart';
import '../models/order_model.dart';

class PackingListPage extends StatefulWidget {
  const PackingListPage({super.key});

  @override
  State<PackingListPage> createState() => _PackingListPageState();
}

class _PackingListPageState extends State<PackingListPage> {
  String _selectedStatus = 'onprocess';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(status: _selectedStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing List'),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            dropdownColor: Colors.blueAccent,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'onprocess', child: Text('On Process')),
              DropdownMenuItem(value: 'onpreparation', child: Text('On Preparation')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
                context.read<OrderProvider>().fetchOrders(status: value);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchOrders(status: _selectedStatus),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return _buildOrderCard(order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
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
                          Text('${item.quantity}x ${item.productName}'),
                          Text('\$${item.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
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
      return ElevatedButton(
        onPressed: () => _handleFinish(order.id),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        child: const Text('Finish'),
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
    final success = await context.read<OrderProvider>().finishOrder(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Order finished' : 'Failed to finish order')),
    );
  }
}
