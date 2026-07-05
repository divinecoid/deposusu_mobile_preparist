import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String updateType; // 'phone' or 'email'
  final String newValue;

  const OtpVerificationDialog({
    super.key,
    required this.updateType,
    required this.newValue,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.verifyAndUpdateSecureProfile(
      widget.updateType,
      widget.newValue,
      otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil diperbarui'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP tidak valid'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verifikasi OTP',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Masukkan kode OTP yang dikirimkan ke ${widget.newValue}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: 'Contoh: 1234',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
