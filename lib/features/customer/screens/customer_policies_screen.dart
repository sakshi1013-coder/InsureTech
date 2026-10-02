import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/policy_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'customer_policy_detail_screen.dart';
import 'customer_new_claim_screen.dart';
import 'customer_profile_screen.dart';

class CustomerPoliciesScreen extends StatefulWidget {
  const CustomerPoliciesScreen({super.key});

  @override
  State<CustomerPoliciesScreen> createState() => _CustomerPoliciesScreenState();
}

class _CustomerPoliciesScreenState extends State<CustomerPoliciesScreen> {
  String _filter = 'All';

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
          'My Insurance Policies',
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
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: InsureXColors.veniceBlue,
                  backgroundColor: InsureXColors.rockBlue.withValues(alpha: 0.18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showAddPolicyModal(context, user.id),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Add Policy',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<PolicyModel>>(
        stream: fs.getPoliciesForUser(user.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          final allPolicies = snap.data ?? _getFallbackPolicies();
          final activeCount = allPolicies.where((p) => p.status == 'Active').length;
          final expiredCount = allPolicies.where((p) => p.status == 'Expired').length;

          var displayedPolicies = allPolicies;
          if (_filter == 'Active') {
            displayedPolicies = allPolicies.where((p) => p.status == 'Active').toList();
          } else if (_filter == 'Expired') {
            displayedPolicies = allPolicies.where((p) => p.status == 'Expired').toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter pills
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _filterPill('All (${allPolicies.length})', _filter == 'All', () => setState(() => _filter = 'All')),
                    const SizedBox(width: 8),
                    _filterPill('Active ($activeCount)', _filter == 'Active', () => setState(() => _filter = 'Active')),
                    const SizedBox(width: 8),
                    _filterPill('Expired ($expiredCount)', _filter == 'Expired', () => setState(() => _filter = 'Expired')),
                  ],
                ),
              ),

              // Policy cards list
              Expanded(
                child: displayedPolicies.isEmpty
                    ? const EmptyState(
                        icon: Icons.shield_outlined,
                        title: 'No Policies Found',
                        subtitle: 'No insurance policies match your current filter.',
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                        itemCount: displayedPolicies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _policyCard(context, displayedPolicies[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterPill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.veniceBlue : const Color(0xFFFAF6EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.veniceBlue : const Color(0xFFEADBCE)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.veniceBlue.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? InsureXColors.merino : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _policyCard(BuildContext context, PolicyModel p) {
    final isAuto = p.policyType.toLowerCase().contains('auto') ||
        p.policyType.toLowerCase().contains('vehicle') ||
        p.policyType.toLowerCase().contains('motor');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerPolicyDetailScreen(policy: p),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07171A2B),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.rockBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAuto ? Icons.directions_car_rounded : Icons.home_rounded,
                        color: AppColors.veniceBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.policyType,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Policy #${p.policyNumber}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AppStatusBadge(status: p.status, compact: true),
              ],
            ),
            const SizedBox(height: 14),

            // Coverage & Premium row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBCE).withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Coverage',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(p.coverageAmount),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Monthly Premium',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${p.premium.toStringAsFixed(2)} /mo',
                        style: const TextStyle(
                          color: AppColors.veniceBlue,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.veniceBlue, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerPolicyDetailScreen(policy: p),
                        ),
                      );
                    },
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.veniceBlue,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.veniceBlue,
                      foregroundColor: InsureXColors.merino,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerNewClaimScreen(initialPolicy: p),
                        ),
                      );
                    },
                    child: const Text(
                      'File Claim',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPolicyModal(BuildContext context, String userId) {
    final nameCtrl = TextEditingController(text: 'Comprehensive Protection Shield');
    final coverageCtrl = TextEditingController(text: '150000');
    final premiumCtrl = TextEditingController(text: '120.00');
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
                'Issue New Insurance Policy',
                style: TextStyle(
                  color: Color(0xFF16587B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Configure policy tier, coverage sum and coverage terms',
                style: TextStyle(color: Color(0xFF5F7480), fontSize: 12.5),
              ),
              const SizedBox(height: 18),

              // Policy Type selector
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
                'Policy Name',
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
                          final coverage = double.tryParse(coverageCtrl.text.replaceAll(',', '')) ?? 150000;
                          final monthly = double.tryParse(premiumCtrl.text.replaceAll(',', '')) ?? 120;
                          final deductible = double.tryParse(deductibleCtrl.text.replaceAll(',', '')) ?? 500;
                          final polNum = 'POL-${selectedType.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}';

                          final newPolicy = PolicyModel(
                            id: 'pol_${DateTime.now().millisecondsSinceEpoch}',
                            userId: userId,
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
                                content: Text('New Policy #${newPolicy.policyNumber} created and active!'),
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

  List<PolicyModel> _getFallbackPolicies() {
    return [
      PolicyModel(
        id: 'pol_1',
        policyNumber: '123 456 789',
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
        policyNumber: '456 789 012',
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
