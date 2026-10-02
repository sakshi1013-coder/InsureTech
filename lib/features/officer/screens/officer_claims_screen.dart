import 'package:flutter/material.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'officer_claim_detail_screen.dart';
import 'officer_profile_screen.dart';

class OfficerClaimsScreen extends StatefulWidget {
  const OfficerClaimsScreen({super.key});

  @override
  State<OfficerClaimsScreen> createState() => _OfficerClaimsScreenState();
}

class _OfficerClaimsScreenState extends State<OfficerClaimsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'High Priority', 'SLA Breaching', 'Motor'];
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ambient light elements
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF84B3CE).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
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
                // Premium Floating Header
                _buildFloatingHeader(),

                // Premium Search Box & Filter Pills
                _buildSearchAndFilters(),

                // Claims Stream List
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
                        claims = _getFallbackClaims();
                      }
                      claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      // Apply search
                      if (_searchQuery.trim().isNotEmpty) {
                        final query = _searchQuery.toLowerCase().trim();
                        claims = claims.where((c) {
                          return c.claimNumber.toLowerCase().contains(query) ||
                              c.policyNumber.toLowerCase().contains(query) ||
                              c.userName.toLowerCase().contains(query) ||
                              c.claimType.toLowerCase().contains(query);
                        }).toList();
                      }

                      // Apply filters
                      if (_selectedFilter == 'High Priority') {
                        claims = claims
                            .where((c) => c.priority == 'Critical' || c.priority == 'High')
                            .toList();
                      } else if (_selectedFilter == 'SLA Breaching') {
                        claims = claims.where((c) => c.priority == 'Critical').toList();
                      } else if (_selectedFilter == 'Motor') {
                        claims = claims
                            .where((c) =>
                                c.claimType.toLowerCase().contains('auto') ||
                                c.claimType.toLowerCase().contains('motor') ||
                                c.claimType.toLowerCase().contains('collision') ||
                                c.claimType.toLowerCase().contains('vehicle'))
                            .toList();
                      }

                      if (claims.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'No Claims Found',
                            subtitle: 'No claims match "$_selectedFilter" filter or search.',
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _buildAnimatedClaimCard(context, claims[i], i),
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
              Icons.assignment_outlined,
              color: Color(0xFF16587B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Claims Roster',
                style: TextStyle(
                  color: Color(0xFF16587B),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'FIELD INVESTIGATION & REVIEWS',
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
                Icon(Icons.shield_outlined, size: 13, color: Color(0xFF16587B)),
                SizedBox(width: 4),
                Text(
                  'ACTIVE QUEUE',
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(
        children: [
          // Search input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF84B3CE), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A16587B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, color: Color(0xFF16587B), fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search Claim ID / Policy # / Insured...',
                hintStyle: const TextStyle(color: Color(0xFF5F7480), fontSize: 13, fontWeight: FontWeight.w400),
                prefixIcon: const Icon(Icons.search_rounded, size: 21, color: Color(0xFF16587B)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined, size: 20, color: Color(0xFF16587B)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scanning Claim QR Code...'),
                        backgroundColor: Color(0xFF16587B),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                final isSla = filter == 'SLA Breaching';

                Color activeBg = const Color(0xFF16587B);
                Color activeText = const Color(0xFFF5EEDD);
                Color activeBorder = const Color(0xFF16587B);

                if (isSla && isSelected) {
                  activeBg = const Color(0xFFB54747);
                  activeBorder = const Color(0xFFB54747);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? activeBg : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? activeBorder : const Color(0xFF84B3CE),
                          width: 1.1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeBg.withValues(alpha: 0.20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? activeText : const Color(0xFF16587B),
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
        ],
      ),
    );
  }

  Widget _buildAnimatedClaimCard(BuildContext context, ClaimModel claim, int index) {
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
      child: _OfficerClaimCard(claim: claim),
    );
  }

  List<ClaimModel> _getFallbackClaims() {
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
        description: 'Multi-vehicle collision at intersection. Front bumper and hood damaged.',
        estimatedDamage: 4500.0,
        claimAmount: 3800.0,
        status: AppConstants.statusUnderReview,
        priority: 'Critical',
        createdAt: now.subtract(const Duration(hours: 14)),
        updatedAt: now,
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
        description: 'Pipe burst in second-floor bathroom causing ceiling damage.',
        estimatedDamage: 6200.0,
        claimAmount: 5100.0,
        status: AppConstants.statusUnderVerification,
        priority: 'High',
        createdAt: now.subtract(const Duration(hours: 32)),
        updatedAt: now,
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
        description: 'Severe hailstorm shattered rear passenger window and dented roof.',
        estimatedDamage: 1850.0,
        claimAmount: 1850.0,
        status: AppConstants.statusApproved,
        priority: 'Medium',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
      ),
      ClaimModel(
        id: 'clm_4',
        claimNumber: 'CLM-2024-2109',
        userId: 'usr_4',
        userEmail: 'emily.watson@gmail.com',
        userName: 'Emily Watson',
        policyId: 'pol_4',
        policyNumber: 'POL-RENTERS-1022',
        claimType: 'Electronics Theft',
        incidentDate: now.subtract(const Duration(days: 7)),
        incidentLocation: 'Apt 4B, 120 West End Ave',
        description: 'Stolen laptop and audio equipment following apartment break-in.',
        estimatedDamage: 2400.0,
        claimAmount: 2200.0,
        status: AppConstants.statusCompleted,
        priority: 'Low',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now,
      ),
    ];
  }
}

class _OfficerClaimCard extends StatefulWidget {
  final ClaimModel claim;
  const _OfficerClaimCard({required this.claim});

  @override
  State<_OfficerClaimCard> createState() => _OfficerClaimCardState();
}

class _OfficerClaimCardState extends State<_OfficerClaimCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final isCritical = claim.priority == 'Critical';
    final isHigh = claim.priority == 'High';

    Color priorityColor = const Color(0xFF2E8B57);
    if (isCritical) {
      priorityColor = const Color(0xFFB54747);
    } else if (isHigh) {
      priorityColor = const Color(0xFFC98A00);
    }

    final slaText = isCritical
        ? 'SLA Critical · 2h remaining'
        : (isHigh ? 'Within SLA · 14h left' : 'Within SLA · 48h left');

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfficerClaimDetailScreen(claimId: claim.id),
          ),
        );
      },
      color: Colors.white,
      borderRadius: 26,
      padding: const EdgeInsets.all(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C16587B),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Top Row: Claim ID pill, Priority pill, Status pill
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      claim.priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AppStatusBadge(status: claim.status),
                ],
              ),
              const SizedBox(height: 14),

              // Insured Person's Name visually prominent & Claim amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          'Policy: ${claim.policyNumber} · ${claim.claimType}',
                          style: const TextStyle(
                            color: Color(0xFF5F7480),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${claim.claimAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF16587B),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5EDF2)),
              const SizedBox(height: 12),

              // Bottom Info: Assigned date, SLA status, Right Arrow
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Color(0xFF5F7480)),
                  const SizedBox(width: 5),
                  Text(
                    'Assigned: ${_formatDate(claim.createdAt)}',
                    style: const TextStyle(
                      color: Color(0xFF5F7480),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCritical ? const Color(0xFFB54747) : const Color(0xFF2E8B57),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slaText,
                    style: TextStyle(
                      color: isCritical ? const Color(0xFFB54747) : const Color(0xFF5F7480),
                      fontSize: 11.5,
                      fontWeight: isCritical ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF16587B),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
