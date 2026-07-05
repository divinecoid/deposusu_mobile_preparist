import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../widgets/otp_verification_dialog.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _emailController.text = user['email'] ?? '';
    }
  }

  Future<void> _handleSave() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newEmail = _emailController.text.trim();

    setState(() => _isLoading = true);

    // 1. Update Basic Profile (Name)
    if (newName != user['name']) {
      await authProvider.updateBasicProfile(newName, null); // Photo omitted for now
    }

    // 2. Update Phone (OTP Required)
    if (newPhone != user['phone'] && newPhone.isNotEmpty) {
      final success = await authProvider.requestOtp('phone', newPhone);
      if (success && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => OtpVerificationDialog(updateType: 'phone', newValue: newPhone),
        );
      }
    }

    // 3. Update Email (OTP Required)
    if (newEmail != user['email'] && newEmail.isNotEmpty) {
      final success = await authProvider.requestOtp('email', newEmail);
      if (success && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => OtpVerificationDialog(updateType: 'email', newValue: newEmail),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: null, // We can load photo here
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama lengkap',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Nomor HP', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Masukkan nomor HP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Masukkan email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
