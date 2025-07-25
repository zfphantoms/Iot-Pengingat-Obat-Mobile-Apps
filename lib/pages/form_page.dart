import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/waktu_obat_provider.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final List<String> jamList = List.generate(
    14,
    (index) => '${(index + 7).toString().padLeft(2, '0')}:00',
  );

  final Map<String, TextEditingController> controllers = {};
  Map<String, String> jadwalTersimpan = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    final provider = Provider.of<WaktuObatProvider>(context, listen: false);
    await provider.fetchJadwalHarian();
    jadwalTersimpan = provider.jadwalHarian;

    for (var jam in jamList) {
      controllers[jam] = TextEditingController(
        text: jadwalTersimpan[jam] ?? '',
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🔁 Fungsi untuk membuat jadwal otomatis minum obat
  Map<String, String> generateJadwalObatOptimal() {
    final optimalJam = ['08:00', '13:00', '18:00'];
    final Map<String, String> jadwal = {};

    for (var jam in jamList) {
      jadwal[jam] = optimalJam.contains(jam) ? 'Minum Obat' : '';
    }

    return jadwal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kegiatan Harian', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.access_time, color: Colors.teal),
                        title: Text(
                          'Catat Jadwal Obat & Aktivitas',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text('Silakan isi hanya waktu yang dibutuhkan.'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: jamList.map((jam) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jam $jam',
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: controllers[jam],
                                    decoration: InputDecoration(
                                      hintText: jadwalTersimpan[jam]?.isNotEmpty == true
                                          ? jadwalTersimpan[jam]
                                          : 'Tulis aktivitas pada jam $jam (boleh kosong)',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text('Apakah Anda yakin ingin menyimpan jadwal ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context); // Tutup konfirmasi

                                    // Tampilkan animasi loading
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        child: Center(
                                          child: Lottie.asset(
                                            'assets/animations/capsule.json',
                                            height: 150,
                                          ),
                                        ),
                                      ),
                                    );

                                    final provider = Provider.of<WaktuObatProvider>(context, listen: false);

                                    // Data manual dari form
                                    final inputManual = {
                                      for (var jam in jamList) jam: controllers[jam]!.text.trim()
                                    };

                                    // Data otomatis (minum obat)
                                    final jadwalOptimal = generateJadwalObatOptimal();

                                    // Simpan ke Firebase
                                    await provider.setJadwalHarian(inputManual);
                                    provider.autoScheduleWaktuObat();;

                                    Navigator.pop(context); // Tutup animasi

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Data berhasil disimpan & jadwal obat dibuat!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                  child: const Text('Ya, Simpan'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'SIMPAN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }
}
