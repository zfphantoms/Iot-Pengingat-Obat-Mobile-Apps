import 'package:flutter/material.dart';

class WaktuObatProvider with ChangeNotifier {
  List<String> _waktuObat = [];

  List<String> get waktuObat => _waktuObat;

  void setWaktuObat(List<String> waktuList) {
    _waktuObat = waktuList;
    notifyListeners();
  }
}
