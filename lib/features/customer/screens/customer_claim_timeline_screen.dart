import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';

class CustomerClaimTimelineScreen extends StatelessWidget {
  final String claimId;
  const CustomerClaimTimelineScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Claim Timeline',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<ClaimModel?>(
        future: fs.getClaimById(claimId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          final claim = snap.data;
          if (claim == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Claim Not Found',
              subtitle: 'Timeline milestones could not be loaded.',
            );
          }
          return _buildTimelineContent(context, claim);
        },
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, ClaimModel claim) {
    final stages = [
      {'title': 'Claim Reported', 'time': 'May 20, 2025 · 10:15 AM', 'state': 'completed'},
      {'title': 'Information Received', 'time': 'May 20, 2025 · 11:30 AM', 'state': 'completed'},
      {'title': 'Under Review', 'time': 'May 21, 2025 · In Progress', 'state': 'current'},
      {'title': 'Estimate Approval', 'time': 'Pending assessment', 'state': 'pending'},
      {'title': 'Settlement', 'time': 'Expected within 3-5 days', 'state': 'pending'},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08171A2B),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      claim.claimNumber,
                      style: const TextStyle(
                        color: AppColors.brightBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppStatusBadge(status: claim.status, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  claim.incidentType.isNotEmpty ? claim.incidentType : claim.claimType,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated Payout', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(claim.claimAmount),
                              style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Est. Resolution', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            SizedBox(height: 2),
                            Text(
                              '3-5 Days',
                              style: TextStyle(color: AppColors.brightBlue, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Timeline Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08171A2B),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Milestone Progress',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Column(
                  children: List.generate(stages.length, (i) {
                    final stage = stages[i];
                    final isLast = i == stages.length - 1;
                    final state = stage['state'];

                    Color dotColor;
                    Color lineColor = const Color(0xFFE2E8F0);
                    Widget dotChild = const SizedBox.shrink();

                    if (state == 'completed') {
                      dotColor = AppColors.brightBlue;
                      lineColor = AppColors.brightBlue;
                      dotChild = const Icon(Icons.check, size: 12, color: Colors.white);
                    } else if (state == 'current') {
                      dotColor = AppColors.purple;
                      dotChild = Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      );
                    } else {
                      dotColor = const Color(0xFFCBD5E1);
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                                boxShadow: state == 'current'
                                    ? [
                                        BoxShadow(
                                          color: AppColors.purple.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(child: dotChild),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 42,
                                color: lineColor,
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage['title']!,
                                  style: TextStyle(
                                    color: state == 'pending'
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: state == 'current'
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stage['time']!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
