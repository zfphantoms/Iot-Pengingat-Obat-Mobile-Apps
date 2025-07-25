import 'package:flutter/material.dart';
import 'form_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ✅ Logo di tengah atas
              Center(
                child: Image.asset(
                  'assets/logo.png', // pastikan file logo.png sudah di-declare di pubspec.yaml
                  height: 100,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Nama Aplikasi
              const Text(
                'Pengingat Obat Cerdas',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 32),

              // ✅ Card Informasi
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Pengguna: Novia',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '📋 Masukkan kegiatan harian Anda agar sistem dapat mengingatkan Anda secara otomatis.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FormPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_note),
                          label: const Text(
                            'Isi Jadwal Obat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ✅ Tips atau catatan
              Card(
                color: Colors.teal[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.lightbulb, color: Colors.teal),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tips: Jangan lewatkan waktu minum obat agar penyembuhan maksimal!',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
