import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../../core/utils/dashboard_router.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnackBar('Please fill all required fields.', AppColors.dangerRed);
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Registration Successful!', AppColors.successGreen);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardRouter.screenForRole(
            Provider.of<AuthProvider>(context, listen: false).role,
          ),
        ),
        (route) => false,
      );
    } else {
      _showSnackBar('Registration failed. Email may already be registered.', AppColors.dangerRed);
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 25,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 54,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Operative Onboarding',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your surveyor field account',
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 36),

                  GlassContainer(
                    borderRadius: 24,
                    blur: 18,
                    padding: const EdgeInsets.all(28),
                    borderColor: AppColors.accentBlue.withValues(alpha: 0.4),
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    child: Column(
                      children: [
                        GlassTextField(
                          controller: _nameCtrl,
                          hintText: 'Full Name',
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          controller: _emailCtrl,
                          hintText: 'Official Email ID',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          controller: _passCtrl,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                            ? const CircularProgressIndicator(color: AppColors.accentBlue)
                            : SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: AppColors.accentBlue.withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'REGISTER & ENTER PORTAL',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
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
