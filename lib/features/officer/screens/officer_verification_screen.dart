import 'package:flutter/material.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'officer_claim_detail_screen.dart';
import 'officer_profile_screen.dart';

class OfficerVerificationScreen extends StatefulWidget {
  const OfficerVerificationScreen({super.key});

  @override
  State<OfficerVerificationScreen> createState() => _OfficerVerificationScreenState();
}

class _OfficerVerificationScreenState extends State<OfficerVerificationScreen> {
  String _selectedTab = 'All';
  final List<String> _tabs = [
    'All',
    'Pending Verification',
    'Documents',
    'Evidence',
    'FIR / Triage',
  ];

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle ambient light elements
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF84B3CE).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF84B3CE).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Floating Header
                _buildFloatingHeader(),

                // Filter Tabs
                _buildTabs(),

                // Verification Items List
                Expanded(
                  child: StreamBuilder<List<ClaimModel>>(
                    stream: fs.getAllClaims(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF16587B)),
                        );
                      }

                      var claims = (snapshot.data ?? []).toList();
                      if (claims.isEmpty) {
                        claims = _getVerificationItems();
                      }
                      claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      // Filter by tab
                      if (_selectedTab == 'Pending Verification') {
                        claims = claims
                            .where((c) =>
                                c.status == AppConstants.statusUnderVerification ||
                                c.status == AppConstants.statusUnderReview)
                            .toList();
                      } else if (_selectedTab == 'Documents') {
                        claims = claims
                            .where((c) =>
                                c.claimType.toLowerCase().contains('collision') ||
                                c.claimType.toLowerCase().contains('property') ||
                                c.claimType.toLowerCase().contains('auto'))
                            .toList();
                      } else if (_selectedTab == 'Evidence') {
                        claims = claims
                            .where((c) => c.priority == 'Critical' || c.priority == 'High')
                            .toList();
                      } else if (_selectedTab == 'FIR / Triage') {
                        claims = claims
                            .where((c) =>
                                c.claimType.toLowerCase().contains('collision') ||
                                c.priority == 'Critical')
                            .toList();
                      }

                      if (claims.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: EmptyState(
                            icon: Icons.verified_outlined,
                            title: 'No Pending Verifications',
                            subtitle: 'All items in "$_selectedTab" have been reviewed.',
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _buildAnimatedVerificationCard(context, claims[i], i),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF84B3CE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C16587B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF16587B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: Color(0xFF16587B),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Verification Queue',
                style: TextStyle(
                  color: Color(0xFF16587B),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'FORENSIC EVIDENCE & DAMAGE TRIAGE',
                style: TextStyle(
                  color: Color(0xFF5F7480),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF16587B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF84B3CE).withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF16587B)),
                SizedBox(width: 4),
                Text(
                  'COMPLIANCE',
                  style: TextStyle(
                    color: Color(0xFF16587B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF16587B),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'MV',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _tabs.map((tab) {
            final isSelected = _selectedTab == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF16587B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF16587B) : const Color(0xFF84B3CE),
                      width: 1.1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF16587B).withValues(alpha: 0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFF5EEDD) : const Color(0xFF16587B),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedVerificationCard(BuildContext context, ClaimModel claim, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 320 + (index * 60).clamp(0, 400)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, (1 - val) * 20),
            child: child,
          ),
        );
      },
      child: _OfficerVerificationCard(claim: claim),
    );
  }

  List<ClaimModel> _getVerificationItems() {
    final now = DateTime.now();
    return [
      ClaimModel(
        id: 'clm_1',
        claimNumber: 'CLM-2024-4576',
        userId: 'usr_1',
        userEmail: 'alex.johnson@gmail.com',
        userName: 'Alex Johnson',
        policyId: 'pol_1',
        policyNumber: 'POL-AUTO-8821',
        claimType: 'Vehicle Collision',
        incidentDate: now.subtract(const Duration(days: 3)),
        incidentLocation: 'Oakland Blvd & 4th Ave, CA',
        description: 'Multi-vehicle collision at intersection.',
        estimatedDamage: 4500.0,
        claimAmount: 3800.0,
        status: AppConstants.statusUnderVerification,
        priority: 'Critical',
        createdAt: now.subtract(const Duration(hours: 14)),
        updatedAt: now,
        isFnolSubmitted: true,
      ),
      ClaimModel(
        id: 'clm_2',
        claimNumber: 'CLM-2024-3901',
        userId: 'usr_2',
        userEmail: 'sarah.miller@gmail.com',
        userName: 'Sarah Miller',
        policyId: 'pol_2',
        policyNumber: 'POL-HOME-4412',
        claimType: 'Property Water Damage',
        incidentDate: now.subtract(const Duration(days: 5)),
        incidentLocation: '742 Evergreen Terrace, Springfield',
        description: 'Pipe burst in second-floor bathroom.',
        estimatedDamage: 6200.0,
        claimAmount: 5100.0,
        status: AppConstants.statusUnderVerification,
        priority: 'High',
        createdAt: now.subtract(const Duration(hours: 32)),
        updatedAt: now,
        isFnolSubmitted: false,
      ),
      ClaimModel(
        id: 'clm_3',
        claimNumber: 'CLM-2024-5120',
        userId: 'usr_3',
        userEmail: 'david.chen@gmail.com',
        userName: 'David Chen',
        policyId: 'pol_3',
        policyNumber: 'POL-AUTO-9104',
        claimType: 'Windshield & Hail Damage',
        incidentDate: now.subtract(const Duration(days: 1)),
        incidentLocation: 'Northway Mall Parking, Sector 9',
        description: 'Severe hailstorm shattered rear passenger window.',
        estimatedDamage: 1850.0,
        claimAmount: 1850.0,
        status: AppConstants.statusUnderReview,
        priority: 'Medium',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
        isFnolSubmitted: true,
      ),
    ];
  }
}

