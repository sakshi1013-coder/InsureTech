import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/customer/customer_shell.dart';
import 'features/customer/screens/customer_notifications_screen.dart';
import 'features/customer/screens/customer_policy_detail_screen.dart';
import 'features/officer/officer_shell.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const InsureXApp());
}

class InsureXApp extends StatelessWidget {
  const InsureXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'InsureX – Digital Insurance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.customerHome: (_) => const CustomerShell(initialIndex: 0),
          AppRoutes.customerPolicies: (_) => const CustomerShell(initialIndex: 1),
          AppRoutes.customerClaims: (_) => const CustomerShell(initialIndex: 2),
          AppRoutes.customerPolicyDetail: (_) => const CustomerPolicyDetailScreen(),
          AppRoutes.customerNotifications: (_) => const CustomerNotificationsScreen(),
          AppRoutes.customerProfile: (_) => const CustomerShell(initialIndex: 3),
          AppRoutes.officerDashboard: (_) => const OfficerShell(initialIndex: 0),
          AppRoutes.officerClaims: (_) => const OfficerShell(initialIndex: 1),
          AppRoutes.officerVerification: (_) => const OfficerShell(initialIndex: 2),
          AppRoutes.officerAlerts: (_) => const OfficerShell(initialIndex: 3),
          AppRoutes.officerProfile: (_) => const OfficerShell(initialIndex: 4),
          AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}
