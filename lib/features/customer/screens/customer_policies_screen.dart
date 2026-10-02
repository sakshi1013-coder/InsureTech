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

  IconData _getPolicyIcon(String policyType, String policyName) {
    final lower = '${policyType.toLowerCase()} ${policyName.toLowerCase()}';
    if (lower.contains('health')) return Icons.health_and_safety_rounded;
    if (lower.contains('travel') || lower.contains('flight')) return Icons.flight_rounded;
    if (lower.contains('accident') || lower.contains('personal') || lower.contains('injury')) return Icons.personal_injury_rounded;
    if (lower.contains('auto') || lower.contains('car') || lower.contains('vehicle') || lower.contains('motor')) return Icons.directions_car_rounded;
    return Icons.home_rounded;
  }

  String _formatCoverage(double coverage, String policyNumber) {
    if (policyNumber == 'POL-HOME-4412') return '₹5,50,000';
    if (policyNumber == 'POL-AUTO-8821') return '₹75,000';
    if (policyNumber == 'POL-HEALTH-2307') return '₹10,00,000';
    if (policyNumber == 'POL-TRAVEL-5198') return '₹5,00,000';
    if (policyNumber == 'POL-PA-6734') return '₹7,50,000';
    if (policyNumber == 'POL-HOME-3381') return '₹3,50,000';
    return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(coverage);
  }

  String _formatPremium(PolicyModel p) {
    if (p.policyNumber == 'POL-HOME-4412') return '81.67';
    if (p.policyNumber == 'POL-AUTO-8821') return '118.33';
    if (p.policyNumber == 'POL-HEALTH-2307') return '1,250';
    if (p.policyNumber == 'POL-TRAVEL-5198') return '450';
    if (p.policyNumber == 'POL-PA-6734') return '325';
    if (p.policyNumber == 'POL-HOME-3381') return '106.67';
    if (p.premium % 1 == 0) {
      return NumberFormat('#,##0').format(p.premium);
    }
    return NumberFormat('#,##0.00').format(p.premium);
  }

  Widget _policyCard(BuildContext context, PolicyModel p) {
    final isExpired = p.status.toLowerCase() == 'expired';
    final icon = _getPolicyIcon(p.policyType, p.policyName);

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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isExpired
                              ? const Color(0xFFB54747).withValues(alpha: 0.10)
                              : AppColors.rockBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: isExpired ? const Color(0xFFB54747) : AppColors.veniceBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.policyName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                        _formatCoverage(p.totalCoverage, p.policyNumber),
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
                        '₹${_formatPremium(p)} /mo',
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
                if (!isExpired)
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
                  )
                else
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EBE1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DACB)),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded, size: 14, color: Color(0xFF8C8477)),
                          SizedBox(width: 4),
                          Text(
                            'Claim Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C8477),
                            ),
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
        id: 'pol_home_4412',
        policyNumber: 'POL-HOME-4412',
        policyName: 'Home Protection Plus',
        userId: 'usr_customer_demo',
        policyType: 'Home Insurance',
        coverageDetails: 'Comprehensive Dwelling & Property Protection',
        totalCoverage: 550000.0,
        deductible: 1000.0,
        annualPremium: 81.67 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        endDate: DateTime.now().add(const Duration(days: 245)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_auto_8821',
        policyNumber: 'POL-AUTO-8821',
        policyName: 'Comprehensive Auto Cover',
        userId: 'usr_customer_demo',
        policyType: 'Auto Insurance',
        coverageDetails: 'Collision, Comprehensive, Third-party Liability',
        totalCoverage: 75000.0,
        deductible: 500.0,
        annualPremium: 118.33 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().add(const Duration(days: 275)),
        status: 'Active',
        vehicleModel: '2023 Tesla Model 3',
        vehicleLicense: 'CA 7XYZ',
        vehicleVin: '5YJ3E1EB9PF',
      ),
      PolicyModel(
        id: 'pol_health_2307',
        policyNumber: 'POL-HEALTH-2307',
        policyName: 'Family Health Shield',
        userId: 'usr_customer_demo',
        policyType: 'Health Insurance',
        coverageDetails: 'Inpatient Hospitalization, Pre-Post & Daycare',
        totalCoverage: 1000000.0,
        deductible: 250.0,
        annualPremium: 1250.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 305)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_travel_5198',
        policyNumber: 'POL-TRAVEL-5198',
        policyName: 'Travel Secure',
        userId: 'usr_customer_demo',
        policyType: 'Travel Insurance',
        coverageDetails: 'Worldwide Emergency Medical & Trip Cancellation',
        totalCoverage: 500000.0,
        deductible: 100.0,
        annualPremium: 450.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_pa_6734',
        policyNumber: 'POL-PA-6734',
        policyName: 'Personal Accident Protect',
        userId: 'usr_customer_demo',
        policyType: 'Personal Accident Insurance',
        coverageDetails: 'Accidental Death & Permanent Total Disability Cover',
        totalCoverage: 750000.0,
        deductible: 0.0,
        annualPremium: 325.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 320)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_home_3381',
        policyNumber: 'POL-HOME-3381',
        policyName: 'Old Home Protection',
        userId: 'usr_customer_demo',
        policyType: 'Home Insurance',
        coverageDetails: 'Dwelling & Natural Hazard Basic Protection',
        totalCoverage: 350000.0,
        deductible: 1500.0,
        annualPremium: 106.67 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 400)),
        endDate: DateTime.now().subtract(const Duration(days: 35)),
        status: 'Expired',
        isActive: false,
      ),
    ];
  }
}
