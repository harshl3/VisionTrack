import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/glass_container.dart';
import 'admin_login_screen.dart';
import 'user_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Badge Icon with Glow
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 64,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'VisionTrack GIS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textWhite,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your authorization protocol to access portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Admin Selection Glass Card
                  GlassContainer(
                    borderRadius: 24,
                    blur: 16,
                    padding: const EdgeInsets.all(24),
                    borderColor: AppColors.dangerRed.withValues(alpha: 0.4),
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerRed.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: AppColors.dangerRed,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'POLICE HEADQUARTERS',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'System Administrator Portal',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Full access to analytics dashboard, city-wide surveillance maps, range coverage, surveyor management, and camera registry.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dangerRed,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: AppColors.dangerRed.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminLoginScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LOGIN AS ADMIN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Surveyor Selection Glass Card
                  GlassContainer(
                    borderRadius: 24,
                    blur: 16,
                    padding: const EdgeInsets.all(24),
                    borderColor: AppColors.accentBlue.withValues(alpha: 0.4),
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: AppColors.accentBlue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FIELD SURVEYOR',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Field Operative Portal',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Register new CCTV hardware in real-time with automated GPS location, range coverage calculation, and orientation azimuth tags.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: AppColors.accentBlue.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserLoginScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LOGIN AS SURVEYOR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
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
