import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/models/policy_model.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'customer_new_claim_screen.dart';
import 'customer_claim_detail_screen.dart';

class CustomerPolicyDetailScreen extends StatelessWidget {
  final PolicyModel? policy;
  const CustomerPolicyDetailScreen({super.key, this.policy});

  String _formatCoverage(double coverage, String policyNum) {
    if (policyNum == 'POL-HOME-4412') return '₹5,50,000';
    if (policyNum == 'POL-AUTO-8821') return '₹75,000';
    if (policyNum == 'POL-HEALTH-2307') return '₹10,00,000';
    if (policyNum == 'POL-TRAVEL-5198') return '₹5,00,000';
    if (policyNum == 'POL-PA-6734') return '₹7,50,000';
    if (policyNum == 'POL-HOME-3381') return '₹3,50,000';
    final formatter = NumberFormat('#,##,###');
    return '₹${formatter.format(coverage.toInt())}';
  }

  String _formatPremium(double premium, String policyNum) {
    if (policyNum == 'POL-HOME-4412') return '₹81.67 /mo';
    if (policyNum == 'POL-AUTO-8821') return '₹118.33 /mo';
    if (policyNum == 'POL-HEALTH-2307') return '₹1,250 /mo';
    if (policyNum == 'POL-TRAVEL-5198') return '₹450 /mo';
    if (policyNum == 'POL-PA-6734') return '₹325 /mo';
    if (policyNum == 'POL-HOME-3381') return '₹106.67 /mo';
    return premium % 1 == 0
        ? '₹${premium.toInt()} /mo'
        : '₹${premium.toStringAsFixed(2)} /mo';
  }

  IconData _getPolicyIcon(String type, String name) {
    final t = type.toLowerCase();
    final n = name.toLowerCase();
    if (t.contains('personal') || n.contains('personal') || n.contains('accident')) {
      return Icons.personal_injury;
    }
    if (t.contains('home') || n.contains('home')) {
      return Icons.home;
    }
    if (t.contains('auto') || t.contains('vehicle') || n.contains('auto')) {
      return Icons.directions_car;
    }
    if (t.contains('health') || n.contains('health')) {
      return Icons.health_and_safety;
    }
    if (t.contains('travel') || n.contains('travel')) {
      return Icons.flight;
    }
    return Icons.shield_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final effectivePolicy = policy ??
        PolicyModel(
          id: 'POL-AUTO-8821',
          userId: 'usr_customer_demo',
          policyNumber: 'POL-AUTO-8821',
          policyName: 'Comprehensive Auto Cover',
          policyType: 'Auto Insurance',
          coverageDetails: 'Complete damage, collision & personal liability cover',
          totalCoverage: 75000,
          deductible: 5000,
          annualPremium: 1420,
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2026, 1, 1),
          status: 'Active',
          isActive: true,
        );

    final policyNumber = effectivePolicy.policyNumber.isNotEmpty
        ? effectivePolicy.policyNumber
        : effectivePolicy.id;
    final policyName = effectivePolicy.policyName.isNotEmpty
        ? effectivePolicy.policyName
        : 'Comprehensive Protection';
    final policyType = effectivePolicy.policyType.isNotEmpty
        ? effectivePolicy.policyType
        : 'Insurance Policy';

    final isExpired = effectivePolicy.status.toLowerCase() == 'expired' ||
        effectivePolicy.isExpired;
    final statusColor = isExpired ? const Color(0xFFB54747) : const Color(0xFF2E8B57);
    final statusLabel = isExpired ? 'Expired' : 'Active';

    final coverageStr = _formatCoverage(effectivePolicy.totalCoverage, policyNumber);
    final premiumStr = _formatPremium(effectivePolicy.monthlyPremium, policyNumber);
    final policyIcon = _getPolicyIcon(policyType, policyName);

