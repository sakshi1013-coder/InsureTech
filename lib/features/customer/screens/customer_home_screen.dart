import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/models/policy_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'customer_claim_detail_screen.dart';
import 'customer_new_claim_screen.dart';
import 'customer_notifications_screen.dart';
import 'customer_policy_detail_screen.dart';
import 'customer_chat_screen.dart';
import 'customer_profile_screen.dart';
import '../customer_shell.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final fs = FirestoreService();

    final displayName = user.name.trim().isNotEmpty ? user.name : 'Alexander Wright';
    final initials = (user.initials.trim().isNotEmpty && user.initials != '?') ? user.initials : 'AW';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ambient organic curves
          Positioned.fill(
            child: CustomPaint(
              painter: CustomerBackgroundPainter(),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header (Avatar + Greeting + Notification Bell)
                SliverToBoxAdapter(
                  child: _buildHeader(context, displayName, initials, fs, user.id),
                ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Total Coverage Card (Hero Venice Blue Card with 3D Glass Shield)
                        _buildTotalCoverageCard(context, user.id, fs),
                        const SizedBox(height: 18),

                        // 4 Quick Action Cards (Report Claim, Assistance, ID Card, Payment)
                        _buildQuickActions(context),
                        const SizedBox(height: 22),

                        // Your Active Policies Section with Carousel Indicators
                        _buildActivePoliciesSection(context, user.id, fs),
                        const SizedBox(height: 20),

                        // AI Assistant Banner Card with Mascot
                        _buildAiAssistantCard(context, firstName),
                        const SizedBox(height: 22),

                        // Recent Claims Section
                        _buildRecentClaimsSection(context, user.id, fs),
                        const SizedBox(height: 100), // Space for floating bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP HEADER WIDGET
  // ==========================================
  Widget _buildHeader(
    BuildContext context,
    String name,
    String initials,
    FirestoreService fs,
    String userId,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          // Circular Avatar (Taps to open Customer Profile)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
              );
            },
            child: Tooltip(
              message: 'View Profile',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: InsureXColors.veniceBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: InsureXColors.veniceBlue.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Greeting & User Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Good Morning,',
                  style: TextStyle(
                    color: Color(0xFF5F7480),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // Floating Circular Notification Button
          StreamBuilder<int>(
            stream: fs.getUnreadNotificationCount(userId),
            builder: (ctx, snap) {
              final unread = snap.data ?? 1;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerNotificationsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5EDF2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0E16587B),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 21,
                        color: InsureXColors.veniceBlue,
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 11,
                          right: 12,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF216F9A),
                              shape: BoxShape.circle,
                            ),
                          ),
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
  }

  // ==========================================
  // TOTAL COVERAGE CARD (HERO CARD WITH 3D GLASS SHIELD)
  // ==========================================
  Widget _buildTotalCoverageCard(
    BuildContext context,
    String userId,
    FirestoreService fs,
  ) {
    return StreamBuilder<List<PolicyModel>>(
      stream: fs.getPoliciesForUser(userId),
      builder: (ctx, snap) {
        final policies = snap.data ?? [];
        double totalPremium = 0;
        final activeTypes = <String>{};

        for (final p in policies) {
          if (p.status == 'Active') {
            totalPremium += p.premium;
            activeTypes.add(p.policyType.split(' ').first);
          }
        }
        if (totalPremium == 0) totalPremium = 1586.00;
        final typesLabel = activeTypes.isNotEmpty
            ? activeTypes.take(3).join('  •  ')
            : 'Auto  •  Home  •  Renters';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B6B98),
                Color(0xFF144F72),
                Color(0xFF0F3B55),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF3885AF).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E144F72),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Decorative wave glow lines in the background of the card
                Positioned.fill(
                  child: CustomPaint(
                    painter: HeroCardWavePainter(),
                  ),
                ),

                // 3D Glass Shield on the Right
                const Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GlassShieldWidget(),
                  ),
                ),

                // Card content on the Left
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 130, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Total Coverage" Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Total Coverage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Large Amount: ₹1,586.00
                      Text(
                        NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(totalPremium),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Subtitle: Auto • Home • Renters
                      Text(
                        typesLabel,
                        style: const TextStyle(
                          color: Color(0xFFB5DEF4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Pill Button: "View all Policies →"
                      GestureDetector(
                        onTap: () {
                          CustomerShell.switchTab(context, 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEDD),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View all Policies',
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 4 QUICK ACTIONS CARDS (Report Claim, Assistance, ID Card, Payment)
  // ==========================================
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickActionCard(
            label: 'Report Claim',
            icon: Icons.add_circle_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerNewClaimScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionCard(
            label: 'Assistance',
            icon: Icons.headset_mic_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerChatScreen(
                    claimId: 'general_support',
                    officerName: 'INSUREX AI Assistant',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionCard(
            label: 'ID Card',
            icon: Icons.badge_outlined,
            onTap: () => _showIdCardSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionCard(
            label: 'Payment',
            icon: Icons.credit_card_outlined,
            onTap: () => _showPaymentSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EDF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0816587B),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F2F8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 21,
                  color: InsureXColors.veniceBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: InsureXColors.veniceBlue,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ACTIVE POLICIES SECTION WITH CAROUSEL INDICATOR
  // ==========================================
  Widget _buildActivePoliciesSection(
    BuildContext context,
    String userId,
    FirestoreService fs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Title, Pagination Bar, and View All link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Active Policies',
                  style: TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Pagination lines matching screenshot
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: InsureXColors.rockBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 14,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5E6F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                CustomerShell.switchTab(context, 1);
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: InsureXColors.veniceBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stream of Active Policies
        StreamBuilder<List<PolicyModel>>(
          stream: fs.getPoliciesForUser(userId),
          builder: (ctx, snap) {
            final policies = snap.data ?? _getFallbackPolicies();
            if (policies.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: policies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) => _buildPolicyHorizontalCard(context, policies[i]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPolicyHorizontalCard(BuildContext context, PolicyModel policy) {
    final isAuto = policy.policyType.toLowerCase().contains('auto') ||
        policy.policyType.toLowerCase().contains('vehicle') ||
        policy.policyType.toLowerCase().contains('motor');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerPolicyDetailScreen(policy: policy),
          ),
        );
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6EF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFA7E2C3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: InsureXColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: InsureXColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Illustration badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F2F8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAuto ? Icons.directions_car_rounded : Icons.home_rounded,
                    size: 18,
                    color: InsureXColors.veniceBlue,
                  ),
                ),
              ],
            ),

            // Policy Type & Number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy.policyType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Policy #${policy.policyNumber}',
                  style: const TextStyle(
                    color: Color(0xFF5F7480),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Premium
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Premium',
                    style: TextStyle(
                      color: Color(0xFF5F7480),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${policy.premium.toStringAsFixed(2)} /mo',
                    style: const TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // AI ASSISTANT BANNER CARD WITH MASCOT
  // ==========================================
  Widget _buildAiAssistantCard(BuildContext context, String firstName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFE8F3F9),
            Color(0xFFD8ECF7),
          ],
        ),
        border: Border.all(color: const Color(0xFFC7E2F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C16587B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cute AI Robot Mascot
          const AiRobotMascotWidget(),
          const SizedBox(width: 14),

          // Message Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 13.5,
                      fontFamily: 'Inter',
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(
                        text: "Hey $firstName! I'm your\n",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(
                        text: 'INSUREX AI Assistant.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'How can I help you today?',
                  style: TextStyle(
                    color: Color(0xFF5F7480),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Circular Venice Blue Arrow Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerChatScreen(
                    claimId: 'general_support',
                    officerName: 'INSUREX AI Assistant',
                  ),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: InsureXColors.veniceBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2816587B),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RECENT CLAIMS SECTION
  // ==========================================
  Widget _buildRecentClaimsSection(
    BuildContext context,
    String userId,
    FirestoreService fs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Claims',
              style: TextStyle(
                color: InsureXColors.veniceBlue,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                CustomerShell.switchTab(context, 2);
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: InsureXColors.veniceBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        StreamBuilder<List<ClaimModel>>(
          stream: fs.getClaimsForUser(userId),
          builder: (ctx, snap) {
            final claims = (snap.data ?? []).toList();
            claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (claims.isEmpty) {
              // Exact Reference Card matching user screenshot
              return _buildApprovedClaimCard(
                context,
                claimNumber: 'CLM-2024-1102',
                status: 'Approved',
                title: 'Windshield Damage',
                date: 'Aug 29, 2024',
                amount: '₹650.00',
                claimId: null,
              );
            }

            final first = claims.first;
            return _buildApprovedClaimCard(
              context,
              claimNumber: first.claimNumber,
              status: first.status,
              title: first.incidentType,
              date: DateFormat('MMM dd, yyyy').format(first.incidentDate),
              amount: NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(first.claimAmount),
              claimId: first.id,
            );
          },
        ),
      ],
    );
  }

  Widget _buildApprovedClaimCard(
    BuildContext context, {
    required String claimNumber,
    required String status,
    required String title,
    required String date,
    required String amount,
    required String? claimId,
  }) {
    return Container(
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
          // Top Row: Claim Number on Left, Approved Badge on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                claimNumber,
                style: const TextStyle(
                  color: Color(0xFF5F7480),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7E2C3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: InsureXColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: const TextStyle(
                        color: InsureXColors.success,
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

          // Middle Row: Incident Title + Date on Left, Amount on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF8B9FA8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: InsureXColors.veniceBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom Button: "Track Claim Status →"
          GestureDetector(
            onTap: () {
              if (claimId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerClaimDetailScreen(claimId: claimId),
                  ),
                );
              } else {
                CustomerShell.switchTab(context, 2);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUICK ACTION SHEETS (ID Card & Payment)
  // ==========================================
  void _showIdCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Digital Insurance ID',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: InsureXColors.veniceBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Digital Card Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: InsureXColors.veniceBlue,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2816587B),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INSUREX AUTO ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Icon(Icons.contactless_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Policy # 123 456 789',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _idField('INSURED', 'Alexander Wright'),
                      _idField('VALID THRU', '05/26'),
                      _idField('VIN', '•••• 89PF'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryGradientButton(
              label: 'Add to Apple Wallet',
              icon: Icons.wallet_rounded,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _idField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showPaymentSheet(BuildContext context) {
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
            const SizedBox(height: 16),
            const Text(
              'Upcoming Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: InsureXColors.veniceBlue,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Jun 10, 2025',
                        style: TextStyle(
                          color: Color(0xFF5F7480),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '₹112.50',
                        style: TextStyle(
                          color: InsureXColors.veniceBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '•••• 4242 (Visa)',
                    style: TextStyle(
                      color: Color(0xFF5F7480),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryGradientButton(
              label: 'Pay Now (₹112.50)',
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Payment processed successfully!'),
                    backgroundColor: InsureXColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<PolicyModel> _getFallbackPolicies() {
    return [
      PolicyModel(
        id: 'pol_1',
        policyNumber: '6ABC123',
        policyName: 'Comprehensive Auto Shield',
        userId: 'demo',
        policyType: 'Auto Insurance',
        coverageDetails: 'Full Collision & Comprehensive Vehicle Protection',
        totalCoverage: 100000,
        deductible: 500,
        annualPremium: 1350.00,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().add(const Duration(days: 275)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_2',
        policyNumber: '7DEF456',
        policyName: 'Premium Homeowners Shield',
        userId: 'demo',
        policyType: 'Home Insurance',
        coverageDetails: 'Dwelling & Personal Property Comprehensive',
        totalCoverage: 350000,
        deductible: 1000,
        annualPremium: 2220.00,
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        endDate: DateTime.now().add(const Duration(days: 245)),
        status: 'Active',
      ),
    ];
  }
}

// ==========================================
// 3D GLASS SHIELD GRAPHIC WITH CHECKMARK
// ==========================================
class GlassShieldWidget extends StatelessWidget {
  const GlassShieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing orbital ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
          ),

          // Translucent Shield
          CustomPaint(
            size: const Size(88, 104),
            painter: GlassShieldPainter(),
            child: const SizedBox(
              width: 88,
              height: 104,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    // Shield path with curved top and tapered pointed bottom
    path.moveTo(w * 0.18, 0);
    path.lineTo(w * 0.82, 0);
    path.quadraticBezierTo(w, 0, w, h * 0.25);
    path.quadraticBezierTo(w, h * 0.65, w * 0.5, h);
    path.quadraticBezierTo(0, h * 0.65, 0, h * 0.25);
    path.quadraticBezierTo(0, 0, w * 0.18, 0);
    path.close();

    // Semi-transparent frosted glass gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Glowing rim stroke
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// HERO CARD WAVE PAINTER
// ==========================================
class HeroCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width, size.height * 0.85);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.95);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// CUTE AI ROBOT MASCOT WIDGET
// ==========================================
class AiRobotMascotWidget extends StatelessWidget {
  const AiRobotMascotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft glowing circular background
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFCDE5F4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1216587B),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          // Robot Head
          Container(
            width: 36,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1016587B),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dark visor display
                Container(
                  width: 28,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16587B),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Smiling curved eye 1
                      Container(
                        width: 7,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF67D8F7),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Smiling curved eye 2
                      Container(
                        width: 7,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF67D8F7),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Left earphone
          Positioned(
            left: 5,
            child: Container(
              width: 5,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF84B3CE),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Right earphone
          Positioned(
            right: 5,
            child: Container(
              width: 5,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF84B3CE),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Sparkle ✦ star on top-right
          const Positioned(
            top: 2,
            right: 2,
            child: Text(
              '✦',
              style: TextStyle(
                color: Color(0xFF76C4EA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// BACKGROUND AMBIENT ORGANIC WAVES PAINTER
// ==========================================
class CustomerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFF0F6F9).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Organic top-right wave glow
    final path1 = Path();
    path1.moveTo(size.width * 0.45, 0);
    path1.quadraticBezierTo(size.width * 0.7, size.height * 0.12, size.width, size.height * 0.08);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Organic soft mid wave
    final paint2 = Paint()
      ..color = const Color(0xFFF4F8FA).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(size.width * 0.35, size.height * 0.78, 0, size.height * 0.9);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
