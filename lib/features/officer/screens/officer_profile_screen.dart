import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import '../../auth/screens/login_screen.dart';

class OfficerProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const OfficerProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  bool _isOnDuty = true;
  bool _urgentAlerts = true;
  bool _offlineCache = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final officer = auth.officerProfile;

    final displayName = officer?.name.isNotEmpty == true
        ? officer!.name
        : (user?.name.isNotEmpty == true ? user!.name : 'Marcus Vance');
    final displayEmail = officer?.email.isNotEmpty == true
        ? officer!.email
        : (user?.email.isNotEmpty == true ? user!.email : 'marcus.vance@insurex.com');
    final displayPhone = officer?.phone.isNotEmpty == true
        ? officer!.phone
        : (user?.phone.isNotEmpty == true ? user!.phone : '+1 (555) 234-5678');
    final employeeId = officer?.employeeId.isNotEmpty == true
        ? officer!.employeeId
        : 'EMP-7721';
    final department = officer?.department.isNotEmpty == true
        ? officer!.department
        : 'Claims Adjudication & Field Investigation';
    final designation = officer?.designation.isNotEmpty == true
        ? officer!.designation
        : 'Senior Claims Adjuster';
    final specialty = officer?.specialty.isNotEmpty == true
        ? officer!.specialty
        : 'Automotive & Casualty Forensics';
    final initials = officer?.initials ?? (user?.initials ?? 'MV');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header (compact, InsureX Duty style)
            _buildHeader(context),

            // Scrollable Profile content (White cards on light background)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                children: [
                  // 1. Officer Identity Summary Card (White Card)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar with Active Indicator
                        Stack(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryBlue, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _isOnDuty ? AppColors.success : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Name & Designation
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          designation,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Badges Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.badge_outlined, size: 13, color: AppColors.primaryBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    employeeId,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isOnDuty ? AppColors.successLight : AppColors.secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isOnDuty
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _isOnDuty ? AppColors.success : AppColors.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isOnDuty ? 'ON ACTIVE DUTY' : 'OFF DUTY',
                                    style: TextStyle(
                                      color: _isOnDuty ? AppColors.success : AppColors.textSecondary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Personnel Credentials Card (White Card)
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.verified_outlined, size: 16, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Personnel Credentials',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _credRow('Employee ID', employeeId),
                        _credRow('Department', department),
                        _credRow('Designation', designation),
                        _credRow('Specialty Focus', specialty),
                        _credRow('Official Email', displayEmail),
                        _credRow('Direct Phone', displayPhone),
                        _credRow('Assigned Zone', 'Metro North (Zone 4)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Operational Preferences Card (White Card)
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.lightPurple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.purple),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Field Desk Preferences',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _switchRow(
                          'Active Duty Status',
                          'Receive field dispatches & new claims',
                          _isOnDuty,
                          (v) => setState(() => _isOnDuty = v),
                        ),
                        _divider(),
                        _switchRow(
                          'Urgent SLA Alerts',
                          'Audio notifications on critical SLA timers',
                          _urgentAlerts,
                          (v) => setState(() => _urgentAlerts = v),
                        ),
                        _divider(),
                        _switchRow(
                          'Offline Cache',
                          'Sync evidence and claims for offline field use',
                          _offlineCache,
                          (v) => setState(() => _offlineCache = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Account, Settings, Help & Support, Sign Out Card (White Card)
                  AppCard(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _menuRow(
                          Icons.manage_accounts_outlined,
                          'Account',
                          'Security credentials and officer profile details',
                          () => _showInfoModal(context, 'Account Details', 'Your officer account is authenticated and synced with InsureX enterprise directory.'),
                        ),
                        _divider(),
                        _menuRow(
                          Icons.settings_outlined,
                          'Settings',
                          'App configuration, theme, cache & data',
                          () => _showInfoModal(context, 'Settings', 'Officer portal version 2.4.0. Build 108. Auto-sync active.'),
                        ),
                        _divider(),
                        _menuRow(
                          Icons.help_outline_rounded,
                          'Help & Support',
                          'Field desk standard operating procedures & contact',
                          () => _showInfoModal(context, 'Help & Support', 'Claims Escalation Hotline: +1 (800) 555-0199\nField Operations Support: desk@insurex.com'),
                        ),
                        _divider(),

                        // CRITICAL: Sign Out Button
                        InkWell(
                          onTap: () => _confirmSignOut(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign Out',
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'End duty session and return to login',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.error),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.veniceBlue,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          if (!widget.isEmbedded && Navigator.canPop(context))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Officer Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'FIELD INVESTIGATION CREDENTIALS',
                style: TextStyle(
                  color: AppColors.rockBlueLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_outlined, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'ACTIVE OFFICER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(color: AppColors.border, height: 1, thickness: 1);

  void _showInfoModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your active duty session and sign out of the Officer Portal?',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
