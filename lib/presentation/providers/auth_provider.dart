import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  int? _userId;
  String? _userName;

  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  String? get userName => _userName;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _role == 'POLICE';
  bool get isSurveyor => _role == 'SURVEY';

  Future<bool> login(String email, String password) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _role = data['user']['role'];
        _userId = data['user']['id'];
        _userName = data['user']['name'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('user_role', _role!);
        await prefs.setInt('user_id', _userId!);
        await prefs.setString('user_name', _userName!);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return await login(email, password);
      }
      return false;
    } catch (e) {
      debugPrint('Register Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _userId = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('jwt_token')) return;

    _token = prefs.getString('jwt_token');
    _role = prefs.getString('user_role');
    _userId = prefs.getInt('user_id');
    _userName = prefs.getString('user_name');
    notifyListeners();
  }
}
