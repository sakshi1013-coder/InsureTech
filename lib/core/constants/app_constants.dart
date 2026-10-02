class AppConstants {
  // App Info
  static const String appName = 'InsureX';
  static const String appTagline = 'Digital Insurance Claim Management';

  // Collections
  static const String usersCollection = 'users';
  static const String policiesCollection = 'policies';
  static const String claimsCollection = 'claims';
  static const String documentsCollection = 'documents';
  static const String evidenceCollection = 'evidence';
  static const String officersCollection = 'officers';
  static const String notificationsCollection = 'notifications';
  static const String messagesCollection = 'messages';
  static const String auditLogsCollection = 'auditLogs';

  // Storage & Cloudinary Config
  static const String cloudinaryCloudName = 'd2c6a4ta';
  static const String cloudinaryApiKey = '776336881959241';
  static String cloudinaryUploadPreset = 'insurex_unsigned';
  static const String documentsPath = 'documents';
  static const String evidencePath = 'evidence';
  static const String profilesPath = 'profiles';

  // Roles
  static const String roleCustomer = 'customer';
  static const String roleOfficer = 'officer';
  static const String roleAdmin = 'admin';

  // Claim statuses (Canonical Firestore values)
  static const String statusSubmitted = 'submitted';
  static const String statusUnderVerification = 'under_verification';
  static const String statusUnderReview = 'under_review';
  static const String statusMoreInfoRequired = 'more_information_required';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';

  // Document verification statuses
  static const String docPending = 'pending';
  static const String docVerified = 'verified';
  static const String docRejected = 'rejected';
  static const String docReuploadRequired = 'reupload_required';

  // Audit Log Actions
  static const String auditClaimCreated = 'CLAIM_CREATED';
  static const String auditDocUploaded = 'DOCUMENT_UPLOADED';
  static const String auditDocVerified = 'DOCUMENT_VERIFIED';
  static const String auditDocRejected = 'DOCUMENT_REJECTED';
  static const String auditOfficerAssigned = 'OFFICER_ASSIGNED';
  static const String auditStatusChanged = 'STATUS_CHANGED';
  static const String auditClaimApproved = 'CLAIM_APPROVED';
  static const String auditClaimRejected = 'CLAIM_REJECTED';
  static const String auditInfoRequested = 'INFORMATION_REQUESTED';

  // Helper method to format status for display
  static String formatStatus(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'submitted':
        return 'Submitted';
      case 'under_verification':
        return 'Under Verification';
      case 'under_review':
        return 'Under Review';
      case 'more_information_required':
      case 'more_info_required':
        return 'More Info Required';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  // Claim types
  static const List<String> claimTypes = [
    'Vehicle Collision',
    'Windshield Damage',
    'Theft',
    'Fire Damage',
    'Natural Disaster',
    'Health Emergency',
    'Property Damage',
    'Third Party Liability',
  ];

  // Document types
  static const List<String> documentTypes = [
    'Insurance Policy',
    'Driving License',
    'Vehicle RC',
    'FIR Report',
    'Repair Estimate',
    'Medical Report',
    'Police Report',
    'Witness Statement',
    'Vehicle Photos',
    'Other',
  ];

  // Notification types
  static const String notifClaimSubmitted = 'claim_submitted';
  static const String notifOfficerAssigned = 'officer_assigned';
  static const String notifDocVerified = 'document_verified';
  static const String notifDocRejected = 'document_rejected';
  static const String notifMoreInfo = 'more_info_required';
  static const String notifStatusUpdated = 'status_updated';
  static const String notifClaimApproved = 'claim_approved';
  static const String notifClaimRejected = 'claim_rejected';

  // Allowed formats
  static const List<String> allowedDocExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const List<String> allowedEvidenceExtensions = ['jpg', 'jpeg', 'png', 'mp4'];

  // Max file sizes
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 50;
  static const int maxDocSizeMB = 15;
}

class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Customer
  static const String customerHome = '/customer/home';
  static const String customerClaims = '/customer/claims';
  static const String customerPolicies = '/customer/policies';
  static const String customerNotifications = '/customer/notifications';
  static const String customerProfile = '/customer/profile';
  static const String customerClaimDetail = '/customer/claim-detail';
  static const String customerClaimTimeline = '/customer/claim-timeline';
  static const String customerPolicyDetail = '/customer/policy-detail';
  static const String customerNewClaim = '/customer/new-claim';
  static const String customerChat = '/customer/chat';

  // Officer
  static const String officerDashboard = '/officer/dashboard';
  static const String officerProfile = '/officer/profile';
  static const String officerClaims = '/officer/claims';
  static const String officerClaimDetail = '/officer/claim-detail';
  static const String officerVerification = '/officer/verification';
  static const String officerAlerts = '/officer/alerts';
  static const String officerChat = '/officer/chat';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminClaims = '/admin/claims';
  static const String adminCustomers = '/admin/customers';
  static const String adminOfficers = '/admin/officers';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminAssignOfficer = '/admin/assign-officer';
  static const String adminNotifications = '/admin/notifications';
  static const String adminSettings = '/admin/settings';
}
