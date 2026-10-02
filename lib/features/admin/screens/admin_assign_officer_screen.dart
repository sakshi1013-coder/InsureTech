import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/models/user_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'package:insurex_app/core/constants/app_constants.dart';

class AdminAssignOfficerScreen extends StatefulWidget {
  final String claimId;
  final String claimNumber;
  const AdminAssignOfficerScreen({super.key, required this.claimId, required this.claimNumber});

  @override
  State<AdminAssignOfficerScreen> createState() => _AdminAssignOfficerScreenState();
}

class _AdminAssignOfficerScreenState extends State<AdminAssignOfficerScreen> {
  OfficerModel? _selectedOfficer;
  bool _isAssigning = false;

  Future<void> _assign() async {
    if (_selectedOfficer == null) return;
    setState(() => _isAssigning = true);
    final auth = context.read<AuthProvider>();
    final fs = FirestoreService();
    try {
      // Update claim
      await fs.updateClaim(widget.claimId, {
        'officerId': _selectedOfficer!.id,
        'officerName': _selectedOfficer!.name,
        'status': AppConstants.statusUnderVerification,
        'currentStep': 3,
      });

      // Update officer workload
      await fs.updateOfficerWorkload(_selectedOfficer!.id, 1);

      // Get claim for notification
      final claim = await fs.getClaimById(widget.claimId);
      if (claim != null) {
        // Notify customer
        await fs.createNotification(NotificationModel(
          id: '', userId: claim.userId, claimId: widget.claimId,
          title: 'Officer Assigned',
          message: 'Officer ${_selectedOfficer!.name} (${_selectedOfficer!.employeeId}) has been assigned to your claim #${widget.claimNumber}.',
          type: AppConstants.notifOfficerAssigned,
          createdAt: DateTime.now(),
        ));
      }

      // Audit log
      await fs.createAuditLog(AuditLogModel(
        id: '', userId: auth.user?.id ?? '',
        userName: auth.user?.name ?? 'Admin',
        role: AppConstants.roleAdmin,
        action: 'officer_assigned',
        claimId: widget.claimId,
        description: 'Admin ${auth.user?.name ?? 'Admin'} assigned Officer ${_selectedOfficer!.name} to claim #${widget.claimNumber}.',
        timestamp: DateTime.now(),
      ));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Officer ${_selectedOfficer!.name} assigned to #${widget.claimNumber}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _isAssigning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: InsureXAppBar(
        title: 'Assign Officer',
        subtitle: 'Claim #${widget.claimNumber}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select an Available Officer', style: AppTextStyles.headlineLarge),
                Text('Choose an officer to handle this claim', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OfficerModel>>(
              stream: fs.getOfficers(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final officers = snap.data ?? [];
                if (officers.isEmpty) {
                  return const EmptyState(icon: Icons.badge_outlined, title: 'No Officers', subtitle: 'No officers available.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: officers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _officerCard(officers[i]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: _selectedOfficer != null ? 'Assign ${_selectedOfficer!.name}' : 'Select an Officer',
                onPressed: _selectedOfficer != null ? _assign : null,
                isLoading: _isAssigning,
                icon: Icons.assignment_ind_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _officerCard(OfficerModel o) {
    final isSelected = _selectedOfficer?.id == o.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedOfficer = o),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFFFAF6EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFEADBCE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceMid,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(o.initials, style: AppTextStyles.headlineLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ))),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(o.employeeId, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontSize: 9)),
                      ),
                    ],
                  ),
                  Text(o.designation, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  Text(o.specialty, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metricBadge('${o.currentWorkload} Claims', AppColors.warning),
                      const SizedBox(width: 8),
                      _metricBadge(o.isAvailable ? 'Available' : 'Busy', o.isAvailable ? AppColors.success : AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _metricBadge(String text, Color color) {
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
