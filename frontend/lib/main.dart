import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/user_session.dart';
import 'ui/screens/auth/welcome_role_screen.dart';
import 'ui/screens/auth/onboarding_carousel_screen.dart';
import 'ui/screens/auth/parent_registration_screen.dart';
import 'ui/screens/auth/otp_verification_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/forgot_password_screen.dart';
import 'ui/screens/auth/reset_password_screen.dart';
import 'ui/screens/onboarding/add_child_profile_screen.dart';
import 'ui/screens/parent/parent_main_scaffold.dart';
import 'ui/screens/parent/edit_profile_screen.dart';
import 'ui/screens/parent/recipe_details_screen.dart';
import 'ui/screens/parent/nutrition_risk_alerts_screen.dart';
import 'ui/screens/parent/anganwadi_connect_screen.dart';
import 'ui/screens/parent/reminders_screen.dart';
import 'ui/screens/clinician/professional_registration_screen.dart';
import 'ui/screens/clinician/clinician_dashboard_screen.dart';
import 'ui/screens/clinician/assigned_children_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession.instance.init();
  runApp(const PoshanSaathiApp());
}

class PoshanSaathiApp extends StatelessWidget {
  const PoshanSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoshanSaathi (પોષણ સાથી)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeRoleScreen(),
        '/onboarding': (context) => const OnboardingCarouselScreen(),
        '/register': (context) => const ParentRegistrationScreen(),
        '/otp_verify': (context) => const OtpVerificationScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/add_child': (context) => const AddChildProfileScreen(),
        '/dashboard': (context) => const ParentMainScaffold(initialIndex: 0),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/meals': (context) => const ParentMainScaffold(initialIndex: 1),
        '/growth': (context) => const ParentMainScaffold(initialIndex: 2),
        '/ai_assistant': (context) => const ParentMainScaffold(initialIndex: 3),
        '/recipe_details': (context) => const RecipeDetailsScreen(),
        '/risk_alerts': (context) => const NutritionRiskAlertsScreen(),
        '/anganwadi_connect': (context) => const AnganwadiConnectScreen(),
        '/reminders': (context) => const RemindersScreen(),
        '/clinician_register': (context) => const ProfessionalRegistrationScreen(),
        '/clinician_dashboard': (context) => const ClinicianDashboardScreen(),
        '/assigned_children': (context) => const AssignedChildrenScreen(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null && (uri.path == '/reset_password' || uri.path == '/reset-password')) {
          final token = uri.queryParameters['token'] ??
              (settings.arguments is String ? settings.arguments as String : null);
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(initialToken: token),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
