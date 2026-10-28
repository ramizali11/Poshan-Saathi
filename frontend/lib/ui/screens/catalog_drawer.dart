import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';

class CatalogDrawer extends StatelessWidget {
  const CatalogDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryContainer.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: AppColors.primaryDark, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'PoshanSaathi Screens',
                        style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '18 Stitch Design System Screens',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _sectionHeader('AUTHENTICATION & ONBOARDING'),
                  _drawerItem(context, '1. Welcome & Role Selection', Icons.login_rounded, '/welcome'),
                  _drawerItem(context, '2. Onboarding Carousel (4 Pillars)', Icons.view_carousel_outlined, '/onboarding'),
                  _drawerItem(context, '3. Parent Registration (Step 1/2)', Icons.person_add_outlined, '/register'),
                  _drawerItem(context, '4. OTP 6-Digit Verification', Icons.mark_email_read_outlined, '/otp_verify'),
                  _drawerItem(context, '5. Login & ABHA / ABDM Access', Icons.lock_outline, '/login'),
                  _drawerItem(context, '6. Password Recovery & Reset', Icons.lock_reset_rounded, '/forgot_password'),
                  _drawerItem(context, '7. Add Child Profile', Icons.child_care_rounded, '/add_child'),

                  const Divider(),
                  _sectionHeader('PARENT NUTRITION & GROWTH HUB'),
                  _drawerItem(context, '8. Parent Dashboard & Growth Hub', Icons.dashboard_rounded, '/dashboard'),
                  _drawerItem(context, '9. Smart Meal Planner (5 Groups)', Icons.restaurant_menu_rounded, '/meals'),
                  _drawerItem(context, '10. Recipe Details & Iron Synergy', Icons.menu_book_rounded, '/recipe_details'),
                  _drawerItem(context, '11. Growth Monitoring & WHO Curves', Icons.show_chart_rounded, '/growth'),
                  _drawerItem(context, '12. AI Nutrition Assistant & Voice', Icons.auto_awesome, '/ai_assistant'),
                  _drawerItem(context, '13. Nutrition Risk Alerts', Icons.warning_amber_rounded, '/risk_alerts'),
                  _drawerItem(context, '14. Anganwadi Worker Connectivity', Icons.volunteer_activism_rounded, '/anganwadi_connect'),
                  _drawerItem(context, '15. Reminders & Notification Alarms', Icons.alarm_rounded, '/reminders'),

                  const Divider(),
                  _sectionHeader('CLINICIAN & DOCTOR PORTAL'),
                  _drawerItem(context, '16. Clinician Credentialing App', Icons.verified_user_outlined, '/clinician_register'),
                  _drawerItem(context, '17. Doctor Clinical Dashboard', Icons.medical_services_rounded, '/clinician_dashboard'),
                  _drawerItem(context, '18. Assigned Children Directory', Icons.people_outline_rounded, '/assigned_children'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 6),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: AppColors.primaryDark),
      title: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route);
      },
    );
  }
}
