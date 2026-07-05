import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../provider/order_provider.dart';
import '../../../../core/utils/watermark_util.dart';

class PackingDetailPage extends StatefulWidget {
  final int orderId;
  const PackingDetailPage({super.key, required this.orderId});

  @override
  State<PackingDetailPage> createState() => _PackingDetailPageState();
}

class _PackingDetailPageState extends State<PackingDetailPage> {
  final ImagePicker _picker = ImagePicker();
  File? _photoIsiPaket;
  File? _photoPaketFinal;
  DateTime? _timeIsiPaket;
  DateTime? _timePaketFinal;
  final TextEditingController _packerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final order = context.read<OrderProvider>().orders.firstWhere((o) => o.id == widget.orderId);
      if (order.packerName != null) {
        _packerController.text = order.packerName!;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(bool isFinal) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memproses foto...'), duration: Duration(seconds: 1)),
          );
        }

        final provider = context.read<OrderProvider>();
        final order = provider.orders.firstWhere((o) => o.id == widget.orderId);
        
        File watermarkedFile = await WatermarkUtil.addPackingWatermark(
          imageFile: File(pickedFile.path),
          orderId: order.orderNumber,
          adminName: _packerController.text.isNotEmpty ? _packerController.text : (order.assignedTo ?? 'Unknown'),
        );

        setState(() {
          if (isFinal) {
            _photoPaketFinal = watermarkedFile;
            _timePaketFinal = DateTime.now();
          } else {
            _photoIsiPaket = watermarkedFile;
            _timeIsiPaket = DateTime.now();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengambil foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFullScreenImage(File imageFile) {
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
            child: Image.file(imageFile),
          ),
        ),
      ),
    ));
  }

  void _handleStart(BuildContext context) async {
    final adminName = await showDialog<String>(
      context: context,
      builder: (context) {
        final staffs = ['Andi', 'Budi', 'Citra', 'Deni', 'Eka', 'Fajar'];
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Siapa yang bertugas?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: staffs.map((name) => ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context, name),
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (adminName == null || adminName.trim().isEmpty) return;
    if (!mounted) return;

    final provider = context.read<OrderProvider>();
    final success = await provider.startOrder(widget.orderId, adminName.trim());
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas Packing Diambil oleh ${adminName.trim()}!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil pesanan.'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleFinish(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    final order = provider.orders.firstWhere((o) => o.id == widget.orderId);

    final allChecked = order.items.every((item) => item.checkedQuantity == item.quantity);
    if (!allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pastikan semua barang sudah sesuai jumlahnya!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final packerName = order.assignedTo ?? 'Unknown';
    
    if (_photoIsiPaket == null || _photoPaketFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KEDUA foto bukti (isi paket & paket final) WAJIB diambil!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Update packer name in provider
    provider.updatePackerName(order.id, packerName);
    
    // Show Final Check Bottom Sheet
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, size: 64, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tahap Final Check', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    const Text(
                      'Demi menjaga kualitas, mohon pastikan sekali lagi:\n\n'
                      '1. Semua barang sudah masuk kardus/tas.\n'
                      '2. Tidak ada barang yang tertinggal.\n'
                      '3. Segel dan label resi sudah menempel kuat.',
                      style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          setModalState(() {
                            isLoading = true;
                          });
                          try {
                            // Finish order with both photos
                            final ok = await provider.finishPacking(order.id, _photoIsiPaket!.path, _photoPaketFinal!.path);
                            if (!bottomSheetContext.mounted) return;
                            Navigator.pop(bottomSheetContext, ok); // close bottom sheet and return result
                          } catch (e) {
                            if (!bottomSheetContext.mounted) return;
                            setModalState(() {
                              isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('✅ FINAL CHECK COMPLETE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(bottomSheetContext),
                      child: const Text('Batal, saya mau cek ulang', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (success != null && mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status Realtime terupdate! Notifikasi dikirim ke Kurir.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyelesaikan pesanan.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLocationPicker(BuildContext context, OrderProvider provider, int orderId, item) {
    final warehouseController = TextEditingController(text: item.warehouseName ?? '');
    final rackController = TextEditingController(text: item.rackName ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lokasi Ambil Barang', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(item.productName, style: TextStyle(fontSize: 13, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gudang field
              const Text('Gudang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: warehouseController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Contoh: Gudang Utama, Gudang B...',
                  prefixIcon: const Icon(Icons.warehouse_rounded, color: Color(0xFF2563EB)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rak field
              const Text('Nomor / Nama Rak', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: rackController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Contoh: A1, B3, Rak Depan...',
                  prefixIcon: const Icon(Icons.shelves, color: Color(0xFF2563EB)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Simpan button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.updateItemLocation(
                      orderId,
                      item.id,
                      warehouseName: warehouseController.text.trim().isEmpty ? null : warehouseController.text.trim(),
                      rackName: rackController.text.trim().isEmpty ? null : rackController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Simpan Lokasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScannerMockup(BuildContext context, dynamic order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Simulasi Scanner', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              const Text('Pilih skenario scan di bawah ini:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...order.items.map<Widget>((item) {
                      final isDone = item.checkedQuantity == item.quantity;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        subtitle: Text('${item.checkedQuantity} / ${item.quantity}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        trailing: isDone ? const Icon(Icons.warning_amber_rounded, color: Colors.orange) : const Icon(Icons.document_scanner_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          if (isDone) {
                            HapticFeedback.vibrate();
                            context.read<OrderProvider>().addManualLog(order.id, 'Peringatan: Mencoba men-scan ${item.productName} melebihi pesanan.');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.cancel_rounded, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('❌ Kelebihan Qty! ${item.productName} sudah lengkap.', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                backgroundColor: Colors.red[700],
                                duration: const Duration(milliseconds: 2000),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          } else {
                            HapticFeedback.heavyImpact();
                            SystemSound.play(SystemSoundType.click);
                            context.read<OrderProvider>().updateItemChecklist(order.id, item.id, item.checkedQuantity + 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('BEEP! 1x ${item.productName} masuk.')),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(milliseconds: 1000),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                    const Divider(),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.red[50],
                      title: const Text('Simulasi Scan Barang Salah', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      subtitle: const Text('Scan produk yang tidak ada di order'),
                      trailing: const Icon(Icons.error_outline_rounded, color: Colors.red),
                      onTap: () {
                        Navigator.pop(context);
                        HapticFeedback.vibrate();
                        context.read<OrderProvider>().addManualLog(order.id, 'Peringatan: Mencoba men-scan produk yang salah/tidak ada di order.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.cancel_rounded, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Expanded(child: Text('❌ Produk tidak sesuai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            backgroundColor: Colors.red[700],
                            duration: const Duration(milliseconds: 2000),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Packing', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700),
        actions: [
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              final idx = provider.orders.indexWhere((o) => o.id == widget.orderId);
              if (idx == -1) return const SizedBox();
              final order = provider.orders[idx];
              if (order.status != 'onpreparation') return const SizedBox();
              
              return IconButton(
                icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
                tooltip: 'Log Accountability',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (bottomContext) {
                      return SafeArea(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Accountability Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        Text('Catatan aktivitas packing', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (order.editLogs.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text('Belum ada log aktivitas tercatat.', style: TextStyle(color: Colors.grey)),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: order.editLogs.length,
                                    separatorBuilder: (_, __) => Divider(color: Colors.grey[200]),
                                    itemBuilder: (context, idx) {
                                      final log = order.editLogs[idx];
                                      final isWarning = log.contains('Peringatan');
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          isWarning ? Icons.warning_amber_rounded : Icons.history_rounded, 
                                          color: isWarning ? Colors.orange : Colors.grey
                                        ),
                                        title: Text(
                                          log,
                                          style: TextStyle(fontSize: 14, color: isWarning ? Colors.orange[800] : Colors.black87),
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(bottomContext),
                                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final idx = provider.orders.indexWhere((o) => o.id == widget.orderId);
          if (idx == -1) {
            return const Center(child: Text('Order not found'));
          }
          final order = provider.orders[idx];
          final isPreparation = order.status == 'onpreparation';
          
          final checkedCount = order.items.fold(0, (sum, item) => sum + item.checkedQuantity);
          final totalCount = order.items.fold(0, (sum, item) => sum + item.quantity);
          final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

          return Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            order.orderNumber,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPreparation ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFF3B82F6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPreparation ? '🟠 PREPARING' : '🟡 NEW ORDER', 
                            style: TextStyle(color: isPreparation ? const Color(0xFFD97706) : const Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Flexible(child: Text(order.customerName, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Flexible(child: Text(order.orderSource, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    if (order.assignedTo != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.assignment_ind_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Flexible(child: Text('Assigned to: ${order.assignedTo}', style: const TextStyle(fontSize: 14, color: Color(0xFFD97706), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progress Packing', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                        Text('$checkedCount/$totalCount Item', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checklist Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daftar Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (isPreparation)
                            TextButton.icon(
                              onPressed: () => _showScannerMockup(context, order),
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text('Scan'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            final isDone = item.checkedQuantity == item.quantity;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDone ? const Color(0xFF10B981) : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rp ${item.subtotal.toStringAsFixed(0)}',
                                              style: TextStyle(color: isDone ? const Color(0xFF10B981).withOpacity(0.7) : Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Stepper Control
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDone ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: isDone ? const Color(0xFF10B981).withOpacity(0.3) : Colors.transparent),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: item.checkedQuantity > 0 ? () {
                                                HapticFeedback.lightImpact();
                                                provider.updateItemChecklist(order.id, item.id, item.checkedQuantity - 1);
                                              } : null,
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Icon(Icons.remove_rounded, size: 24, color: item.checkedQuantity > 0 ? Colors.black87 : Colors.grey),
                                              ),
                                            ),
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 44),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${item.checkedQuantity} / ${item.quantity}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: isDone ? const Color(0xFF10B981) : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: !isDone ? () {
                                                HapticFeedback.lightImpact();
                                                provider.updateItemChecklist(order.id, item.id, item.checkedQuantity + 1);
                                              } : null,
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Icon(Icons.add_rounded, size: 24, color: isDone ? Colors.grey : Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Lokasi Ambil (Gudang & Rak)
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: isPreparation ? () => _showLocationPicker(context, provider, order.id, item) : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: (item.warehouseName != null || item.rackName != null)
                                            ? const Color(0xFF2563EB).withOpacity(0.07)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (item.warehouseName != null || item.rackName != null)
                                              ? const Color(0xFF2563EB).withOpacity(0.3)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 16,
                                            color: (item.warehouseName != null || item.rackName != null)
                                                ? const Color(0xFF2563EB)
                                                : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              (item.warehouseName != null || item.rackName != null)
                                                  ? '${item.warehouseName ?? '-'}  •  Rak: ${item.rackName ?? '-'}'
                                                  : 'Ketuk untuk isi lokasi ambil...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: (item.warehouseName != null || item.rackName != null)
                                                    ? const Color(0xFF2563EB)
                                                    : Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                          if (isPreparation)
                                            Icon(Icons.edit_rounded, size: 14, color: Colors.grey[400]),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      if (isPreparation && progress == 1.0) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 2),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Semua item telah diverifikasi!\nSilakan masukkan ke tas/kardus dan pasang segel (seal) paket.',
                                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (isPreparation) ...[
                        // Packer Info Section
                        const Text('Konfirmasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.assignment_ind_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Staf Bertugas', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                                        Text(
                                          order.assignedTo ?? 'Belum ada',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Foto Isi Paket
                            const Text('Foto 1: Isi Paket (Sebelum Disegel) *', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _photoIsiPaket == null ? _pickImage(false) : _showFullScreenImage(_photoIsiPaket!),
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _photoIsiPaket != null ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: _photoIsiPaket == null 
                                    ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2)
                                    : null,
                                ),
                                child: _photoIsiPaket != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.file(_photoIsiPaket!, fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 0, left: 0, right: 0, bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 12,
                                            left: 16,
                                            right: 16,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Disimpan otomatis:', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                                Text('${_timeIsiPaket?.toString().substring(0, 16)} WIB', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                Text('Staf: ${order.assignedTo ?? "Belum diisi"}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: GestureDetector(
                                              onTap: () => _pickImage(false),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 16),
                                                    SizedBox(width: 8),
                                                    Text('Retake', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                              ]
                                            ),
                                            child: Icon(Icons.inventory_2_outlined, size: 32, color: Theme.of(context).colorScheme.primary),
                                          ),
                                          const SizedBox(height: 16),
                                          Text('Ketuk untuk Ambil Foto Isi', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Foto Paket Final
                            const Text('Foto 2: Paket Final + Label Resi *', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _photoPaketFinal == null ? _pickImage(true) : _showFullScreenImage(_photoPaketFinal!),
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _photoPaketFinal != null ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: _photoPaketFinal == null 
                                    ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2)
                                    : null,
                                ),
                                child: _photoPaketFinal != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.file(_photoPaketFinal!, fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 0, left: 0, right: 0, bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 12,
                                            left: 16,
                                            right: 16,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Disimpan otomatis:', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                                Text('${_timePaketFinal?.toString().substring(0, 16)} WIB', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                Text('Staf: ${order.assignedTo ?? "Belum diisi"}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: GestureDetector(
                                              onTap: () => _pickImage(true),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 16),
                                                    SizedBox(width: 8),
                                                    Text('Retake', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                              ]
                                            ),
                                            child: Icon(Icons.local_shipping_outlined, size: 32, color: Theme.of(context).colorScheme.primary),
                                          ),
                                          const SizedBox(height: 16),
                                          Text('Ketuk untuk Ambil Foto Final', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final idx = provider.orders.indexWhere((o) => o.id == widget.orderId);
          if (idx == -1) return const SizedBox.shrink();
          final isPreparation = provider.orders[idx].status == 'onpreparation';

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10)),
              ],
            ),
            child: SafeArea(
              child: isPreparation ? ElevatedButton(
                onPressed: () => _handleFinish(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lanjut ke Final Check', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ) : ElevatedButton(
                onPressed: () => _handleStart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ambil Tugas Packing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
