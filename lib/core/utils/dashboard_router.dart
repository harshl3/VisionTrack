import 'package:flutter/material.dart';
import '../../presentation/screens/admin_dashboard_screen.dart';
import '../../presentation/screens/surveyor_dashboard_screen.dart';

class DashboardRouter {
  static Widget screenForRole(String? role) {
    if (role == 'POLICE') {
      return const AdminDashboardScreen();
    }
    return const SurveyorDashboardScreen();
  }
}
