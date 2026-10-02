import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'customer_chat_screen.dart';

class CustomerClaimDetailScreen extends StatefulWidget {
  final String claimId;
  const CustomerClaimDetailScreen({super.key, required this.claimId});

  @override
  State<CustomerClaimDetailScreen> createState() => _CustomerClaimDetailScreenState();
}

class _CustomerClaimDetailScreenState extends State<CustomerClaimDetailScreen> {
  bool _isUploading = false;
  bool _isSubmittingNextStep = false;
  late Future<ClaimModel?> _claimFuture;

  @override
  void initState() {
    super.initState();
    _claimFuture = FirestoreService().getClaimById(widget.claimId);
  }

  void _refreshClaim() {
    setState(() {
      _claimFuture = FirestoreService().getClaimById(widget.claimId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6EE),
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
        title: FutureBuilder<ClaimModel?>(
          future: _claimFuture,
          builder: (ctx, snap) {
            final claim = snap.data;
            return Text(
              claim != null ? claim.claimNumber : 'Claim Details',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
      body: FutureBuilder<ClaimModel?>(
        future: _claimFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: InsureXColors.veniceBlue),
            );
          }
          final claim = snap.data;
          if (claim == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Claim Not Found',
              subtitle: 'The specified claim details could not be loaded.',
            );
          }

          return StreamBuilder<List<DocumentModel>>(
            stream: fs.getDocumentsForClaim(claim.id),
            builder: (ctx, docSnap) {
              final docs = docSnap.data ?? [];

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. MAIN STATUS CARD
                    // ==========================================
                    _buildMainStatusCard(claim),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 2. CLAIM TIMELINE
                    // ==========================================
                    _buildTimelineCard(claim),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 3. CLAIM DETAILS CARD
                    // ==========================================
                    _buildClaimDetailsCard(claim),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 4. UPLOADED EVIDENCE & DOCUMENTS
                    // ==========================================
                    _buildUploadedDocumentsSection(context, claim, fs, docs),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 5. NEXT STEP OPTION CARD
                    // ==========================================
                    _buildNextStepCard(context, claim, docs),
                    const SizedBox(height: 22),

                    // ==========================================
                    // 6. BOTTOM ACTION BUTTONS
                    // ==========================================
                    _buildActionButtons(context, claim, docs),
                    const SizedBox(height: 36),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // 1. MAIN STATUS CARD
  // ==========================================
  Widget _buildMainStatusCard(ClaimModel claim) {
    double progress = 0.50;
    String statusTitle = "We're on it! Your claim is being\nreviewed by our team.";
    String pillText = 'In Progress';

    if (claim.status == AppConstants.statusApproved || claim.status == AppConstants.statusCompleted) {
      progress = 1.0;
      statusTitle = 'Claim Approved! 🎉\nSettlement payment authorized.';
      pillText = 'Approved';
    } else if (claim.currentStep >= 4 || claim.status == AppConstants.statusUnderReview) {
      progress = 0.75;
      statusTitle = 'Evidence submitted!\nUndergoing damage assessment.';
      pillText = 'Assessment';
    }

    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: InsureXColors.veniceBlue,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pillText,
                      style: const TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: InsureXColors.veniceBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            statusTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: InsureXColors.rockBlue.withValues(alpha: 0.25),
                  ),
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
        ],
      ),
    );
  }

  // ==========================================
  // 2. CLAIM TIMELINE CARD
  // ==========================================
  Widget _buildTimelineCard(ClaimModel claim) {
    final isEstimateApproval = claim.currentStep >= 4;
    final isSettled = claim.status == AppConstants.statusApproved ||
        claim.status == AppConstants.statusCompleted ||
        claim.currentStep >= 6;

    final stages = [
      {
        'title': 'Claim Reported',
        'time': DateFormat('MMM dd, yyyy · hh:mm a').format(claim.createdAt),
        'state': 'completed',
      },
      {
        'title': 'Information Received',
        'time': DateFormat('MMM dd, yyyy · hh:mm a')
            .format(claim.createdAt.add(const Duration(minutes: 45))),
        'state': 'completed',
      },
      {
        'title': 'Under Review',
        'time': isEstimateApproval ? 'Review completed' : 'In Progress',
        'state': isEstimateApproval ? 'completed' : 'current',
      },
      {
        'title': 'Estimate Approval',
        'time': isSettled
            ? 'Estimate approved'
            : (isEstimateApproval ? 'Under Assessment' : 'Pending assessment'),
        'state': isSettled ? 'completed' : (isEstimateApproval ? 'current' : 'pending'),
      },
      {
        'title': 'Settlement',
        'time': isSettled ? 'Payment Authorized' : 'Expected within 3-5 days',
        'state': isSettled ? 'completed' : 'pending',
      },
    ];

    return Container(
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
            'Claim Timeline',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(stages.length, (i) {
              final stage = stages[i];
              final isLast = i == stages.length - 1;
              final state = stage['state'];

              Color dotColor;
              Color lineColor = const Color(0xFFE2E8F0);
              Widget dotChild = const SizedBox.shrink();

              if (state == 'completed') {
                dotColor = InsureXColors.rockBlue;
                lineColor = InsureXColors.rockBlue;
                dotChild = const Icon(Icons.check, size: 12, color: Colors.white);
              } else if (state == 'current') {
                dotColor = InsureXColors.veniceBlue;
                dotChild = Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                );
              } else {
                dotColor = const Color(0xFFCDDFE9);
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
                                    color: InsureXColors.veniceBlue.withValues(alpha: 0.35),
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
                          height: 38,
                          color: lineColor,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage['title']!,
                            style: TextStyle(
                              color: state == 'pending'
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              fontSize: 13.5,
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
                              fontSize: 11.5,
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
    );
  }

  // ==========================================
  // 3. CLAIM DETAILS CARD
  // ==========================================
  Widget _buildClaimDetailsCard(ClaimModel claim) {
    return Container(
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
            'Claim Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Incident Type',
              claim.incidentType.isNotEmpty ? claim.incidentType : 'Windshield Damage'),
          _divider(),
          _detailRow(
            'Date of Incident',
            DateFormat('MMMM dd, yyyy · hh:mm a').format(claim.incidentDate),
          ),
          _divider(),
          _detailRow(
            'Estimated Damage',
            NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                .format(claim.estimatedLoss > 0 ? claim.estimatedLoss : 65000),
          ),
          _divider(),
          _detailRow(
            'Claim Amount',
            NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                .format(claim.claimAmount > 0 ? claim.claimAmount : 65000),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. UPLOADED EVIDENCE & DOCUMENTS SECTION
  // ==========================================
  Widget _buildUploadedDocumentsSection(
      BuildContext context, ClaimModel claim, FirestoreService fs, List<DocumentModel> docs) {
    return Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F0F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_shared_outlined,
                        size: 18, color: InsureXColors.veniceBlue),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Uploaded Evidence',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        docs.isEmpty
                            ? 'No files attached yet'
                            : '${docs.length} ${docs.length == 1 ? 'file' : 'files'} in Cloudinary',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _handleDocumentUpload(context, claim),
                icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: InsureXColors.veniceBlue),
                label: Text(
                  docs.isEmpty ? 'Upload' : 'Add More',
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
          if (docs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5EDF2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 32, color: InsureXColors.rockBlue.withValues(alpha: 0.8)),
                  const SizedBox(height: 8),
                  const Text(
                    'No documents attached yet. Upload damage photos or repair invoices.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: docs.map((doc) => _buildDocItem(context, doc)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDocItem(BuildContext context, DocumentModel doc) {
    final isImage = doc.resourceType == 'image' ||
        doc.fileName.toLowerCase().endsWith('.jpg') ||
        doc.fileName.toLowerCase().endsWith('.png') ||
        doc.fileName.toLowerCase().endsWith('.jpeg');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE2F0F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
              color: InsureXColors.veniceBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName.isNotEmpty ? doc.fileName : 'Evidence File',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      doc.fileSize?.isNotEmpty == true ? doc.fileSize! : 'Document',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Cloudinary',
                      style: TextStyle(
                        color: InsureXColors.rockBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: doc.verificationStatus == 'verified'
                  ? const Color(0xFFE6F8F0)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              doc.verificationStatus == 'verified' ? 'Verified' : 'Uploaded',
              style: TextStyle(
                color: doc.verificationStatus == 'verified'
                    ? AppColors.success
                    : const Color(0xFFD97706),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. NEXT STEP OPTION CARD
  // ==========================================
  Widget _buildNextStepCard(BuildContext context, ClaimModel claim, List<DocumentModel> docs) {
    final hasDocs = docs.isNotEmpty;
    final isSettled = claim.status == AppConstants.statusApproved ||
        claim.status == AppConstants.statusCompleted ||
        claim.currentStep >= 6;

    if (isSettled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimate Approved 🎉',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your claim has been assessed and approved. Settlement payout is in progress.',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC6E0EE), width: 1.2),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: InsureXColors.veniceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEXT STEP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    claim.currentStep >= 4 ? 'Step 4: Under Assessment' : 'Step 4: Estimate Approval',
                    style: const TextStyle(
                      color: InsureXColors.veniceBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (hasDocs && claim.currentStep < 4)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EDDA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Ready to Proceed',
                    style: TextStyle(
                      color: Color(0xFF155724),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            claim.currentStep >= 4
                ? 'Evidence Submitted for Assessment'
                : 'Submit Evidence & Proceed to Estimate Approval',
            style: const TextStyle(
              color: InsureXColors.veniceBlue,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            claim.currentStep >= 4
                ? 'Your uploaded documents are now with your claims officer. You will receive an assessment update within 24-48 hours.'
                : hasDocs
                    ? 'You have attached evidence to this claim. Tap below to submit these documents to your officer and advance to Estimate Approval.'
                    : 'Upload evidence (photos or bills) above, then submit to proceed to damage assessment.',
            style: const TextStyle(
              color: Color(0xFF335C67),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (claim.currentStep < 4)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: InsureXColors.veniceBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSubmittingNextStep
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  _isSubmittingNextStep
                      ? 'Submitting to Officer...'
                      : 'Proceed to Next Step: Estimate Approval →',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                onPressed: _isSubmittingNextStep ? null : () => _handleProceedToNextStep(context, claim),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC6E0EE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 16, color: InsureXColors.veniceBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Officer is reviewing evidence for estimate approval',
                      style: TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
  // 6. BOTTOM ACTION BUTTONS
  // ==========================================
  Widget _buildActionButtons(BuildContext context, ClaimModel claim, List<DocumentModel> docs) {
    final hasDocs = docs.isNotEmpty;
    final isAlreadyUnderReview = claim.currentStep >= 4;

    return Column(
      children: [
        if (hasDocs && !isAlreadyUnderReview) ...[
          PrimaryGradientButton(
            label: 'Proceed to Next Step →',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isSubmittingNextStep,
            onPressed: () => _handleProceedToNextStep(context, claim),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCCE3EF), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.cloud_upload_outlined, size: 18, color: InsureXColors.veniceBlue),
              label: const Text(
                'Upload Additional Documents',
                style: TextStyle(
                  color: InsureXColors.veniceBlue,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _handleDocumentUpload(context, claim),
            ),
          ),
        ] else ...[
          PrimaryGradientButton(
            label: 'Upload Documents',
            icon: Icons.cloud_upload_outlined,
            isLoading: _isUploading,
            onPressed: () => _handleDocumentUpload(context, claim),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerChatScreen(
                    claimId: claim.id,
                    officerName: claim.officerName ?? 'INSUREX Support',
                  ),
                ),
              );
            },
            child: const Text(
              'Need Help? Chat with support',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: AppColors.border, height: 1, thickness: 1);

  // ==========================================
  // PROCEED TO NEXT STEP FLOW
  // ==========================================
  Future<void> _handleProceedToNextStep(BuildContext context, ClaimModel claim) async {
    setState(() => _isSubmittingNextStep = true);
    try {
      final fs = FirestoreService();
      await fs.updateClaim(claim.id, {
        'status': AppConstants.statusUnderReview,
        'currentStep': 4,
      });

      await fs.createNotification(NotificationModel(
        id: '',
        userId: claim.userId,
        claimId: claim.id,
        title: 'Evidence Submitted for Estimate Approval',
        message:
            'Your documents for claim #${claim.claimNumber} have been submitted. Officer assessment is underway.',
        type: AppConstants.notifClaimSubmitted,
        createdAt: DateTime.now(),
      ));

      await fs.createAuditLog(AuditLogModel(
        id: '',
        userId: claim.userId,
        userName: claim.userName,
        role: AppConstants.roleCustomer,
        action: 'PROCEEDED_TO_ESTIMATE_APPROVAL',
        claimId: claim.id,
        description: 'Customer submitted evidence and proceeded to Step 4: Estimate Approval.',
        timestamp: DateTime.now(),
      ));

      _refreshClaim();

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (modalCtx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 18),
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2F0F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: InsureXColors.veniceBlue, size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Advanced to Next Step! 🎉',
                  style: TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your uploaded evidence has been submitted to your assigned claims officer. The claim has moved to Estimate Approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InsureXColors.veniceBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(modalCtx),
                    child: const Text('View Updated Timeline',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update claim: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingNextStep = false);
    }
  }

  // ==========================================
  // DOCUMENT UPLOAD BOTTOM SHEET
  // ==========================================
  Future<void> _handleDocumentUpload(BuildContext context, ClaimModel claim) async {
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
            const SizedBox(height: 18),
            const Text(
              'Upload Evidence & Documents',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload accident photos, police reports, or repair estimates to Cloudinary.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: InsureXColors.veniceBlue, size: 20),
              ),
              title: const Text('Take Photo of Damage',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _uploadFromSource(context, claim, isDocument: false, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_outlined, color: InsureXColors.veniceBlue, size: 20),
              ),
              title: const Text('Choose from Photo Gallery',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _uploadFromSource(context, claim, isDocument: false, source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.success, size: 20),
              ),
              title: const Text('Upload PDF / Document',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _uploadFromSource(context, claim, isDocument: true);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFromSource(
    BuildContext context,
    ClaimModel claim, {
    required bool isDocument,
    ImageSource source = ImageSource.gallery,
  }) async {
    setState(() => _isUploading = true);
    try {
      final cloudService = CloudinaryService();
      final uploadRes = isDocument
          ? await cloudService.pickAndUploadDocument(folder: 'insurex/documents')
          : await cloudService.pickAndUploadImage(
              source: source, folder: 'insurex/evidence');

      if (uploadRes != null && uploadRes.secureUrl.isNotEmpty) {
        final fs = FirestoreService();
        await fs.addDocument(DocumentModel(
          id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          claimId: claim.id,
          customerId: claim.userId,
          documentType: isDocument ? 'Policy/Damage Document' : 'Photo Evidence',
          fileName: uploadRes.fileName,
          fileUrl: uploadRes.secureUrl,
          fileSize: cloudService.formatBytes(uploadRes.bytes),
          cloudinaryPublicId: uploadRes.publicId,
          resourceType: uploadRes.resourceType,
          verificationStatus: 'pending',
          uploadedAt: DateTime.now(),
        ));

        _refreshClaim();

        if (context.mounted) {
          _showUploadSuccessWithNextStep(context, claim, uploadRes.fileName);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ==========================================
  // UPLOAD SUCCESS MODAL WITH NEXT STEP OPTION
  // ==========================================
  void _showUploadSuccessWithNextStep(
      BuildContext context, ClaimModel claim, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F0F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_done_rounded,
                  color: InsureXColors.veniceBlue, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Document Uploaded!',
              style: TextStyle(
                color: InsureXColors.veniceBlue,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"$fileName" was successfully uploaded to Cloudinary.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            // Primary Next Step Option
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: InsureXColors.veniceBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(
                  'Proceed to Next Step: Estimate Approval →',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.pop(modalCtx);
                  _handleProceedToNextStep(context, claim);
                },
              ),
            ),
            const SizedBox(height: 10),
            // Upload Another Document Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCCE3EF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add, size: 16, color: InsureXColors.veniceBlue),
                label: const Text(
                  'Upload Another Document',
                  style: TextStyle(
                    color: InsureXColors.veniceBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(modalCtx);
                  _handleDocumentUpload(context, claim);
                },
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(modalCtx),
              child: const Text(
                'Stay on Claim Details',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
