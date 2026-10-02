import 'dart:async';
import '../models/claim_model.dart';
import '../core/constants/app_constants.dart';
import 'firestore_service.dart';

/// ClaimService: Handles claim operations, workflow transitions,
/// and orchestrates audit logging and notifications.
class ClaimService {
  static final ClaimService _instance = ClaimService._internal();
  factory ClaimService() => _instance;
  ClaimService._internal();

  final FirestoreService _firestore = FirestoreService();

  /// Create a new claim
  Future<String> submitClaim({
    required ClaimModel claim,
    List<DocumentModel> documents = const [],
    List<EvidenceModel> evidenceList = const [],
  }) async {
    final claimId = await _firestore.createClaim(claim);

    // Save documents
    for (final doc in documents) {
      await _firestore.addDocument(DocumentModel(
        id: '',
        claimId: claimId,
        customerId: claim.customerId,
        documentType: doc.documentType,
        fileName: doc.fileName,
        fileUrl: doc.fileUrl,
        cloudinaryPublicId: doc.cloudinaryPublicId,
        resourceType: doc.resourceType,
        fileSize: doc.fileSize,
        verificationStatus: AppConstants.docPending,
        uploadedAt: DateTime.now(),
      ));
    }

    // Save evidence
    for (final ev in evidenceList) {
      await _firestore.addEvidence(EvidenceModel(
        id: '',
        claimId: claimId,
        customerId: claim.customerId,
        type: ev.type,
        fileName: ev.fileName,
        fileUrl: ev.fileUrl,
        cloudinaryPublicId: ev.cloudinaryPublicId,
        resourceType: ev.resourceType,
        description: ev.description,
        uploadedAt: DateTime.now(),
      ));
    }

    // Trigger notification
    await _firestore.createNotification(NotificationModel(
      id: '',
      userId: claim.userId,
      claimId: claimId,
      title: 'Claim Submitted',
      message: 'Your claim ${claim.claimNumber} has been submitted successfully and is awaiting review.',
      type: AppConstants.notifClaimSubmitted,
      createdAt: DateTime.now(),
    ));

    // Audit log
    await _firestore.createAuditLog(AuditLogModel(
      id: '',
      userId: claim.userId,
      userName: claim.userName,
      role: AppConstants.roleCustomer,
      action: AppConstants.auditClaimCreated,
      claimId: claimId,
      description: 'Customer ${claim.userName} created claim ${claim.claimNumber}',
      timestamp: DateTime.now(),
    ));

    return claimId;
  }

