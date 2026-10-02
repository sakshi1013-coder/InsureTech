import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/models/user_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'admin_assign_officer_screen.dart';
import 'admin_audit_logs_screen.dart';
import '../../auth/screens/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  final List<Widget> _sections = [
    const _AdminOverviewSection(),
    const _AdminClaimsSection(),
    const _AdminOfficersSection(),
    const _AdminAnalyticsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: InsureXColors.veniceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('InsureX Admin', style: AppTextStyles.headlineSmall.copyWith(fontSize: 14)),
                Text('Control Centre', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF0F6F9), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: () async {
              await auth.signOut();
              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFF9E8E8), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.logout_outlined, size: 18, color: AppColors.danger),
            ),
          ),
        ],
      ),
      body: _sections[_navIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_outlined, 'label': 'Overview'},
      {'icon': Icons.assignment_outlined, 'label': 'Claims'},
      {'icon': Icons.badge_outlined, 'label': 'Officers'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Analytics'},
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
                onTap: () => setState(() => _navIndex = i),
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

class _AdminOverviewSection extends StatelessWidget {
  const _AdminOverviewSection();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<ClaimModel>>(
      stream: fs.getAllClaims(),
      builder: (ctx, snap) {
        final claims = snap.data ?? [];
        final total = claims.length;
        final pending = claims.where((c) => [AppConstants.statusSubmitted, AppConstants.statusUnderVerification, AppConstants.statusUnderReview].contains(c.status)).length;
        final approved = claims.where((c) => c.status == AppConstants.statusApproved || c.status == AppConstants.statusCompleted).length;
        final rejected = claims.where((c) => c.status == AppConstants.statusRejected).length;

        return StreamBuilder<List<OfficerModel>>(
          stream: fs.getOfficers(),
          builder: (ctx2, officerSnap) {
            final officers = officerSnap.data ?? [];
            final activeOfficers = officers.where((o) => o.isOnDuty).length;

            return StreamBuilder<List<UserModel>>(
              stream: fs.getCustomers(),
              builder: (ctx3, custSnap) {
                final customers = custSnap.data?.length ?? 0;
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Stats grid
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.5,
                            children: [
                              StatCard(value: '$total', label: 'Total Claims', icon: Icons.assignment_outlined, color: AppColors.primary, cardColor: const Color(0xFFFAF6EE)),
                              StatCard(value: '$pending', label: 'Pending Claims', icon: Icons.pending_outlined, color: AppColors.warning, change: '+3 today', changePositive: false, cardColor: const Color(0xFFFAF6EE)),
                              StatCard(value: '$approved', label: 'Approved', icon: Icons.check_circle_outlined, color: AppColors.success, change: '↑12%', cardColor: const Color(0xFFFAF6EE)),
                              StatCard(value: '$rejected', label: 'Rejected', icon: Icons.cancel_outlined, color: AppColors.danger, cardColor: const Color(0xFFFAF6EE)),
                              StatCard(value: '$customers', label: 'Customers', icon: Icons.people_outlined, color: AppColors.info, cardColor: const Color(0xFFFAF6EE)),
                              StatCard(value: '$activeOfficers', label: 'Active Officers', icon: Icons.badge_outlined, color: AppColors.purple, cardColor: const Color(0xFFFAF6EE)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Recent claims requiring action
                          SectionHeader(
                            title: 'Claims Requiring Action',
                            action: 'View All',
                          ),
                          const SizedBox(height: 12),
                          ...claims.where((c) => c.status == AppConstants.statusSubmitted).take(3).map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _adminClaimRow(context, c, fs),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Audit log
                          SectionHeader(title: 'Recent Activity', action: 'Full Log', onAction: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const AdminAuditLogsScreen()),
                          )),
                          const SizedBox(height: 12),
                          StreamBuilder<List<AuditLogModel>>(
                            stream: fs.getAuditLogs(),
                            builder: (ctx4, logSnap) {
                              final logs = logSnap.data?.take(4).toList() ?? [];
                              return Column(
                                children: logs.map((l) => _logTile(l)).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _adminClaimRow(BuildContext context, ClaimModel c, FirestoreService fs) {
    return AppCard(
      color: const Color(0xFFFAF6EE),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${c.claimNumber}', style: AppTextStyles.monospace.copyWith(fontSize: 11)),
                Text('${c.userName} • ${c.claimType}', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                Text('₹${NumberFormat('#,##0.00').format(c.claimAmount)}', style: AppTextStyles.labelLarge.copyWith(fontSize: 12, color: AppColors.success)),
              ],
            ),
          ),
          Column(
            children: [
              AppStatusBadge(status: c.status, compact: true),
              const SizedBox(height: 6),
              if (c.officerId == null)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AdminAssignOfficerScreen(claimId: c.id, claimNumber: c.claimNumber),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Assign Officer', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 9)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logTile(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.history, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.description.length > 60 ? '${log.description.substring(0, 60)}...' : log.description,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                Text('${log.userName} • ${DateFormat('MMM dd, HH:mm').format(log.timestamp)}',
                    style: AppTextStyles.caption.copyWith(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminClaimsSection extends StatelessWidget {
  const _AdminClaimsSection();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<ClaimModel>>(
      stream: fs.getAllClaims(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        final claims = (snap.data ?? []).toList();
        claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (claims.isEmpty) return const EmptyState(icon: Icons.assignment_outlined, title: 'No Claims', subtitle: 'No claims in the system yet.');
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: claims.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _claimRow(context, claims[i], fs),
        );
      },
    );
  }

  Widget _claimRow(BuildContext context, ClaimModel c, FirestoreService fs) {
    return AppCard(
      color: const Color(0xFFFAF6EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${c.claimNumber}', style: AppTextStyles.monospace.copyWith(fontSize: 11)),
              const SizedBox(width: 8),
              PriorityBadge(priority: c.priority),
              const Spacer(),
              AppStatusBadge(status: c.status, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.userName, style: AppTextStyles.headlineSmall.copyWith(fontSize: 13)),
          Text('${c.claimType} • ₹${NumberFormat('#,##0.00').format(c.claimAmount)}', style: AppTextStyles.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.officerName != null ? 'Officer: ${c.officerName}' : '⚠ Unassigned', style: AppTextStyles.caption.copyWith(
                color: c.officerName != null ? AppColors.success : AppColors.warning, fontSize: 10,
              )),
              if (c.officerId == null)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AdminAssignOfficerScreen(claimId: c.id, claimNumber: c.claimNumber),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(6)),
                    child: Text('Assign Officer', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 9)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminOfficersSection extends StatelessWidget {
  const _AdminOfficersSection();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<OfficerModel>>(
      stream: fs.getOfficers(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        final officers = snap.data ?? [];
        if (officers.isEmpty) return const EmptyState(icon: Icons.badge_outlined, title: 'No Officers', subtitle: 'No officers registered yet.');
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: officers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _officerCard(officers[i]),
        );
      },
    );
  }

  Widget _officerCard(OfficerModel o) {
    return AppCard(
      color: const Color(0xFFFAF6EE),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(o.initials, style: AppTextStyles.headlineLarge.copyWith(color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(o.name, style: AppTextStyles.headlineSmall),
                    const SizedBox(width: 8),
                    Text('#${o.employeeId}', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontSize: 10)),
                  ],
                ),
                Text(o.designation, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                Text(o.department, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge('${o.currentWorkload} Active', AppColors.warning),
                    const SizedBox(width: 6),
                    _badge(o.isOnDuty ? 'On Duty' : 'Off Duty', o.isOnDuty ? AppColors.success : AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color, fontSize: 9)),
    );
  }
}

class _AdminAnalyticsSection extends StatelessWidget {
  const _AdminAnalyticsSection();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<ClaimModel>>(
      stream: fs.getAllClaims(),
      builder: (ctx, snap) {
        final claims = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: AppTextStyles.displaySmall),
              Text('Real-time claim insights', style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),

              // Pie chart - Status distribution
              AppCard(
                color: const Color(0xFFFAF6EE),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Claims by Status', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildPieChart(claims),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bar chart - Claims by type
              AppCard(
                color: const Color(0xFFFAF6EE),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Claims by Type', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _buildBarChart(claims),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI metrics
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    value: '₹${_totalAmount(claims)}',
                    label: 'Total Claim Value',
                    icon: Icons.monetization_on_outlined,
                    color: AppColors.success,
                    cardColor: const Color(0xFFFAF6EE),
                  ),
                  StatCard(
                    value: '${_avgProcessing(claims)}d',
                    label: 'Avg Processing Time',
                    icon: Icons.timer_outlined,
                    color: AppColors.warning,
                    cardColor: const Color(0xFFFAF6EE),
                  ),
                  StatCard(
                    value: '${_approvalRate(claims)}%',
                    label: 'Approval Rate',
                    icon: Icons.trending_up_outlined,
                    color: AppColors.primary,
                    cardColor: const Color(0xFFFAF6EE),
                  ),
                  StatCard(
                    value: '${claims.length}',
                    label: 'Total Claims',
                    icon: Icons.assignment_outlined,
                    color: AppColors.info,
                    cardColor: const Color(0xFFFAF6EE),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _totalAmount(List<ClaimModel> claims) {
    final total = claims.fold<double>(0, (sum, c) => sum + c.claimAmount);
    if (total >= 1000) return NumberFormat('#,##0').format(total / 1000) + 'k';
    return NumberFormat('#,##0').format(total);
  }

  String _avgProcessing(List<ClaimModel> claims) {
    if (claims.isEmpty) return '0';
    final avg = claims.fold<int>(0, (sum, c) => sum + c.updatedAt.difference(c.createdAt).inDays) ~/ claims.length;
    return avg.toString();
  }

  String _approvalRate(List<ClaimModel> claims) {
    if (claims.isEmpty) return '0';
    final approved = claims.where((c) => c.status == AppConstants.statusApproved || c.status == AppConstants.statusCompleted).length;
    return ((approved / claims.length) * 100).toStringAsFixed(0);
  }

  Widget _buildPieChart(List<ClaimModel> claims) {
    final statusMap = <String, int>{};
    for (final c in claims) {
      statusMap[c.status] = (statusMap[c.status] ?? 0) + 1;
    }
    if (statusMap.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted)));
    }

    final colors = [AppColors.primary, AppColors.warning, AppColors.success, AppColors.danger, AppColors.info, AppColors.purple];
    final sections = statusMap.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: e.value.toDouble(),
        title: '${e.value}',
        radius: 46,
        titleStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontSize: 11),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 36,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: statusMap.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.key, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<ClaimModel> claims) {
    final typeMap = <String, int>{};
    for (final c in claims) {
      typeMap[c.claimType] = (typeMap[c.claimType] ?? 0) + 1;
    }
    if (typeMap.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted)));
    }

    final entries = typeMap.entries.toList();
    return BarChart(BarChartData(
      barGroups: List.generate(entries.length, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entries[i].value.toDouble(),
            color: AppColors.primary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      )),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i >= 0 && i < entries.length) {
                final parts = entries[i].key.split(' ');
                return Text(parts.first, style: AppTextStyles.caption.copyWith(fontSize: 8));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
          getTitlesWidget: (v, _) => Text('${v.toInt()}', style: AppTextStyles.caption.copyWith(fontSize: 9)),
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      backgroundColor: Colors.transparent,
    ));
  }
}
