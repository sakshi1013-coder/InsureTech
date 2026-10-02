import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/models/user_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'package:insurex_app/models/policy_model.dart';
import 'package:intl/intl.dart';
import 'officer_claim_detail_screen.dart';
import 'officer_profile_screen.dart';
import '../officer_shell.dart';
import '../../auth/screens/login_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  final bool isEmbedded;
  const OfficerDashboardScreen({super.key, this.isEmbedded = false});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _navIndex = 0;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final officer = auth.officerProfile;
    final fs = FirestoreService();
    final initials = officer?.initials ?? (user?.initials ?? 'MV');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Venice Blue Enterprise Header (as in screenshot & palette)
            _buildHeader(context, user?.name ?? 'Marcus Vance', officer, initials),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Officer summary and 4 Stats Tiles
                  _buildStatsRow(officer),

                  // Venice Blue Quota Progress Card (as in screenshot)
                  _buildQuotaBar(),

                  // Underwritten Policies Section
                  _buildPoliciesSection(fs),

                  const SizedBox(height: 8),

                  // Search Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(color: AppColors.textBody, fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: 'Search Claim ID, Policy #, Insured...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.rockBlue),
                          suffixIcon: Icon(Icons.qr_code_scanner_outlined, size: 20, color: AppColors.rockBlue),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips
                  _buildFilterChips(),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Claims Requiring Action',
                          style: TextStyle(
                            color: AppColors.veniceBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '3 Critical Items',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stream of Claims
                  StreamBuilder<List<ClaimModel>>(
                    stream: fs.getAllClaims(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      }
                      var claims = (snap.data ?? []).toList();
                      claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      if (_searchQuery.isNotEmpty) {
                        claims = claims.where((c) =>
                          c.claimNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          c.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          c.claimType.toLowerCase().contains(_searchQuery.toLowerCase())
                        ).toList();
                      }
                      if (_navIndex == 2) {
                        claims = claims.where((c) =>
                          c.status == AppConstants.statusUnderVerification ||
                          c.status.toLowerCase().contains('verification')
                        ).toList();
                      } else if (_navIndex == 3) {
                        claims = claims.where((c) => c.priority == 'Critical' || c.priority == 'High').toList();
                      } else if (_filterStatus != 'All') {
                        if (_filterStatus.contains('High Priority') || _filterStatus.contains('SLA')) {
                          claims = claims.where((c) => c.priority == 'Critical' || c.priority == 'High').toList();
                        } else if (_filterStatus == 'Motor') {
                          claims = claims.where((c) => c.claimType.toLowerCase().contains('vehicle') || c.claimType.toLowerCase().contains('motor')).toList();
                        } else {
                          claims = claims.where((c) => c.status == _filterStatus).toList();
                        }
                      }
                      if (claims.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: EmptyState(icon: Icons.assignment_outlined, title: 'No Claims Found', subtitle: 'Try clearing your filter.'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _claimCard(context, claims[i]),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isEmbedded ? null : _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context, String name, OfficerModel? officer, String initials) {
    return Container(
      color: AppColors.veniceBlue,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            // Branding
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text('InsureX', style: TextStyle(color: AppColors.merino, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 6),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('DUTY', style: TextStyle(color: AppColors.rockBlue, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('OFFICER PORTAL / FIELD DESK', style: TextStyle(color: AppColors.rockBlueLight, fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            // Alert bell with unread indicator (Navigates to Alerts Tab)
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => OfficerShell.switchTab(context, 3),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.veniceBlueDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x3384B3CE)),
                    ),
                    child: const Center(
                      child: Icon(Icons.notifications_outlined, size: 19, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // User Avatar (taps to view Profile)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OfficerProfileScreen()),
                );
              },
              child: Tooltip(
                message: 'Officer Profile',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.veniceBlueDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.rockBlue, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(OfficerModel? officer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        children: [
          // ROW 2: Officer Identity & Status Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x0616587B), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.veniceBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          officer?.name.isNotEmpty == true ? officer!.name[0] : 'M',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              officer?.name ?? 'Marcus Vance',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.rockBlueLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0x3384B3CE)),
                            ),
                            child: Text(
                              '#${officer?.employeeId ?? 'OFF-4491'}',
                              style: const TextStyle(color: AppColors.veniceBlue, fontWeight: FontWeight.w700, fontSize: 10.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${officer?.department ?? 'Auto & Casualty Desk'} • ${officer?.designation ?? 'Senior Field Adjuster'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: const [
                          Icon(Icons.sync, size: 13, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Synced 4m ago (DMV & DocuScan)',
                            style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // On Duty Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('ON DUTY', style: TextStyle(color: Color(0xFF087A5A), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Stats Cards (Hierarchy: Small label, large number, contextual metric, supporting status)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final crossAxisCount = isWide ? 4 : 2;
              final childAspectRatio = constraints.maxWidth < 420 ? 1.35 : (isWide ? 1.6 : 1.45);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  _statTile(
                    label: 'ASSIGNED CLAIMS',
                    value: '${officer?.currentWorkload ?? 24}',
                    subBadge: '+3 today',
                    subBadgeColor: AppColors.danger,
                    statusText: 'High Urgency Load',
                    statusColor: AppColors.danger,
                    icon: Icons.folder_outlined,
                  ),
                  _statTile(
                    label: 'PENDING REVIEW',
                    value: '${officer?.pendingClaims ?? 8}',
                    subBadge: 'SLA < 24h',
                    subBadgeColor: AppColors.rockBlue,
                    statusText: 'Within target SLA',
                    statusColor: AppColors.textMuted,
                    icon: Icons.pending_actions_outlined,
                  ),
                  _statTile(
                    label: 'VERIFICATION',
                    value: '6',
                    subBadge: 'FIR / Triage',
                    subBadgeColor: AppColors.rockBlue,
                    statusText: 'Body Shop ready',
                    statusColor: AppColors.textMuted,
                    icon: Icons.verified_outlined,
                  ),
                  _statTile(
                    label: 'COMPLETED',
                    value: '10',
                    subBadge: 'Paid',
                    subBadgeColor: AppColors.success,
                    statusText: 'Payout cleared',
                    statusColor: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String subBadge,
    required Color subBadgeColor,
    String? statusText,
    Color? statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0616587B), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Label + Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.rockBlueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: AppColors.veniceBlue),
              ),
            ],
          ),
          // Big number in Venice Blue + Contextual SubBadge
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.veniceBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: subBadgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subBadge,
                  style: TextStyle(
                    color: subBadgeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Small supporting status
          if (statusText != null)
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: statusColor ?? AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor ?? AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuotaBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.veniceBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x2216587B), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.speed, color: AppColors.merino, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Daily Quota Progress',
                    style: TextStyle(color: AppColors.merino, fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.veniceBlueDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '78% Complete',
                  style: TextStyle(color: AppColors.rockBlue, fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '14 of 18 claims reviewed • 4 more to fulfill desk target',
            style: TextStyle(color: AppColors.merino, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.78,
              backgroundColor: AppColors.veniceBlueDark,
              color: AppColors.rockBlue,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Auto Target: 10/12', style: TextStyle(color: AppColors.rockBlue, fontSize: 11, fontWeight: FontWeight.w600)),
              Text('Casualty: 4/6', style: TextStyle(color: AppColors.rockBlue, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesSection(FirestoreService fs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF84B3CE), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x0C16587B), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16587B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF16587B), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Underwritten Policies',
                      style: TextStyle(
                        color: Color(0xFF16587B),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ACTIVE PORTFOLIO & CONTRACTS',
                      style: TextStyle(
                        color: Color(0xFF5F7480),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF16587B),
                  backgroundColor: const Color(0xFF84B3CE).withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showOfficerIssuePolicyModal(context),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Issue Policy', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<PolicyModel>>(
            stream: fs.getAllPolicies(),
            builder: (ctx, snap) {
              final policies = snap.data ?? [];
              if (policies.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No active policies in portfolio.', style: TextStyle(fontSize: 12, color: Color(0xFF5F7480))),
                );
              }

              return SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: policies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final p = policies[i];
                    return Container(
                      width: 230,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EEDD).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF84B3CE).withValues(alpha: 0.7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.policyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF16587B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E8B57).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF2E8B57),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '#${p.policyNumber}',
                            style: const TextStyle(
                              color: Color(0xFF5F7480),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Divider(height: 8, color: Color(0xFFD6E2EA)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Coverage', style: TextStyle(color: Color(0xFF5F7480), fontSize: 10)),
                                  Text(
                                    '₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(p.totalCoverage)}',
                                    style: const TextStyle(
                                      color: Color(0xFF16587B),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Premium', style: TextStyle(color: Color(0xFF5F7480), fontSize: 10)),
                                  Text(
                                    '₹${p.monthlyPremium.toStringAsFixed(0)}/mo',
                                    style: const TextStyle(
                                      color: Color(0xFF16587B),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOfficerIssuePolicyModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Commercial Fleet Policy');
    final coverageCtrl = TextEditingController(text: '250000');
    final premiumCtrl = TextEditingController(text: '185.00');
    final deductibleCtrl = TextEditingController(text: '500');
    String selectedType = 'Auto';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF5EEDD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF84B3CE).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Underwrite New Policy',
                style: TextStyle(
                  color: Color(0xFF16587B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Issue policy into portfolio for underwriting inspection',
                style: TextStyle(color: Color(0xFF5F7480), fontSize: 12.5),
              ),
              const SizedBox(height: 18),

              // Policy Type
              const Text(
                'Policy Type',
                style: TextStyle(color: Color(0xFF16587B), fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Auto', 'Home', 'Health', 'Life'].map((type) {
                  final isSel = selectedType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF16587B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? const Color(0xFF16587B) : const Color(0xFF84B3CE),
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSel ? const Color(0xFFF5EEDD) : const Color(0xFF16587B),
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Policy Name
              const Text(
                'Policy Title',
                style: TextStyle(color: Color(0xFF16587B), fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF84B3CE)),
                ),
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF16587B), fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Coverage Amount & Monthly Premium Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Coverage (₹)',
                          style: TextStyle(color: Color(0xFF16587B), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF84B3CE)),
                          ),
                          child: TextField(
                            controller: coverageCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF16587B), fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium /mo (₹)',
                          style: TextStyle(color: Color(0xFF16587B), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF84B3CE)),
                          ),
                          child: TextField(
                            controller: premiumCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF16587B), fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Issue Policy Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16587B),
                    foregroundColor: const Color(0xFFF5EEDD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          final coverage = double.tryParse(coverageCtrl.text.replaceAll(',', '')) ?? 250000;
                          final monthly = double.tryParse(premiumCtrl.text.replaceAll(',', '')) ?? 185;
                          final deductible = double.tryParse(deductibleCtrl.text.replaceAll(',', '')) ?? 500;
                          final polNum = 'POL-${selectedType.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}';

                          final newPolicy = PolicyModel(
                            id: 'pol_${DateTime.now().millisecondsSinceEpoch}',
                            userId: 'ALL',
                            policyNumber: polNum,
                            policyName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : '$selectedType Comprehensive Shield',
                            policyType: selectedType.toLowerCase(),
                            coverageDetails: 'Full coverage terms under $selectedType Protection Scheme',
                            totalCoverage: coverage,
                            deductible: deductible,
                            annualPremium: monthly * 12,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 365)),
                            status: 'Active',
                          );

                          await FirestoreService().createPolicy(newPolicy);

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Policy #${newPolicy.policyNumber} underwritten and issued!'),
                                backgroundColor: const Color(0xFF16587B),
                              ),
                            );
                            setState(() {});
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Issue Policy',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All (24)', 'High Priority (5)', 'SLA Breaching (2)', 'Motor'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = (_filterStatus == 'All' && f.startsWith('All')) || _filterStatus == f;
          final isSLA = f.contains('SLA');

          Color bgColor;
          Color textColor;
          Color borderColor;

          if (isSelected) {
            bgColor = AppColors.veniceBlue;
            textColor = AppColors.merino;
            borderColor = AppColors.veniceBlue;
          } else if (isSLA) {
            bgColor = const Color(0xFFFEF2F2);
            textColor = const Color(0xFFDC2626);
            borderColor = const Color(0xFFFCA5A5);
          } else {
            bgColor = Colors.white;
            textColor = AppColors.textPrimary;
            borderColor = AppColors.border;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = f.startsWith('All') ? 'All' : f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _claimCard(BuildContext context, ClaimModel claim) {
    final isCritical = claim.priority == 'Critical';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => OfficerClaimDetailScreen(claimId: claim.id),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isCritical ? const Color(0xFFFCA5A5) : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: Claim ID + Submission date + Badges
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: AppColors.rockBlueLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${claim.claimNumber}',
                        style: const TextStyle(
                          color: AppColors.veniceBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Submitted Oct 24 • 2h ago',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Critical badge
                  if (isCritical)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CRITICAL',
                        style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w800, fontSize: 9.5),
                      ),
                    ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.rockBlueLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.rockBlue),
                    ),
                    child: Text(
                      claim.status,
                      style: const TextStyle(color: AppColors.veniceBlue, fontWeight: FontWeight.w700, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Inner Insured Person & Vehicle box
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6EE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE8D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.directions_car, color: AppColors.veniceBlue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim.userName,
                                style: const TextStyle(
                                  color: AppColors.veniceBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tesla Model 3 • Pol: #${claim.policyNumber}',
                                style: const TextStyle(
                                  color: AppColors.textBody,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.car_crash, size: 12, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${claim.claimType} • Bumper & Radar',
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metrics Row
                  Row(
                    children: [
                      _claimMetric('CLAIM AMT', '₹${claim.claimAmount.toStringAsFixed(2)}'),
                      _claimMetric('RESERVE', '₹${(claim.reservedValue ?? (claim.claimAmount * 1.2)).toStringAsFixed(2)}'),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SLA WINDOW',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFDC2626)),
                                const SizedBox(width: 3),
                                Text(
                                  isCritical ? '4h left' : '24h left',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // High-Contrast Action Buttons
                  Row(
                    children: [
                      // Review File Button
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => OfficerClaimDetailScreen(claimId: claim.id),
                          )),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.rockBlue),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.folder_open_outlined, size: 15, color: AppColors.veniceBlue),
                                SizedBox(width: 6),
                                Text(
                                  'Review File',
                                  style: TextStyle(
                                    color: AppColors.veniceBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Quick Verify Button (Venice Blue)
                      Expanded(
                        child: InkWell(
                          onTap: () => _quickAction(context, claim),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.veniceBlue,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.veniceBlue.withValues(alpha: 0.30),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  claim.status == AppConstants.statusUnderVerification
                                      ? Icons.verified_outlined
                                      : Icons.check_circle_outlined,
                                  size: 15,
                                  color: AppColors.merino,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  claim.status == AppConstants.statusUnderVerification ? 'Quick Verify' : 'Approve',
                                  style: const TextStyle(
                                    color: AppColors.merino,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.veniceBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _quickAction(BuildContext context, ClaimModel claim) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => OfficerClaimDetailScreen(claimId: claim.id)));
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.assignment_outlined, 'label': 'Claims'},
      {'icon': Icons.verified_outlined, 'label': 'Verification'},
      {'icon': Icons.notifications_outlined, 'label': 'Alerts'},
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
            children: List.generate(items.length, (i) {
              final isActive = _navIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _navIndex = i);
                  OfficerShell.switchTab(context, i);
                },
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
                          items[i]['icon'] as IconData,
                          size: 21,
                          color: isActive ? InsureXColors.veniceBlue : InsureXColors.rockBlue,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i]['label'] as String,
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
