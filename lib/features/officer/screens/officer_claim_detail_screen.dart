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
import '../officer_shell.dart';

class OfficerClaimDetailScreen extends StatefulWidget {
  final String claimId;
  const OfficerClaimDetailScreen({super.key, required this.claimId});

  @override
  State<OfficerClaimDetailScreen> createState() => _OfficerClaimDetailScreenState();
}

class _OfficerClaimDetailScreenState extends State<OfficerClaimDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _remarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6EE),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCE)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textPrimary),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim Details', style: AppTextStyles.headlineSmall.copyWith(fontSize: 14)),
            Text('ACTIVE CASE FILE', style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 1, color: AppColors.primary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.labelSmall.copyWith(fontSize: 11),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Documents'),
            Tab(text: 'Evidence'),
            Tab(text: 'Timeline'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: StreamBuilder<ClaimModel?>(
        stream: FirestoreService().getAllClaims().map((claims) {
          if (claims.isEmpty) return null;
          return claims.cast<ClaimModel?>().firstWhere(
            (c) => c?.id == widget.claimId || c?.claimNumber == widget.claimId,
            orElse: () => claims.first,
          );
        }),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final claim = snap.data;
          if (claim == null) {
            return const EmptyState(icon: Icons.search_off, title: 'Claim not found', subtitle: '');
          }
          return _buildBody(context, claim, fs, auth);
        },
      ),
      bottomNavigationBar: _buildActionBar(context, fs, auth),
    );
  }

  Widget _buildBody(BuildContext context, ClaimModel claim, FirestoreService fs, AuthProvider auth) {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildOverviewTab(claim, auth),
        _buildDocumentsTab(claim, fs, auth),
        _buildEvidenceTab(claim, fs),
        _buildTimelineTab(claim),
        _buildMessagesTab(claim, auth),
      ],
    );
  }

  Widget _buildOverviewTab(ClaimModel claim, AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Claim Header
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#${claim.claimNumber}', style: AppTextStyles.monospace),
                    const Spacer(),
                    AppStatusBadge(status: claim.status),
                    const SizedBox(width: 8),
                    PriorityBadge(priority: claim.priority),
                  ],
                ),
                const SizedBox(height: 8),
                Text(claim.claimType, style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
                Text('${claim.policyNumber} • ${DateFormat('MMM dd, yyyy').format(claim.incidentDate)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Customer
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CUSTOMER DETAILS', style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 10),
                _infoRow('Name', claim.userName),
                _infoRow('Email', claim.userEmail),
                _infoRow('Policy', claim.policyNumber),
                _infoRow('Location', claim.incidentLocation),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Claim Details
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLAIM DETAILS', style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 10),
                _infoRow('Claim Amount', '₹${NumberFormat('#,##0.00').format(claim.claimAmount)}'),
                _infoRow('Estimated Damage', '₹${NumberFormat('#,##0.00').format(claim.estimatedDamage)}'),
                if (claim.reservedValue != null)
                  _infoRow('Reserved Value', '₹${NumberFormat('#,##0.00').format(claim.reservedValue!)}'),
                const SizedBox(height: 8),
                Text('Description', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                const SizedBox(height: 4),
                Text(claim.description, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Remarks
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OFFICER NOTES', style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 10),
                TextField(
                  controller: _remarkCtrl,
                  maxLines: 3,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Add internal remarks / adjuster field notes...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(ClaimModel claim, FirestoreService fs, AuthProvider auth) {
    final officer = auth.user;
    return StreamBuilder<List<DocumentModel>>(
      stream: fs.getDocumentsForClaim(claim.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snap.data ?? [];
        if (docs.isEmpty) return const EmptyState(icon: Icons.folder_outlined, title: 'No Documents', subtitle: 'No documents uploaded for this claim.');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _documentCard(docs[i], fs, officer?.name ?? 'Officer'),
        );
      },
    );
  }

  Widget _documentCard(DocumentModel doc, FirestoreService fs, String officerName) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surfaceMid, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.documentType, style: AppTextStyles.headlineSmall.copyWith(fontSize: 13)),
                    Text(doc.fileName.isNotEmpty ? doc.fileName : 'Document', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ),
              AppStatusBadge(status: doc.verificationStatus),
            ],
          ),
          if (doc.verificationStatus == AppConstants.docPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyDocument(doc, fs, officerName),
                    icon: const Icon(Icons.check_circle_outlined, size: 14),
                    label: const Text('Verify', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectDocument(doc, fs),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Reject', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (doc.verificationStatus == AppConstants.docVerified && doc.verifiedBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Verified by ${doc.verifiedBy} • ${doc.verifiedAt != null ? DateFormat('MMM dd, HH:mm').format(doc.verifiedAt!) : ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Future<void> _verifyDocument(DocumentModel doc, FirestoreService fs, String officerName) async {
    final auth = context.read<AuthProvider>();
    await fs.updateDocument(doc.id, {
      'verificationStatus': AppConstants.docVerified,
      'verifiedBy': officerName,
      'verifiedAt': DateTime.now(),
    });
    await fs.createAuditLog(AuditLogModel(
      id: '', userId: auth.user?.id ?? '', userName: officerName,
      role: AppConstants.roleOfficer, action: 'document_verified',
      claimId: doc.claimId,
      description: 'Document "${doc.documentType}" verified by $officerName.',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _rejectDocument(DocumentModel doc, FirestoreService fs) async {
    await fs.updateDocument(doc.id, {'verificationStatus': AppConstants.docRejected});
  }

  Widget _buildEvidenceTab(ClaimModel claim, FirestoreService fs) {
    return StreamBuilder<List<EvidenceModel>>(
      stream: fs.getEvidenceForClaim(claim.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final evidence = snap.data ?? [];
        if (evidence.isEmpty) return const EmptyState(icon: Icons.photo_library_outlined, title: 'No Evidence', subtitle: 'No photos or videos uploaded.');

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: evidence.length,
          itemBuilder: (ctx, i) => _evidenceTile(evidence[i]),
        );
      },
    );
  }

  Widget _evidenceTile(EvidenceModel e) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          e.fileUrl.isNotEmpty
              ? Image.network(e.fileUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceMid, child: const Icon(Icons.broken_image, color: AppColors.textMuted)))
              : Container(color: AppColors.surfaceMid, child: Icon(e.type == 'video' ? Icons.videocam : Icons.photo, color: AppColors.textMuted, size: 40)),
          if (e.type == 'video')
            Center(child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.overlay, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            )),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: InsureXColors.veniceBlue.withValues(alpha: 0.85),
              ),
              child: Text(e.type.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: InsureXColors.merino)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(ClaimModel claim) {
    return StreamBuilder<List<AuditLogModel>>(
      stream: FirestoreService().getAuditLogs(claimId: claim.id),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return const EmptyState(icon: Icons.timeline_outlined, title: 'No Activity', subtitle: 'No actions recorded yet.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (ctx, i) => _logRow(logs[i], i == logs.length - 1),
        );
      },
    );
  }

  Widget _logRow(AuditLogModel log, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 56, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.description, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(log.userName, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMM dd, HH:mm').format(log.timestamp), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesTab(ClaimModel claim, AuthProvider auth) {
    final msgCtrl = TextEditingController();
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: FirestoreService().getMessagesForClaim(claim.id),
            builder: (ctx, snap) {
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return const Center(child: Text('No messages yet', style: TextStyle(color: AppColors.textMuted)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final isOfficer = msgs[i].senderRole == 'officer';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isOfficer ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOfficer ? AppColors.primary : AppColors.surfaceMid,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(msgs[i].content, style: AppTextStyles.bodySmall.copyWith(
                              color: isOfficer ? Colors.white : AppColors.textPrimary, fontSize: 13,
                            )),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceDark, border: Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(hintText: 'Reply to customer...'),
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final text = msgCtrl.text.trim();
                    if (text.isEmpty) return;
                    msgCtrl.clear();
                    await FirestoreService().sendMessage(MessageModel(
                      id: '', claimId: claim.id,
                      senderId: auth.user?.id ?? '',
                      senderName: auth.user?.name ?? 'Officer',
                      senderRole: 'officer',
                      content: text,
                      createdAt: DateTime.now(),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context, FirestoreService fs, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: FutureBuilder<ClaimModel?>(
          future: fs.getClaimById(widget.claimId),
          builder: (ctx, snap) {
            final claim = snap.data;
            if (claim == null) return const SizedBox.shrink();
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showMoreInfoDialog(context, claim, fs, auth),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('More Info', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showApproveDialog(context, claim, fs, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(context, claim, fs, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showApproveDialog(BuildContext ctx, ClaimModel claim, FirestoreService fs, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceMid,
        title: Text('Approve Claim', style: AppTextStyles.headlineLarge),
        content: Text('Are you sure you want to approve claim #${claim.claimNumber}?\nThis action cannot be undone.',
            style: AppTextStyles.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, elevation: 0),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await fs.updateClaim(claim.id, {'status': AppConstants.statusApproved, 'currentStep': 6});
    await fs.createNotification(NotificationModel(
      id: '', userId: claim.userId, claimId: claim.id,
      title: 'Claim Approved! 🎉',
      message: 'Your claim #${claim.claimNumber} has been approved. Settlement will be processed shortly.',
      type: AppConstants.notifClaimApproved,
      createdAt: DateTime.now(),
    ));
    await fs.createAuditLog(AuditLogModel(
      id: '', userId: auth.user?.id ?? '',
      userName: auth.user?.name ?? 'Officer',
      role: AppConstants.roleOfficer, action: 'claim_approved',
      claimId: claim.id,
      description: 'Claim #${claim.claimNumber} approved by ${auth.user?.name ?? 'Officer'}.',
      timestamp: DateTime.now(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Claim approved successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).popUntil((route) => route.isFirst);
      OfficerShell.switchTab(context, 0);
    }
  }

  Future<void> _showRejectDialog(BuildContext ctx, ClaimModel claim, FirestoreService fs, AuthProvider auth) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceMid,
        title: Text('Reject Claim', style: AppTextStyles.headlineLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Provide a reason for rejection:', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: AppTextStyles.bodySmall,
              decoration: const InputDecoration(hintText: 'Enter rejection reason...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, elevation: 0),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await fs.updateClaim(claim.id, {
      'status': AppConstants.statusRejected,
      'rejectionReason': reasonCtrl.text,
      'currentStep': 6,
    });
    await fs.createNotification(NotificationModel(
      id: '', userId: claim.userId, claimId: claim.id,
      title: 'Claim Rejected',
      message: 'Your claim #${claim.claimNumber} has been rejected. Reason: ${reasonCtrl.text}',
      type: AppConstants.notifClaimRejected,
      createdAt: DateTime.now(),
    ));
    await fs.createAuditLog(AuditLogModel(
      id: '', userId: auth.user?.id ?? '',
      userName: auth.user?.name ?? 'Officer',
      role: AppConstants.roleOfficer, action: 'claim_rejected',
      claimId: claim.id,
      description: 'Claim #${claim.claimNumber} rejected. Reason: ${reasonCtrl.text}',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _showMoreInfoDialog(BuildContext ctx, ClaimModel claim, FirestoreService fs, AuthProvider auth) async {
    final msgCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceMid,
        title: Text('Request More Information', style: AppTextStyles.headlineLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What additional information do you need?', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              style: AppTextStyles.bodySmall,
              decoration: const InputDecoration(hintText: 'Describe what is needed...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, elevation: 0),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await fs.updateClaim(claim.id, {
      'status': AppConstants.statusMoreInfoRequired,
      'additionalInfoRequest': msgCtrl.text,
    });
    await fs.createNotification(NotificationModel(
      id: '', userId: claim.userId, claimId: claim.id,
      title: 'Additional Information Required',
      message: 'Your claim #${claim.claimNumber} needs additional information: ${msgCtrl.text}',
      type: AppConstants.notifMoreInfo,
      createdAt: DateTime.now(),
    ));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
