import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _fadeCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2200), () => _navigate());
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _navigate() async {
    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      await auth.init();
      if (!mounted) return;

      if (!auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }

      switch (auth.role) {
        case AppConstants.roleAdmin:
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          break;
        case AppConstants.roleOfficer:
          Navigator.pushReplacementNamed(context, AppRoutes.officerDashboard);
          break;
        default:
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      }
    } catch (e) {
      debugPrint('Navigation notice: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text('InsureX', style: AppTextStyles.displayLarge.copyWith(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text('ENTERPRISE', style: AppTextStyles.labelSmall.copyWith(
                    letterSpacing: 4, color: AppColors.primary, fontSize: 11,
                  )),
                  const SizedBox(height: 8),
                  Text('Digital Insurance Claim Management', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Initializing secure session...', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