class _OfficerVerificationCard extends StatefulWidget {
  final ClaimModel claim;
  const _OfficerVerificationCard({required this.claim});

  @override
  State<_OfficerVerificationCard> createState() => _OfficerVerificationCardState();
}

class _OfficerVerificationCardState extends State<_OfficerVerificationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final docStatus = claim.isFnolSubmitted ? 'FNOL & Police Report Attached' : '2 Documents Pending Verification';
    final evidenceStatus = claim.priority == 'Critical' ? '4 Scene Photos · 1 Dashcam Video Verified' : '3 Scene Photos Verified';

    final isVerified = claim.status == AppConstants.statusApproved;
    final isRejected = claim.status == AppConstants.statusRejected;
    final verifStatus = isVerified
        ? 'Verified'
        : (isRejected
            ? 'Rejected'
            : (claim.status == AppConstants.statusUnderVerification
                ? 'Pending Inspection'
                : 'In Review'));

    Color statusColor = const Color(0xFFC98A00); // Warm amber default
    if (isVerified) {
      statusColor = const Color(0xFF2E8B57);
    } else if (isRejected) {
      statusColor = const Color(0xFFB54747);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfficerClaimDetailScreen(claimId: claim.id),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF84B3CE), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C16587B),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Claim ID & Verification Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84B3CE).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      claim.claimNumber,
                      style: const TextStyle(
                        color: Color(0xFF16587B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          verifStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Insured & Claim Type & Estimated Damage in ₹
              Text(
                claim.userName.isNotEmpty ? claim.userName : 'Alex Johnson',
                style: const TextStyle(
                  color: Color(0xFF16587B),
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${claim.claimType} · Est. ₹${claim.estimatedDamage.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF5F7480),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // Soft Inset Information Panel (Merino #F5EEDD + Border #84B3CE)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EEDD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF84B3CE), width: 1.0),
                ),
                child: Column(
                  children: [
                    // Documents row
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Color(0xFF16587B),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Documents: ',
                          style: TextStyle(
                            color: Color(0xFF5F7480),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            docStatus,
                            style: const TextStyle(
                              color: Color(0xFF16587B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Evidence row
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          size: 16,
                          color: Color(0xFF16587B),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Evidence: ',
                          style: TextStyle(
                            color: Color(0xFF5F7480),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            evidenceStatus,
                            style: const TextStyle(
                              color: Color(0xFF16587B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Verify & Inspect CTA Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Verify & Inspect →',
                        style: TextStyle(
                          color: Color(0xFF16587B),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
