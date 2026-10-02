import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:insurex_app/core/constants/app_constants.dart';
import 'package:insurex_app/firebase_options.dart';

/// Seeds realistic demo data to Firestore if not already seeded.
class DemoDataService {
  FirebaseFirestore? get _db {
    if (!DefaultFirebaseOptions.isConfigured) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isSeeded() async {
    final db = _db;
    if (db == null) return false;
    try {
      final snap = await db.collection(AppConstants.policiesCollection).limit(1).get().timeout(const Duration(seconds: 2));
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> seedAll() async {
    if (!DefaultFirebaseOptions.isConfigured) return;
    try {
      if (await isSeeded()) return;
      await _seedPolicies();
      await _seedOfficers();
    } catch (_) {}
  }

  Future<void> seedUserData(String userId, String userName) async {
    if (!DefaultFirebaseOptions.isConfigured) return;
    try {
      await _seedClaimsForUser(userId, userName);
      await _seedNotificationsForUser(userId);
      await _seedAuditLogs(userId, userName);
    } catch (_) {}
  }

  Future<void> _seedPolicies() async {
    final db = _db;
    if (db == null) return;

    final policies = [
      {
        'policyNumber': 'POL-HOME-4412',
        'policyName': 'Home Protection Plus',
        'policyType': 'home',
        'coverageDetails': 'Comprehensive Dwelling & Property Protection',
        'totalCoverage': 550000.0,
        'deductible': 1000.0,
        'annualPremium': 81.67 * 12,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 120))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 245))),
        'status': 'Active',
        'vehicleModel': '',
        'vehicleLicense': '',
        'vehicleVin': '',
        'tier': 'Gold',
        'isActive': true,
        'userId': 'DEMO',
      },
      {
        'policyNumber': 'POL-AUTO-8821',
        'policyName': 'Comprehensive Auto Cover',
        'policyType': 'auto',
        'coverageDetails': 'Collision, Comprehensive, Third-party Liability',
        'totalCoverage': 75000.0,
        'deductible': 500.0,
        'annualPremium': 118.33 * 12,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 90))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 275))),
        'status': 'Active',
        'vehicleModel': '2023 Tesla Model 3',
        'vehicleLicense': 'CA 7XYZ',
        'vehicleVin': '5YJ3E1EB9PF',
        'tier': 'Platinum',
        'isActive': true,
        'userId': 'DEMO',
      },
      {
        'policyNumber': 'POL-HEALTH-2307',
        'policyName': 'Family Health Shield',
        'policyType': 'health',
        'coverageDetails': 'Inpatient Hospitalization, Pre-Post & Daycare',
        'totalCoverage': 1000000.0,
        'deductible': 250.0,
        'annualPremium': 1250.0 * 12,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 305))),
        'status': 'Active',
        'vehicleModel': '',
        'vehicleLicense': '',
        'vehicleVin': '',
        'tier': 'Platinum',
        'isActive': true,
        'userId': 'DEMO',
      },
      {
        'policyNumber': 'POL-TRAVEL-5198',
        'policyName': 'Travel Secure',
        'policyType': 'travel',
        'coverageDetails': 'Worldwide Emergency Medical & Trip Cancellation',
        'totalCoverage': 500000.0,
        'deductible': 100.0,
        'annualPremium': 450.0 * 12,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 335))),
        'status': 'Active',
        'vehicleModel': '',
        'vehicleLicense': '',
        'vehicleVin': '',
        'tier': 'Gold',
        'isActive': true,
        'userId': 'DEMO',
      },
      {
        'policyNumber': 'POL-PA-6734',
        'policyName': 'Personal Accident Protect',
        'policyType': 'accident',
        'coverageDetails': 'Accidental Death & Permanent Total Disability Cover',
        'totalCoverage': 750000.0,
        'deductible': 0.0,
        'annualPremium': 325.0 * 12,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 320))),
        'status': 'Active',
        'vehicleModel': '',
        'vehicleLicense': '',
        'vehicleVin': '',
        'tier': 'Silver',
        'isActive': true,
        'userId': 'DEMO',
      },
      {
        'policyNumber': 'POL-HOME-3381',
        'policyName': 'Old Home Protection',
        'policyType': 'home',
        'coverageDetails': 'Dwelling & Natural Hazard Basic Protection',
        'totalCoverage': 350000.0,
        'deductible': 1500.0,
        'annualPremium': 106.67 * 12,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 400))),
        'endDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 35))),
        'status': 'Expired',
        'vehicleModel': '',
        'vehicleLicense': '',
        'vehicleVin': '',
        'tier': 'Silver',
        'isActive': false,
        'userId': 'DEMO',
      },
    ];

    for (final p in policies) {
      await db.collection(AppConstants.policiesCollection).add(p);
    }
  }

  Future<void> _seedOfficers() async {
    final db = _db;
    if (db == null) return;

    final officers = [
      {
        'userId': 'officer_demo_1',
        'name': 'Marcus Vance',
        'email': 'marcus.vance@insurex.com',
        'employeeId': 'OFF-4491',
        'department': 'Auto & Casualty Desk',
        'designation': 'Senior Field Adjuster',
        'phone': '+1-555-0147',
        'currentWorkload': 24,
        'pendingClaims': 8,
        'isAvailable': true,
        'isOnDuty': true,
        'specialty': 'Auto Claims · Vehicle Collision',
        'joinedAt': Timestamp.fromDate(DateTime(2020, 6, 15)),
      },
      {
        'userId': 'officer_demo_2',
        'name': 'Priya Mehta',
        'email': 'priya.mehta@insurex.com',
        'employeeId': 'OFF-3312',
        'department': 'Health & Life Desk',
        'designation': 'Claims Analyst',
        'phone': '+1-555-0289',
        'currentWorkload': 18,
        'pendingClaims': 5,
        'isAvailable': true,
        'isOnDuty': true,
        'specialty': 'Health · Accident Claims',
        'joinedAt': Timestamp.fromDate(DateTime(2021, 3, 10)),
      },
    ];

    for (final o in officers) {
      await db.collection(AppConstants.officersCollection).add(o);
    }
  }

  Future<void> _seedClaimsForUser(String userId, String userName) async {
    final db = _db;
    if (db == null) return;

    // Check if user already has claims
    final existing = await db.collection(AppConstants.claimsCollection).where('userId', isEqualTo: userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    // Get a policy for this user (DEMO shared)
    final policiesSnap = await db.collection(AppConstants.policiesCollection).limit(1).get();
    final policyId = policiesSnap.docs.isNotEmpty ? policiesSnap.docs.first.id : '';
    final policyNumber = policiesSnap.docs.isNotEmpty ? (policiesSnap.docs.first.data()['policyNumber'] ?? 'IX-992014') : 'IX-992014';

    // Get officer
    final officersSnap = await db.collection(AppConstants.officersCollection).limit(1).get();
    final officerId = officersSnap.docs.isNotEmpty ? officersSnap.docs.first.id : null;
    final officerName = officersSnap.docs.isNotEmpty ? (officersSnap.docs.first.data()['name'] ?? 'Marcus Vance') : null;

    final claims = [
      {
        'claimNumber': 'CLM-2024-8841',
        'userId': userId,
        'userEmail': '',
        'userName': userName,
        'policyId': policyId,
        'policyNumber': policyNumber,
        'officerId': officerId,
        'officerName': officerName,
        'claimType': 'Vehicle Collision',
        'incidentDate': Timestamp.fromDate(DateTime(2024, 10, 24)),
        'incidentLocation': 'I-80, Exit 428, San Francisco, CA',
        'description': 'Multi-car impact on I-80. Front bumper and sensor collision damage reported. Vehicle towed to Bay Area Repair Center #402.',
        'estimatedDamage': 4250.0,
        'claimAmount': 4250.0,
        'reservedValue': 5000.0,
        'status': AppConstants.statusUnderVerification,
        'priority': 'Critical',
        'createdAt': Timestamp.fromDate(DateTime(2024, 10, 24, 17, 30)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 10, 26, 9, 0)),
        'rejectionReason': null,
        'additionalInfoRequest': null,
        'timeline': [],
        'currentStep': 4,
        'totalSteps': 7,
        'isFnolSubmitted': true,
      },
      {
        'claimNumber': 'CLM-2024-1102',
        'userId': userId,
        'userEmail': '',
        'userName': userName,
        'policyId': policyId,
        'policyNumber': policyNumber,
        'officerId': null,
        'officerName': null,
        'claimType': 'Windshield Damage',
        'incidentDate': Timestamp.fromDate(DateTime(2024, 8, 29)),
        'incidentLocation': 'Safelite AutoGlass, San Jose',
        'description': 'Windshield crack from road debris. Safelite repair completed.',
        'estimatedDamage': 650.0,
        'claimAmount': 650.0,
        'reservedValue': 650.0,
        'status': AppConstants.statusApproved,
        'priority': 'Low',
        'createdAt': Timestamp.fromDate(DateTime(2024, 8, 29, 10, 0)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 9, 5, 14, 0)),
        'rejectionReason': null,
        'additionalInfoRequest': null,
        'timeline': [],
        'currentStep': 7,
        'totalSteps': 7,
        'isFnolSubmitted': true,
      },
    ];

    for (final c in claims) {
      await db.collection(AppConstants.claimsCollection).add(c);
    }
  }

  Future<void> _seedNotificationsForUser(String userId) async {
    final db = _db;
    if (db == null) return;

    final existing = await db.collection(AppConstants.notificationsCollection).where('userId', isEqualTo: userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final notifications = [
      {
        'userId': userId,
        'claimId': null,
        'title': 'Claim Submitted Successfully',
        'message': 'Your claim CLM-2024-8841 has been submitted and is under verification.',
        'type': AppConstants.notifClaimSubmitted,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 10, 24, 17, 35)),
      },
      {
        'userId': userId,
        'claimId': null,
        'title': 'Officer Assigned',
        'message': 'Officer Marcus Vance (Badge #OFF-4491) has been assigned to your claim CLM-2024-8841.',
        'type': AppConstants.notifOfficerAssigned,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 10, 25, 9, 20)),
      },
      {
        'userId': userId,
        'claimId': null,
        'title': 'Document Verified',
        'message': 'Your Police FIR document has been officially verified and signed.',
        'type': AppConstants.notifDocVerified,
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 10, 25, 14, 18)),
      },
      {
        'userId': userId,
        'claimId': null,
        'title': 'Claim CLM-2024-1102 Approved & Paid',
        'message': 'Your windshield damage claim of ₹650.00 has been approved. Payment disbursed.',
        'type': AppConstants.notifClaimApproved,
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 9, 5, 14, 5)),
      },
    ];

    for (final n in notifications) {
      await db.collection(AppConstants.notificationsCollection).add(n);
    }
  }

  Future<void> _seedAuditLogs(String userId, String userName) async {
    final db = _db;
    if (db == null) return;

    final existing = await db.collection(AppConstants.auditLogsCollection).where('userId', isEqualTo: userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final logs = [
      {
        'userId': userId,
        'userName': userName,
        'role': AppConstants.roleCustomer,
        'action': 'claim_submitted',
        'claimId': null,
        'description': 'Customer submitted FNOL for CLM-2024-8841 via mobile app.',
        'timestamp': Timestamp.fromDate(DateTime(2024, 10, 24, 17, 30)),
      },
      {
        'userId': 'system',
        'userName': 'System',
        'role': 'system',
        'action': 'officer_assigned',
        'claimId': null,
        'description': 'Officer Marcus Vance (OFF-4491) assigned to CLM-2024-8841 by Admin.',
        'timestamp': Timestamp.fromDate(DateTime(2024, 10, 25, 9, 15)),
      },
      {
        'userId': 'officer_demo_1',
        'userName': 'Marcus Vance',
        'role': AppConstants.roleOfficer,
        'action': 'document_verified',
        'claimId': null,
        'description': 'Officer Marcus Vance reviewed repair estimate for CLM-2024-8841.',
        'timestamp': Timestamp.fromDate(DateTime(2024, 10, 26, 9, 0)),
      },
      {
        'userId': 'system',
        'userName': 'DocuScan AI',
        'role': 'system',
        'action': 'document_verified',
        'claimId': null,
        'description': 'Police FIR document officially verified and validated by DocuScan AI.',
        'timestamp': Timestamp.fromDate(DateTime(2024, 10, 25, 16, 18)),
      },
    ];

    for (final l in logs) {
      await db.collection(AppConstants.auditLogsCollection).add(l);
    }
  }
}
