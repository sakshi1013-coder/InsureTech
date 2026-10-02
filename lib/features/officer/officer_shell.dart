import 'package:flutter/material.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'screens/officer_dashboard_screen.dart';
import 'screens/officer_claims_screen.dart';
import 'screens/officer_verification_screen.dart';
import 'screens/officer_alerts_screen.dart';
import 'screens/officer_profile_screen.dart';

class OfficerShell extends StatefulWidget {
  final int initialIndex;
  const OfficerShell({super.key, this.initialIndex = 0});

  static _OfficerShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<_OfficerShellState>();

  static void switchTab(BuildContext context, int index) {
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerProfileScreen()));
      return;
    }
    final state = of(context);
    if (state != null) {
      state.setIndex(index);
    } else {
      // If outside shell, navigate
      switch (index) {
        case 0:
          Navigator.pushNamed(context, '/officer/dashboard');
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerClaimsScreen()));
          break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerVerificationScreen()));
          break;
        case 3:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerAlertsScreen()));
          break;
      }
    }
  }

  @override
  State<OfficerShell> createState() => _OfficerShellState();
}

class _OfficerShellState extends State<OfficerShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  void setIndex(int index) {
    if (index >= 0 && index < _screens.length && _currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  final List<Widget> _screens = [
    const OfficerDashboardScreen(isEmbedded: true),
    const OfficerClaimsScreen(),
    const OfficerVerificationScreen(),
    const OfficerAlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment_rounded, 'label': 'Claims'},
      {'icon': Icons.verified_outlined, 'activeIcon': Icons.verified_rounded, 'label': 'Verification'},
      {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications_rounded, 'label': 'Alerts'},
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFE5EDF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1016587B),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (i) {
              final item = navItems[i];
              final isActive = _currentIndex == i;

              return GestureDetector(
                onTap: () => setIndex(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  height: 56,
                  padding: isActive
                      ? const EdgeInsets.symmetric(horizontal: 16)
                      : const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE0EFF7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (isActive ? item['activeIcon'] : item['icon']) as IconData,
                          size: 21,
                          color: isActive ? InsureXColors.veniceBlue : InsureXColors.rockBlue,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isActive ? InsureXColors.veniceBlue : InsureXColors.rockBlue,
                            fontSize: 10.5,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
