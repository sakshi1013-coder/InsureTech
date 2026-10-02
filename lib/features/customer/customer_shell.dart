import 'package:flutter/material.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'screens/customer_home_screen.dart';
import 'screens/customer_claims_screen.dart';
import 'screens/customer_policies_screen.dart';
import 'screens/customer_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  final int initialIndex;
  const CustomerShell({super.key, this.initialIndex = 0});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_CustomerShellState>();
    if (state != null) {
      state.setIndex(index);
    }
  }

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _currentIndex;

  void setIndex(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
  }

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const CustomerPoliciesScreen(),
    const CustomerClaimsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.assignment_outlined, 'label': 'Policies'},
      {'icon': Icons.shield_outlined, 'label': 'Claims'},
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
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  height: 56,
                  padding: isActive
                      ? const EdgeInsets.symmetric(horizontal: 18)
                      : const EdgeInsets.symmetric(horizontal: 12),
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
                          item['icon'] as IconData,
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