    final dateFormat = DateFormat('dd MMM yyyy');
    final validityPeriod =
        '${dateFormat.format(effectivePolicy.startDate)} – ${dateFormat.format(effectivePolicy.endDate)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEADBCE)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: InsureXColors.veniceBlue,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Policy Details',
          style: TextStyle(
            color: InsureXColors.veniceBlue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // HERO POLICY CARD
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: InsureXColors.veniceBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: InsureXColors.rockBlue.withValues(alpha: 0.35),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2216587B),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              policyType.toUpperCase(),
                              style: TextStyle(
                                color: InsureXColors.rockBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              policyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? const Color(0xFFB54747).withValues(alpha: 0.25)
                              : const Color(0xFF2E8B57).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpired
                                ? const Color(0xFFFF8A80)
                                : const Color(0xFF81C784),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpired
                                  ? Icons.cancel_rounded
                                  : Icons.check_circle_rounded,
                              size: 13,
                              color: isExpired
                                  ? const Color(0xFFFF8A80)
                                  : const Color(0xFF81C784),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: isExpired
                                    ? const Color(0xFFFF8A80)
                                    : const Color(0xFF81C784),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Policy ID: $policyNumber',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hero Graphic Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Icon(
                            policyIcon,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                policyIcon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coverageStr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total Guaranteed Coverage',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    premiumStr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 10,
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // POLICY OVERVIEW CARD
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEADBCE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A16587B),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: InsureXColors.veniceBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.article_outlined,
                          size: 18,
                          color: InsureXColors.veniceBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Policy Overview',
                        style: TextStyle(
                          color: InsureXColors.veniceBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _row('Policy Name', policyName),
                  _divider(),
                  _row('Policy ID', policyNumber),
                  _divider(),
                  _row('Policy Type', policyType),
                  _divider(),
                  _row(
                    'Status',
                    statusLabel,
                    valueColor: statusColor,
                    isBold: true,
                  ),
                  _divider(),
                  _row('Coverage Amount', coverageStr, isBold: true),
                  _divider(),
                  _row('Monthly Premium', premiumStr),
                  _divider(),
                  _row('Deductible', '₹5,000'),
                  _divider(),
                  _row('Validity Period', validityPeriod),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // CLAIMS ASSOCIATED WITH THIS POLICY
            // ==========================================
            _buildAssociatedClaimsSection(context, effectivePolicy),
            const SizedBox(height: 24),

            // ==========================================
            // ACTION BUTTON: FILE CLAIM OR CLAIM UNAVAILABLE
            // ==========================================
            if (!isExpired)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'File a Claim Under This Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InsureXColors.veniceBlue,
                    elevation: 3,
                    shadowColor: InsureXColors.veniceBlue.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerNewClaimScreen(
                          initialPolicy: effectivePolicy,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2DBD0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB54747).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        size: 20,
                        color: Color(0xFFB54747),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Claim Unavailable',
                            style: TextStyle(
                              color: Color(0xFF7A7062),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'This policy has expired. New claims cannot be filed.',
                            style: TextStyle(
                              color: Color(0xFF9E9485),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Secondary Buttons: View ID Card & Download Document
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: InsureXColors.veniceBlue,
                      ),
                      label: const Text(
                        'View ID Card',
                        style: TextStyle(
                          color: InsureXColors.veniceBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAF6EE),
                        side: const BorderSide(
                          color: Color(0xFFEADBCE),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showIdCardSheet(
                        context,
                        effectivePolicy,
                        coverageStr,
                        validityPeriod,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.file_download_outlined,
                        size: 16,
                        color: InsureXColors.veniceBlue,
                      ),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(
                          color: InsureXColors.veniceBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAF6EE),
                        side: const BorderSide(
                          color: Color(0xFFEADBCE),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Downloading policy document #$policyNumber...',
                            ),
                            backgroundColor: InsureXColors.veniceBlue,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CLAIMS STREAM BUILDER SECTION
  // ==========================================
  Widget _buildAssociatedClaimsSection(BuildContext context, PolicyModel policy) {
    final policyNum = policy.policyNumber;
    final policyId = policy.id;

    return StreamBuilder<List<ClaimModel>>(
      stream: FirestoreService().getAllClaims(),
      builder: (context, snapshot) {
        final allClaims = snapshot.data ?? [];
        final associatedClaims = allClaims.where((c) {
          final pId = c.policyId.trim().toUpperCase();
          final pNum = c.policyNumber.trim().toUpperCase();
          final targetNum = policyNum.trim().toUpperCase();
          final targetId = policyId.trim().toUpperCase();
          return pId == targetNum ||
              pId == targetId ||
              pNum == targetNum ||
              pNum == targetId;
        }).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6EE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEADBCE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A16587B),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: InsureXColors.veniceBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history_edu_outlined,
                          size: 18,
                          color: InsureXColors.veniceBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Associated Claims',
                        style: TextStyle(
                          color: InsureXColors.veniceBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: InsureXColors.veniceBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${associatedClaims.length}',
                      style: const TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (associatedClaims.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 20,
                          color: InsureXColors.rockBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No claims filed for this policy',
                              style: TextStyle(
                                color: InsureXColors.veniceBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              policy.isExpired ||
                                      policy.status.toLowerCase() == 'expired'
                                  ? 'No previous claims were recorded under this expired policy.'
                                  : 'Your coverage is currently active and in good standing.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: associatedClaims.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final claim = associatedClaims[idx];
                    final isClaimApproved =
                        claim.status.toLowerCase().contains('approv');
                    final isClaimRejected =
                        claim.status.toLowerCase().contains('reject');
                    final Color badgeColor = isClaimApproved
                        ? const Color(0xFF2E8B57)
                        : (isClaimRejected
                            ? const Color(0xFFB54747)
                            : const Color(0xFFC98A00));

                    final claimDate =
                        DateFormat('dd MMM yyyy').format(claim.createdAt);
                    final formatter = NumberFormat('#,##,###');
                    final amountFormatted =
                        '₹${formatter.format(claim.claimAmount.toInt())}';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerClaimDetailScreen(claimId: claim.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEADBCE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: badgeColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        claim.claimNumber,
                                        style: const TextStyle(
                                          color: InsureXColors.veniceBlue,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          claim.status.toUpperCase(),
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    claim.claimType.isNotEmpty
                                        ? claim.claimType
                                        : 'Insurance Claim',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        claimDate,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        amountFormatted,
                                        style: const TextStyle(
                                          color: InsureXColors.veniceBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: InsureXColors.rockBlue,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(color: Color(0xFFEADBCE), height: 1, thickness: 1);

  void _showIdCardSheet(
    BuildContext context,
    PolicyModel policy,
    String coverage,
    String validity,
  ) {
    final isExpired =
        policy.status.toLowerCase() == 'expired' || policy.isExpired;
    final icon = _getPolicyIcon(policy.policyType, policy.policyName);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: InsureXColors.veniceBlue,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2216587B),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'INSUREX DIGITAL ID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isExpired
                                  ? const Color(0xFFFF8A80)
                                  : const Color(0xFF81C784))
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : 'ACTIVE',
                          style: TextStyle(
                            color: isExpired
                                ? const Color(0xFFFF8A80)
                                : const Color(0xFF81C784),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    policy.policyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Policy # ${policy.policyNumber}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COVERAGE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            coverage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'VALIDITY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            validity,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: InsureXColors.veniceBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
