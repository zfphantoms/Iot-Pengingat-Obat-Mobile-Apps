import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import '../providers/waktu_obat_provider.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final TextEditingController waktu1Controller = TextEditingController();
  final TextEditingController waktu2Controller = TextEditingController();
  final TextEditingController waktu3Controller = TextEditingController();

  bool isLoading = true;
  bool isSyncing = false;
  String deviceStatus = "UNKNOWN";

  final _deviceRef = FirebaseDatabase.instance.ref('device_status/alat_01');
  String? lastUpdateBefore;

  @override
  void initState() {
    super.initState();
    _loadWaktuObat();
    _listenDeviceStatus();
  }

  Future<void> _loadWaktuObat() async {
    final provider = Provider.of<WaktuObatProvider>(context, listen: false);
    await provider.fetchWaktuObat();
    final waktuList = provider.waktuObat;

    if (waktuList.length >= 3) {
      waktu1Controller.text = waktuList[0];
      waktu2Controller.text = waktuList[1];
      waktu3Controller.text = waktuList[2];
    }

    setState(() {
      isLoading = false;
    });
  }

  void _listenDeviceStatus() {
    _deviceRef.child('status').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          deviceStatus = event.snapshot.value.toString();
        });
      }
    });
  }

  Future<void> _syncDevice() async {
    setState(() => isSyncing = true);

    final now = DateTime.now();
    final timeout = now.add(const Duration(seconds: 10));

    try {
      final snapshot = await _deviceRef.child('last_update').get();
      if (snapshot.exists) {
        lastUpdateBefore = snapshot.value.toString();
      }

      // Tampilkan animasi sinkronisasi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/Capsule.json', width: 150, height: 150),
              const SizedBox(height: 16),
              const Text('Menyinkronkan dengan alat...'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

      bool synced = false;

      while (DateTime.now().isBefore(timeout)) {
        await Future.delayed(const Duration(seconds: 2));
        final newSnapshot = await _deviceRef.child('last_update').get();
        if (newSnapshot.exists &&
            newSnapshot.value.toString() != lastUpdateBefore) {
          synced = true;
          break;
        }
      }

      Navigator.pop(context); // Tutup animasi dialog

      if (synced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Alat sudah tersinkronisasi!')),
        );
      } else {
        await _deviceRef.child('status').set("OFFLINE");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Gagal sinkronisasi. Alat dianggap OFFLINE.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => isSyncing = false);
    }
  }

  @override
  void dispose() {
    waktu1Controller.dispose();
    waktu2Controller.dispose();
    waktu3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = deviceStatus == "ONLINE";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: const Text(
          "Informasi Obat",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Card(
                    color: Colors.teal[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.medication_outlined, color: Colors.teal),
                      title: const Text(
                        'Jadwal Waktu Minum Obat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Berikut adalah waktu minum obat yang telah disimpan.',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: isOnline ? Colors.green : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            deviceStatus,
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Waktu Minum Obat',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField("Waktu Pertama", waktu1Controller),
                          _buildInputField("Waktu Kedua", waktu2Controller),
                          _buildInputField("Waktu Ketiga", waktu3Controller),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.sync),
                            label: const Text("Sinkronkan Alarm"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSyncing ? null : _syncDevice,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              hintText: '-',
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
