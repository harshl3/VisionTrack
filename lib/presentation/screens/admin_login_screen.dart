import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'map_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter explicit Admin credentials.'), backgroundColor: AppColors.dangerRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(_emailCtrl.text, _passCtrl.text);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Security check: Only allow if Role is POLICE
      if (Provider.of<AuthProvider>(context, listen: false).role != 'POLICE') {
        Provider.of<AuthProvider>(context, listen: false).logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access Denied. Non-admin account.'), backgroundColor: AppColors.dangerRed),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin Protocol Activated.'), backgroundColor: AppColors.successGreen),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MapDashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorization failed. Invalid credentials.'), backgroundColor: AppColors.dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Direct Auth')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Headquarters Access',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textWhite),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(hintText: 'Admin Email ID'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(hintText: 'Admin Password'),
                obscureText: true,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.dangerRed)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
                      onPressed: _login,
                      child: const Text('SECURE ADMIN LOGIN'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
