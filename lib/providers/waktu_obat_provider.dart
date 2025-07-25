import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaktuObatProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Map<String, String> _jadwalHarian = {}; // Jam => Aktivitas
  List<String> _waktuObat = [];

  Map<String, String> get jadwalHarian => _jadwalHarian;
  List<String> get waktuObat => _waktuObat;

  /// Simpan data kegiatan harian ke memory & Firebase
  Future<void> setJadwalHarian(Map<String, String> data) async {
    _jadwalHarian = data;
    notifyListeners();

    try {
      if (_uid != null) {
        await _dbRef.child('jadwal/$_uid').set(_jadwalHarian);
      }
    } catch (e) {
      debugPrint('❌ Gagal simpan jadwal ke Firebase: $e');
    }
  }

  /// Simpan waktu minum obat manual
  Future<void> setWaktuObat(List<String> waktuList) async {
    _waktuObat = waktuList;
    notifyListeners();

    try {
      if (_uid != null) {
        await _dbRef.child('waktu_obat/$_uid').set(_waktuObat);
      }
    } catch (e) {
      debugPrint('❌ Gagal simpan waktu obat ke Firebase: $e');
    }
  }

  /// Auto-suggest waktu terbaik berdasarkan jam kosong
    void autoScheduleWaktuObat() {
    final allHours = List.generate(14, (i) => '${(i + 7).toString().padLeft(2, '0')}:00'); // 07:00–20:00

    // Buat map jam kosong dari jadwal harian
    final jamKosong = allHours.where((jam) {
      final aktivitas = _jadwalHarian[jam];
      return aktivitas == null || aktivitas.trim().isEmpty;
    }).toList();

    List<String> selectedTimes = [];

    /// Step 1: cari waktu kosong pagi di bawah jam 10
    final pagiKosong = jamKosong.where((j) => int.parse(j.split(":")[0]) < 10).toList();

    if (pagiKosong.isNotEmpty) {
      final jamPertama = pagiKosong.first;
      selectedTimes.add(jamPertama);

      int jam1 = int.parse(jamPertama.split(":")[0]);

      /// Step 2: cari jam kedua (±6 jam dari jam pertama)
      int targetJam2 = jam1 + 6;
      String jamKedua = '${targetJam2.toString().padLeft(2, '0')}:00';
      String jamKedua30 = '${targetJam2.toString().padLeft(2, '0')}:30';

      if (_jadwalHarian[jamKedua] == null || _jadwalHarian[jamKedua]!.trim().isEmpty) {
        selectedTimes.add(jamKedua);
      } else if (_jadwalHarian[jamKedua30] == null || _jadwalHarian[jamKedua30]!.trim().isEmpty) {
        selectedTimes.add(jamKedua30);
      }

      /// Step 3: cari jam ketiga (±6 jam dari jam kedua)
      if (selectedTimes.length == 2) {
        final jamKeduaInt = selectedTimes[1].contains(":")
            ? int.parse(selectedTimes[1].split(":")[0])
            : int.parse(selectedTimes[1]);

        int targetJam3 = jamKeduaInt + 6;
        String jamKetiga = '${targetJam3.toString().padLeft(2, '0')}:00';
        String jamKetiga30 = '${targetJam3.toString().padLeft(2, '0')}:30';

        if (_jadwalHarian[jamKetiga] == null || _jadwalHarian[jamKetiga]!.trim().isEmpty) {
          selectedTimes.add(jamKetiga);
        } else if (_jadwalHarian[jamKetiga30] == null || _jadwalHarian[jamKetiga30]!.trim().isEmpty) {
          selectedTimes.add(jamKetiga30);
        }
      }
    }

    // Jika tidak cukup 3 jadwal, fallback ke default
    if (selectedTimes.length < 3) {
      selectedTimes = ['09:30', '13:30', '18:30'];
    }

    _waktuObat = selectedTimes;
    notifyListeners();

    if (_uid != null) {
      _dbRef.child('waktu_obat/$_uid').set(_waktuObat);
    }
  }

  /// Ambil jadwal harian dari Firebase
  Future<void> fetchJadwalHarian() async {
    if (_uid == null) return;
    final ref = _dbRef.child('jadwal/$_uid');

    try {
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _jadwalHarian = data.map((key, value) => MapEntry(key, value.toString()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Gagal mengambil jadwal dari Firebase: $e');
    }
  }

  Future<void> setJadwalObatOptimal(Map<String, String> jadwalOptimal) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final ref = FirebaseDatabase.instance.ref('jadwal_obat_optimal/$uid');
  await ref.set(jadwalOptimal);
}

  Future<void> fetchWaktuObat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 🔁 Ganti path menjadi 'jadwal_obat'
    final ref = _dbRef.child('jadwal_obat/$uid');

    try {
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Ambil jam-jam yang nilainya "Minum Obat"
        _waktuObat = data.entries
            .where((entry) => entry.value == "Minum Obat")
            .map((entry) => entry.key)
            .toList()
          ..sort();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Gagal mengambil waktu obat dari Firebase: $e');
    }
  }


}
