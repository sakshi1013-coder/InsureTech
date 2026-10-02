import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'customer_claim_detail_screen.dart';
import 'customer_new_claim_screen.dart';
import 'customer_profile_screen.dart';

class CustomerClaimsScreen extends StatefulWidget {
  const CustomerClaimsScreen({super.key});

  @override
  State<CustomerClaimsScreen> createState() => _CustomerClaimsScreenState();
}

class _CustomerClaimsScreenState extends State<CustomerClaimsScreen> {
  int _filterIndex = 0;
  final List<String> _filters = ['All', 'Active', 'Approved', 'Rejected'];

  List<ClaimModel> _filter(List<ClaimModel> all, int idx) {
    switch (idx) {
      case 1:
        return all.where((c) => [
          AppConstants.statusSubmitted,
          AppConstants.statusUnderVerification,
          AppConstants.statusUnderReview,
          'in_progress',
          'In Progress',
        ].contains(c.status)).toList();
      case 2:
        return all.where((c) => c.status == AppConstants.statusApproved || c.status == AppConstants.statusCompleted).toList();
      case 3:
        return all.where((c) => c.status == AppConstants.statusRejected).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 68,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                );
              },
              child: Tooltip(
                message: 'View Profile',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: InsureXColors.veniceBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: InsureXColors.veniceBlue.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'My Claims',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerNewClaimScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: InsureXColors.veniceBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: InsureXColors.veniceBlue.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'File Claim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ClaimModel>>(
        stream: fs.getClaimsForUser(user.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          final all = (snap.data ?? []).toList();
          all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No Claims Yet',
              subtitle: 'Submit your first insurance claim to get started with instant verification.',
              actionLabel: 'File a Claim',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerNewClaimScreen()),
              ),
            );
          }

          final filtered = _filter(all, _filterIndex);

          return Column(
            children: [
              // Filter pills
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final active = _filterIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? InsureXColors.veniceBlue : const Color(0xFFFAF6EE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? InsureXColors.veniceBlue : const Color(0xFFEADBCE)),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: InsureXColors.veniceBlue.withValues(alpha: 0.20),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _filters[i],
                            style: TextStyle(
                              color: active ? InsureXColors.merino : const Color(0xFF5F7480),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No Claims Found',
                        subtitle: 'No claims match your selected filter.',
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _claimCard(context, filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _claimCard(BuildContext context, ClaimModel claim) {
    final progress = claim.totalSteps > 0 ? (claim.currentStep / claim.totalSteps).clamp(0.0, 1.0) : 0.6;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerClaimDetailScreen(claimId: claim.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5EDF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0816587B),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Claim Number on Left, Approved/Status Badge on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  claim.claimNumber,
                  style: const TextStyle(
                    color: Color(0xFF5F7480),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: claim.status.toLowerCase().contains('approved') || claim.status.toLowerCase().contains('complete')
                        ? const Color(0xFFE8F6EF)
                        : const Color(0xFFE8F2F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: claim.status.toLowerCase().contains('approved') || claim.status.toLowerCase().contains('complete')
                          ? const Color(0xFFA7E2C3)
                          : const Color(0xFFB5DEF4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: claim.status.toLowerCase().contains('approved') || claim.status.toLowerCase().contains('complete')
                              ? InsureXColors.success
                              : InsureXColors.veniceBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        claim.status,
                        style: TextStyle(
                          color: claim.status.toLowerCase().contains('approved') || claim.status.toLowerCase().contains('complete')
                              ? InsureXColors.success
                              : InsureXColors.veniceBlue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle Row: Incident Type on Left, Claim Amount on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.incidentType.isNotEmpty ? claim.incidentType : claim.claimType,
                      style: const TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('MMM dd, yyyy').format(claim.incidentDate),
                      style: const TextStyle(
                        color: Color(0xFF8B9FA8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(claim.claimAmount),
                  style: const TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stage ${claim.currentStep} of ${claim.totalSteps}',
                  style: const TextStyle(
                    color: Color(0xFF5F7480),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: const TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(width: double.infinity, color: InsureXColors.rockBlue.withValues(alpha: 0.25)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: InsureXColors.veniceBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Track Claim Status Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Track Claim Status',
                    style: TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: InsureXColors.veniceBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
