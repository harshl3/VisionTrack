import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../../core/utils/dashboard_router.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnackBar('Please enter Admin credentials.', AppColors.dangerRed);
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).login(_emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.role != 'POLICE') {
        await authProvider.logout();
        if (!mounted) return;
        _showSnackBar('Access Denied. Non-admin account.', AppColors.dangerRed);
        return;
      }

      _showSnackBar('Admin Authentication Verified.', AppColors.successGreen);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardRouter.screenForRole(authProvider.role),
        ),
        (route) => false,
      );
    } else {
      _showSnackBar('Authorization failed. Check connection or credentials.', AppColors.dangerRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkGradient
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield Icon Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dangerRed.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dangerRed.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 60,
                      color: AppColors.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Headquarters Portal',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Restricted Command & Control Access',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Glassmorphism Card
                  GlassContainer(
                    borderRadius: 24,
                    blur: 18,
                    padding: const EdgeInsets.all(28),
                    borderColor: isDark
                        ? AppColors.dangerRed.withValues(alpha: 0.35)
                        : const Color(0xFFCBD5E1),
                    backgroundColor: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.88),
                    child: Column(
                      children: [
                        GlassTextField(
                          controller: _emailCtrl,
                          hintText: 'Admin Email ID',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        GlassTextField(
                          controller: _passCtrl,
                          hintText: 'Admin Security Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                            ? const CircularProgressIndicator(color: AppColors.dangerRed)
                            : SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.dangerRed,
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    shadowColor: AppColors.dangerRed.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.security, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'AUTHENTICATE ADMIN',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
