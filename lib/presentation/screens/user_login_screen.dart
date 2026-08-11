import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../../core/utils/dashboard_router.dart';
import 'user_registration_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnackBar('Please enter email and password.', AppColors.dangerRed);
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(_emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role != 'SURVEY') {
        await auth.logout();
        if (!mounted) return;
        _showSnackBar('Access Denied. Admin accounts must use Admin Login.', AppColors.dangerRed);
        return;
      }

      _showSnackBar('Surveyor Login Successful.', AppColors.successGreen);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => DashboardRouter.screenForRole(auth.role)),
        (route) => false,
      );
    } else {
      _showSnackBar('Login failed. Check server connection or credentials.', AppColors.dangerRed);
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_outlined,
                        size: 60,
                        color: AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'VisionTrack GIS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Field Operative Authentication',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Glassmorphism Card
                    GlassContainer(
                      borderRadius: 24,
                      blur: 18,
                      padding: const EdgeInsets.all(28),
                      borderColor: AppColors.accentBlue.withValues(alpha: 0.4),
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      child: Column(
                        children: [
                          GlassTextField(
                            controller: _emailCtrl,
                            hintText: 'Surveyor Email ID',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          GlassTextField(
                            controller: _passCtrl,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const CircularProgressIndicator(color: AppColors.accentBlue)
                              : SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _login,
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
                                      'LOGIN TO FIELD PORTAL',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserRegistrationScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'New Field Operative? ',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 15),
                          children: [
                            TextSpan(
                              text: 'Register Here',
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}
