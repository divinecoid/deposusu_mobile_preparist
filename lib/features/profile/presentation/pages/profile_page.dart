import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Data profil tidak ditemukan'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user['photo'] != null ? NetworkImage(user['photo']) : null,
                        child: user['photo'] == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        user['name'] ?? 'Preparist',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        user['email'] ?? 'Belum ada email',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_outline, color: Colors.blue),
                            title: const Text('Edit Profil'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.phone_outlined, color: Colors.green),
                            title: const Text('Nomor HP'),
                            subtitle: Text(user['phone'] ?? 'Belum ada nomor HP'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                            onTap: () {
                              context.read<AuthProvider>().logout();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