  /// Assign officer to claim
  Future<void> assignOfficer({
    required String claimId,
    required String officerId,
    required String officerName,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.updateClaim(claimId, {
      'officerId': officerId,
      'officerName': officerName,
      'status': AppConstants.statusUnderVerification,
      'currentStep': 2,
    });

    final claim = await _firestore.getClaimById(claimId);
    if (claim != null) {
      // Notify customer
      await _firestore.createNotification(NotificationModel(
        id: '',
        userId: claim.userId,
        claimId: claimId,
        title: 'Officer Assigned',
        message: 'Adjuster $officerName has been assigned to evaluate claim ${claim.claimNumber}.',
        type: AppConstants.notifOfficerAssigned,
        createdAt: DateTime.now(),
      ));

      // Audit log
      await _firestore.createAuditLog(AuditLogModel(
        id: '',
        userId: adminId,
        userName: adminName,
        role: AppConstants.roleAdmin,
        action: AppConstants.auditOfficerAssigned,
        claimId: claimId,
        description: 'Admin $adminName assigned adjuster $officerName to claim ${claim.claimNumber}.',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Update claim status (e.g. approved, rejected, more_information_required)
  Future<void> updateStatus({
    required String claimId,
    required String newStatus,
    required String actorId,
    required String actorName,
    required String actorRole,
    String? remarks,
    String? rejectionReason,
  }) async {
    int nextStep = 3;
    final normalized = newStatus.toLowerCase().replaceAll(' ', '_');

    if (normalized == AppConstants.statusUnderReview) {
      nextStep = 4;
    } else if (normalized == AppConstants.statusApproved) {
      nextStep = 6;
    } else if (normalized == AppConstants.statusCompleted) {
      nextStep = 7;
    } else if (normalized == AppConstants.statusRejected) {
      nextStep = 7;
    }

    final updateData = <String, dynamic>{
      'status': newStatus,
      'currentStep': nextStep,
    };

    if (remarks != null && remarks.isNotEmpty) {
      updateData['officerRemarks'] = remarks;
      updateData['additionalInfoRequest'] = remarks;
    }
    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      updateData['rejectionReason'] = rejectionReason;
    }

    await _firestore.updateClaim(claimId, updateData);

    final claim = await _firestore.getClaimById(claimId);
    if (claim != null) {
      String notifType = AppConstants.notifStatusUpdated;
      String notifTitle = 'Claim Status Updated';
      String notifMsg = 'Your claim ${claim.claimNumber} is now ${AppConstants.formatStatus(newStatus)}.';

      String auditAction = AppConstants.auditStatusChanged;

      if (normalized == AppConstants.statusApproved) {
        notifType = AppConstants.notifClaimApproved;
        notifTitle = 'Claim Approved! 🎉';
        notifMsg = 'Your claim ${claim.claimNumber} has been approved for ₹${claim.claimAmount.toStringAsFixed(0)}.';
        auditAction = AppConstants.auditClaimApproved;
      } else if (normalized == AppConstants.statusRejected) {
        notifType = AppConstants.notifClaimRejected;
        notifTitle = 'Claim Rejected';
        notifMsg = 'Your claim ${claim.claimNumber} was rejected: ${rejectionReason ?? "Does not meet criteria"}.';
        auditAction = AppConstants.auditClaimRejected;
      } else if (normalized == AppConstants.statusMoreInfoRequired) {
        notifType = AppConstants.notifMoreInfo;
        notifTitle = 'Information Requested';
        notifMsg = 'Adjuster $actorName requested additional information: ${remarks ?? "Please check remarks"}.';
        auditAction = AppConstants.auditInfoRequested;
      }

      // Notify customer
      await _firestore.createNotification(NotificationModel(
        id: '',
        userId: claim.userId,
        claimId: claimId,
        title: notifTitle,
        message: notifMsg,
        type: notifType,
        createdAt: DateTime.now(),
      ));

      // Audit log
      await _firestore.createAuditLog(AuditLogModel(
        id: '',
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: auditAction,
        claimId: claimId,
        description: '$actorRole $actorName changed status of ${claim.claimNumber} to $newStatus.',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Verify or reject a claim document
  Future<void> verifyDocument({
    required String claimId,
    required String documentId,
    required String status, // 'verified', 'rejected', 'reupload_required'
    required String officerId,
    required String officerName,
    String? note,
  }) async {
    await _firestore.updateDocument(documentId, {
      'verificationStatus': status,
      'verifiedBy': officerName,
      'verificationNote': note,
      'verifiedAt': DateTime.now(),
    });

    final claim = await _firestore.getClaimById(claimId);
    if (claim != null) {
      final isVerified = status == AppConstants.docVerified;
      final action = isVerified ? AppConstants.auditDocVerified : AppConstants.auditDocRejected;
      final notifType = isVerified ? AppConstants.notifDocVerified : AppConstants.notifDocRejected;

      await _firestore.createNotification(NotificationModel(
        id: '',
        userId: claim.userId,
        claimId: claimId,
        title: isVerified ? 'Document Verified' : 'Document Attention Needed',
        message: isVerified
            ? 'Adjuster $officerName verified your document.'
            : 'Document was marked $status: ${note ?? "Please re-upload a clear copy."}',
        type: notifType,
        createdAt: DateTime.now(),
      ));

      await _firestore.createAuditLog(AuditLogModel(
        id: '',
        userId: officerId,
        userName: officerName,
        role: AppConstants.roleOfficer,
        action: action,
        claimId: claimId,
        description: 'Officer $officerName marked document $documentId as $status.',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Streams
  Stream<List<ClaimModel>> streamClaimsForUser(String userId) => _firestore.getClaimsForUser(userId);
  Stream<List<ClaimModel>> streamAllClaims() => _firestore.getAllClaims();
  Stream<List<ClaimModel>> streamClaimsForOfficer(String officerId) => _firestore.getClaimsForOfficer(officerId);
  Stream<List<DocumentModel>> streamDocuments(String claimId) => _firestore.getDocumentsForClaim(claimId);
  Stream<List<EvidenceModel>> streamEvidence(String claimId) => _firestore.getEvidenceForClaim(claimId);
}
