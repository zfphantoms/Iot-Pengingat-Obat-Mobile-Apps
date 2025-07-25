import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  String _password = '';

  String get username => _username;
  String get password => _password;

  void setUser({required String username, required String password}) {
    _username = username;
    _password = password;
    notifyListeners();
  }

  void clearUser() {
    _username = '';
    _password = '';
    notifyListeners();
  }
}
