import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/claim_model.dart';
import '../models/policy_model.dart';
import '../core/constants/app_constants.dart';

/// Central Firestore Service managing real-time and one-time interactions
/// with Firestore collections:
/// users, policies, claims, documents, evidence, officers, notifications, messages, auditLogs
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Reactive in-memory state mirrors screenshot and live data
  static final List<ClaimModel> _claims = _initMockClaims();
  static final List<DocumentModel> _documents = _initMockDocuments();
  static final List<EvidenceModel> _evidence = _initMockEvidence();
  static final List<PolicyModel> _policies = _initMockPolicies();
  static final List<OfficerModel> _officers = _initMockOfficers();
  static final List<NotificationModel> _notifications = _initMockNotifications();
  static final List<AuditLogModel> _auditLogs = _initMockAuditLogs();
  static final List<MessageModel> _messages = _initMockMessages();

  static final _claimsStream = StreamController<List<ClaimModel>>.broadcast();
  static final _docsStream = StreamController<List<DocumentModel>>.broadcast();
  static final _evidenceStream = StreamController<List<EvidenceModel>>.broadcast();
  static final _policiesStream = StreamController<List<PolicyModel>>.broadcast();
  static final _officersStream = StreamController<List<OfficerModel>>.broadcast();
  static final _notificationsStream = StreamController<List<NotificationModel>>.broadcast();
  static final _auditStream = StreamController<List<AuditLogModel>>.broadcast();
  static final _messagesStream = StreamController<List<MessageModel>>.broadcast();

  // ===================== CLAIMS =====================

  Future<String> createClaim(ClaimModel claim) async {
    final claimId = 'clm_${DateTime.now().millisecondsSinceEpoch}';
    final newClaim = ClaimModel(
      id: claimId,
      claimNumber: claim.claimNumber,
      userId: claim.userId,
      userEmail: claim.userEmail,
      userName: claim.userName,
      policyId: claim.policyId,
      policyNumber: claim.policyNumber,
      claimType: claim.claimType,
      incidentDate: claim.incidentDate,
      incidentLocation: claim.incidentLocation,
      description: claim.description,
      estimatedDamage: claim.estimatedDamage,
      claimAmount: claim.claimAmount,
      reservedValue: claim.claimAmount * 1.1,
      status: AppConstants.statusSubmitted,
      priority: claim.priority,
      officerId: claim.officerId ?? 'OFF-4491',
      officerName: claim.officerName ?? 'Marcus Vance',
      currentStep: 1,
      totalSteps: 7,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      timeline: [
        'FNOL Submitted - ${DateTime.now().toString().substring(0, 16)}',
      ],
    );

    _claims.insert(0, newClaim);
    _claimsStream.add(List.from(_claims));

    // Persist to real Firestore
    if (_db != null) {
      try {
        await _db!
            .collection(AppConstants.claimsCollection)
            .doc(claimId)
            .set(newClaim.toMap());
      } catch (e) {
        debugPrint('Firestore createClaim error: $e');
      }
    }

    return claimId;
  }

  Stream<List<ClaimModel>> getClaimsForUser(String userId) {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.claimsCollection)
            .where('userId', isEqualTo: userId)
            .snapshots()
            .map((snap) {
              final list = snap.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList();
              list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return list;
            })
            .handleError((e) {
              debugPrint('Firestore claims stream fallback: $e');
              final list = _claims.where((c) => c.userId == userId || c.userId == 'usr_customer_demo').toList();
              list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return list;
            });
      } catch (_) {}
    }

    return _claimsStream.stream.map((list) {
      final filtered = list.where((c) => c.userId == userId || c.userId == 'usr_customer_demo').toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }).asBroadcastStream(onListen: (sub) {
      _claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _claimsStream.add(List.from(_claims));
    });
  }

  Stream<List<ClaimModel>> getAllClaims() {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.claimsCollection)
            .snapshots()
            .map((snap) {
              final list = snap.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList();
              list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return list;
            })
            .handleError((e) {
              debugPrint('Firestore all claims stream fallback: $e');
              final list = List<ClaimModel>.from(_claims);
              list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return list;
            });
      } catch (_) {}
    }

    return _claimsStream.stream.map((list) {
      final copy = List<ClaimModel>.from(list);
      copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return copy;
    }).asBroadcastStream(onListen: (sub) {
      _claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _claimsStream.add(List.from(_claims));
    });
  }

  Stream<List<ClaimModel>> getClaimsForOfficer(String officerId) {
    return _claimsStream.stream.map((list) {
      final filtered = list.where((c) => c.officerId == officerId || officerId.isEmpty || c.officerId == 'OFF-4491').toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }).asBroadcastStream(onListen: (sub) {
      _claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _claimsStream.add(List.from(_claims));
    });
  }

  Future<ClaimModel?> getClaimById(String claimId) async {
    if (_db != null) {
      try {
        final doc = await _db!.collection(AppConstants.claimsCollection).doc(claimId).get();
        if (doc.exists && doc.data() != null) {
          return ClaimModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }
    return _claims.cast<ClaimModel?>().firstWhere(
      (c) => c?.id == claimId || c?.claimNumber == claimId,
      orElse: () => _claims.isNotEmpty ? _claims.first : null,
    );
  }

  Future<void> updateClaim(String claimId, Map<String, dynamic> data) async {
    final idx = _claims.indexWhere((c) => c.id == claimId || c.claimNumber == claimId);
    if (idx != -1) {
      final current = _claims[idx];
      _claims[idx] = ClaimModel(
        id: current.id,
        claimNumber: current.claimNumber,
        userId: current.userId,
        userEmail: current.userEmail,
        userName: current.userName,
        policyId: current.policyId,
        policyNumber: current.policyNumber,
        claimType: current.claimType,
        incidentDate: current.incidentDate,
        incidentLocation: current.incidentLocation,
        description: current.description,
        estimatedDamage: current.estimatedDamage,
        claimAmount: current.claimAmount,
        reservedValue: current.reservedValue,
        status: data['status'] as String? ?? current.status,
        priority: data['priority'] as String? ?? current.priority,
        officerId: data['officerId'] as String? ?? current.officerId,
        officerName: data['officerName'] as String? ?? current.officerName,
        currentStep: data['currentStep'] as int? ?? current.currentStep,
        totalSteps: current.totalSteps,
        additionalInfoRequest: data['officerRemarks'] as String? ?? data['additionalInfoRequest'] as String? ?? current.additionalInfoRequest,
        rejectionReason: data['rejectionReason'] as String? ?? current.rejectionReason,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
      _claimsStream.add(List.from(_claims));
    }
    if (_db != null) {
      try {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _db!.collection(AppConstants.claimsCollection).doc(claimId).update(data);
      } catch (e) {
        debugPrint('Firestore updateClaim notice: $e');
      }
    }
  }

  // ===================== DOCUMENTS =====================

  Future<String> addDocument(DocumentModel doc) async {
    final id = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final newDoc = DocumentModel(
      id: id,
      claimId: doc.claimId,
      customerId: doc.customerId,
      documentType: doc.documentType,
      fileUrl: doc.fileUrl,
      fileName: doc.fileName,
      fileSize: doc.fileSize,
      cloudinaryPublicId: doc.cloudinaryPublicId,
      resourceType: doc.resourceType,
      verificationStatus: doc.verificationStatus,
      uploadedAt: DateTime.now(),
    );
    _documents.add(newDoc);
    _docsStream.add(List.from(_documents));

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.documentsCollection).doc(id).set(newDoc.toMap());
      } catch (e) {
        debugPrint('Firestore addDocument: $e');
      }
    }
    return id;
  }

  Future<String> addDocumentToClaim(DocumentModel doc) => addDocument(doc);

  Stream<List<DocumentModel>> getDocumentsForClaim(String claimId) {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.documentsCollection)
            .where('claimId', isEqualTo: claimId)
            .snapshots()
            .map((snap) => snap.docs.map((d) => DocumentModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => _documents.where((d) => d.claimId == claimId || d.claimId == 'CLM-2024-8841').toList());
      } catch (_) {}
    }

    return _docsStream.stream.map((list) {
      return list.where((d) => d.claimId == claimId || d.claimId == 'CLM-2024-8841').toList();
    }).asBroadcastStream(onListen: (sub) {
      _docsStream.add(List.from(_documents));
    });
  }

  Future<void> updateDocument(String docId, Map<String, dynamic> data) async {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx != -1) {
      final cur = _documents[idx];
      _documents[idx] = DocumentModel(
        id: cur.id,
        claimId: cur.claimId,
        customerId: cur.customerId,
        documentType: cur.documentType,
        fileUrl: cur.fileUrl,
        fileName: cur.fileName,
        fileSize: cur.fileSize,
        cloudinaryPublicId: cur.cloudinaryPublicId,
        resourceType: cur.resourceType,
        verificationStatus: data['verificationStatus'] as String? ?? data['status'] as String? ?? cur.verificationStatus,
        verificationNote: data['verificationNote'] as String? ?? cur.verificationNote,
        verifiedBy: data['verifiedBy'] as String? ?? cur.verifiedBy,
        verifiedAt: DateTime.now(),
        uploadedAt: cur.uploadedAt,
      );
      _docsStream.add(List.from(_documents));
    }

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.documentsCollection).doc(docId).update(data);
      } catch (_) {}
    }
  }

  // ===================== EVIDENCE =====================

  Future<String> addEvidence(EvidenceModel evidence) async {
    final id = 'ev_${DateTime.now().millisecondsSinceEpoch}';
    final newEv = EvidenceModel(
      id: id,
      claimId: evidence.claimId,
      customerId: evidence.customerId,
      type: evidence.type,
      fileName: evidence.fileName,
      fileUrl: evidence.fileUrl,
      cloudinaryPublicId: evidence.cloudinaryPublicId,
      resourceType: evidence.resourceType,
      description: evidence.description,
      uploadedAt: DateTime.now(),
      thumbnailUrl: evidence.thumbnailUrl,
    );
    _evidence.add(newEv);
    _evidenceStream.add(List.from(_evidence));

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.evidenceCollection).doc(id).set(newEv.toMap());
      } catch (e) {
        debugPrint('Firestore addEvidence: $e');
      }
    }
    return id;
  }

  Stream<List<EvidenceModel>> getEvidenceForClaim(String claimId) {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.evidenceCollection)
            .where('claimId', isEqualTo: claimId)
            .snapshots()
            .map((snap) => snap.docs.map((d) => EvidenceModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => _evidence);
      } catch (_) {}
    }

    return _evidenceStream.stream.asBroadcastStream(onListen: (sub) {
      _evidenceStream.add(List.from(_evidence));
    });
  }

  // ===================== NOTIFICATIONS =====================

  Future<void> createNotification(NotificationModel notif) async {
    final id = notif.id.isNotEmpty ? notif.id : 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final savedNotif = NotificationModel(
      id: id,
      userId: notif.userId,
      claimId: notif.claimId,
      title: notif.title,
      message: notif.message,
      type: notif.type,
      isRead: notif.isRead,
      createdAt: notif.createdAt,
    );

    _notifications.insert(0, savedNotif);
    _notificationsStream.add(List.from(_notifications));

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.notificationsCollection).doc(id).set(savedNotif.toMap());
      } catch (e) {
        debugPrint('Firestore createNotification: $e');
      }
    }
  }

  Stream<List<NotificationModel>> getNotificationsForUser(String userId) {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .snapshots()
            .map((snap) => snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => _notifications);
      } catch (_) {}
    }

    return _notificationsStream.stream.asBroadcastStream(onListen: (sub) {
      _notificationsStream.add(List.from(_notifications));
    });
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return getNotificationsForUser(userId).map((list) => list.where((n) => !n.isRead).length);
  }

  Future<void> markNotificationRead(String notifId) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx != -1) {
      final cur = _notifications[idx];
      _notifications[idx] = NotificationModel(
        id: cur.id,
        userId: cur.userId,
        claimId: cur.claimId,
        title: cur.title,
        message: cur.message,
        type: cur.type,
        isRead: true,
        createdAt: cur.createdAt,
      );
      _notificationsStream.add(List.from(_notifications));
    }

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.notificationsCollection).doc(notifId).update({'isRead': true});
      } catch (_) {}
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      final cur = _notifications[i];
      _notifications[i] = NotificationModel(
        id: cur.id,
        userId: cur.userId,
        claimId: cur.claimId,
        title: cur.title,
        message: cur.message,
        type: cur.type,
        isRead: true,
        createdAt: cur.createdAt,
      );
    }
    _notificationsStream.add(List.from(_notifications));
  }

  // ===================== MESSAGES (CHAT) =====================

  Future<void> sendMessage(MessageModel msg) async {
    final id = msg.id.isNotEmpty ? msg.id : 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final savedMsg = MessageModel(
      id: id,
      claimId: msg.claimId,
      senderId: msg.senderId,
      senderRole: msg.senderRole,
      receiverId: msg.receiverId,
      message: msg.message,
      attachmentUrl: msg.attachmentUrl,
      createdAt: DateTime.now(),
      senderName: msg.senderName,
      isRead: false,
    );

    _messages.add(savedMsg);
    _messagesStream.add(List.from(_messages));

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.messagesCollection).doc(id).set(savedMsg.toMap());
      } catch (e) {
        debugPrint('Firestore sendMessage: $e');
      }
    }
  }

  Stream<List<MessageModel>> getMessagesForClaim(String claimId) {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.messagesCollection)
            .where('claimId', isEqualTo: claimId)
            .snapshots()
            .map((snap) => snap.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => _messages.where((m) => m.claimId == claimId || claimId.isEmpty).toList());
      } catch (_) {}
    }

    return _messagesStream.stream.map((list) {
      return list.where((m) => m.claimId == claimId || claimId.isEmpty).toList();
    }).asBroadcastStream(onListen: (sub) {
      _messagesStream.add(List.from(_messages));
    });
  }

  // ===================== AUDIT LOGS =====================

  Future<void> createAuditLog(AuditLogModel log) async {
    final id = log.id.isNotEmpty ? log.id : 'log_${DateTime.now().millisecondsSinceEpoch}';
    final savedLog = AuditLogModel(
      id: id,
      userId: log.userId,
      userName: log.userName,
      role: log.role,
      action: log.action,
      claimId: log.claimId,
      description: log.description,
      timestamp: log.timestamp,
    );

    _auditLogs.insert(0, savedLog);
    _auditStream.add(List.from(_auditLogs));

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.auditLogsCollection).doc(id).set(savedLog.toMap());
      } catch (e) {
        debugPrint('Firestore createAuditLog: $e');
      }
    }
  }

  Stream<List<AuditLogModel>> getAuditLogs({String? claimId}) {
    if (_db != null) {
      try {
        final collection = _db!.collection(AppConstants.auditLogsCollection);
        if (claimId != null && claimId.isNotEmpty) {
          return collection
              .where('claimId', isEqualTo: claimId)
              .snapshots()
              .map((snap) => snap.docs.map((d) => AuditLogModel.fromMap(d.data(), d.id)).toList())
              .handleError((_) => _auditLogs.where((l) => l.claimId == claimId || claimId.isEmpty).toList());
        }
        return collection
            .snapshots()
            .map((snap) => snap.docs.map((d) => AuditLogModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => _auditLogs);
      } catch (_) {}
    }

    return _auditStream.stream.map((list) {
      if (claimId != null && claimId.isNotEmpty) {
        return list.where((l) => l.claimId == claimId || l.claimId == 'clm_8841_demo').toList();
      }
      return list;
    }).asBroadcastStream(onListen: (sub) {
      _auditStream.add(List.from(_auditLogs));
    });
  }

  // ===================== POLICIES =====================

  Future<String> createPolicy(PolicyModel policy) async {
    final id = policy.id.isNotEmpty ? policy.id : 'pol_${DateTime.now().millisecondsSinceEpoch}';
    final newPolicy = PolicyModel(
      id: id,
      userId: policy.userId,
      policyNumber: policy.policyNumber.isNotEmpty
          ? policy.policyNumber
          : 'POL-${policy.policyType.toUpperCase().substring(0, policy.policyType.length > 4 ? 4 : policy.policyType.length)}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      policyName: policy.policyName,
      policyType: policy.policyType,
      coverageDetails: policy.coverageDetails,
      totalCoverage: policy.totalCoverage,
      deductible: policy.deductible,
      annualPremium: policy.annualPremium,
      startDate: policy.startDate,
      endDate: policy.endDate,
      status: policy.status,
      vehicleModel: policy.vehicleModel,
      vehicleLicense: policy.vehicleLicense,
      vehicleVin: policy.vehicleVin,
      tier: policy.tier,
      isActive: policy.isActive,
    );

    _policies.insert(0, newPolicy);
    _policiesStream.add(List.from(_policies));

    if (_db != null) {
      try {
        await _db!.collection(AppConstants.policiesCollection).doc(id).set(newPolicy.toMap());
      } catch (e) {
        debugPrint('Firestore createPolicy error: $e');
      }
    }
    return id;
  }

  Stream<List<PolicyModel>> getAllPolicies() {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.policiesCollection)
            .snapshots()
            .map((snap) {
              final list = snap.docs.map((d) => PolicyModel.fromMap(d.data(), d.id)).toList();
              // Merge with in-memory policies if any missing
              for (final p in _policies) {
                if (!list.any((item) => item.id == p.id || item.policyNumber == p.policyNumber)) {
                  list.add(p);
                }
              }
              return list.isNotEmpty ? list : _policies;
            })
            .handleError((_) => _policies);
      } catch (_) {}
    }

    return _policiesStream.stream.asBroadcastStream(onListen: (sub) {
      _policiesStream.add(List.from(_policies));
    });
  }

  Stream<List<PolicyModel>> getPoliciesForUser(String userId) {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.policiesCollection)
            .snapshots()
            .map((snap) {
              final allDocs = snap.docs.map((d) => PolicyModel.fromMap(d.data(), d.id)).toList();
              final userPolicies = allDocs.where((p) =>
                p.userId == userId ||
                p.customerId == userId ||
                p.userId == 'DEMO' ||
                p.userId == 'usr_customer_demo' ||
                p.userId.isEmpty
              ).toList();

              // Merge any created in-memory policies
              for (final p in _policies) {
                if (p.userId == userId || p.userId == 'DEMO' || p.userId == 'usr_customer_demo') {
                  if (!userPolicies.any((up) => up.id == p.id || up.policyNumber == p.policyNumber)) {
                    userPolicies.insert(0, p);
                  }
                }
              }

              if (userPolicies.isEmpty) {
                return _policies;
              }
              return userPolicies;
            })
            .handleError((_) => _policies);
      } catch (_) {}
    }

    return _policiesStream.stream.map((list) {
      final userPolicies = list.where((p) =>
        p.userId == userId ||
        p.customerId == userId ||
        p.userId == 'usr_customer_demo' ||
        p.userId == 'DEMO'
      ).toList();
      return userPolicies.isNotEmpty ? userPolicies : _policies;
    }).asBroadcastStream(onListen: (sub) {
      _policiesStream.add(List.from(_policies));
    });
  }

  Future<PolicyModel?> getPolicyById(String policyId) async {
    if (_db != null) {
      try {
        final doc = await _db!.collection(AppConstants.policiesCollection).doc(policyId).get();
        if (doc.exists && doc.data() != null) {
          return PolicyModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }
    return _policies.cast<PolicyModel?>().firstWhere(
      (p) => p?.id == policyId || p?.policyNumber == policyId,
      orElse: () => _policies.isNotEmpty ? _policies.first : null,
    );
  }

  // ===================== USERS & OFFICERS =====================

  Future<UserModel?> getUserById(String userId) async {
    if (_db != null) {
      try {
        final doc = await _db!.collection(AppConstants.usersCollection).doc(userId).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<UserModel>> getAllCustomers() async {
    if (_db != null) {
      try {
        final snap = await _db!
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.roleCustomer)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
        }
      } catch (_) {}
    }
    return [
      UserModel(
        id: 'usr_customer_demo',
        name: 'Alexander Wright',
        email: 'customer@insurex.com',
        phone: '+1 (555) 382-9912',
        role: AppConstants.roleCustomer,
        createdAt: DateTime(2024, 1, 15),
      ),
    ];
  }

  Stream<List<UserModel>> getCustomers() {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.roleCustomer)
            .snapshots()
            .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => [
                  UserModel(
                    id: 'usr_customer_demo',
                    name: 'Alexander Wright',
                    email: 'customer@insurex.com',
                    phone: '+1 (555) 382-9912',
                    role: AppConstants.roleCustomer,
                    createdAt: DateTime(2024, 1, 15),
                  ),
                ]);
      } catch (_) {}
    }
    return Stream.value([
      UserModel(
        id: 'usr_customer_demo',
        name: 'Alexander Wright',
        email: 'customer@insurex.com',
        phone: '+1 (555) 382-9912',
        role: AppConstants.roleCustomer,
        createdAt: DateTime(2024, 1, 15),
      ),
    ]);
  }

  Stream<List<OfficerModel>> getOfficers() => getAllOfficers();

  Stream<List<OfficerModel>> getAllOfficers() {
    if (_db != null) {
      try {
        return _db!
            .collection(AppConstants.officersCollection)
            .snapshots()
            .map((snap) => snap.docs.map((d) => OfficerModel.fromMap(d.data(), d.id)).toList())
            .handleError((_) => _officers);
      } catch (_) {}
    }

    return _officersStream.stream.asBroadcastStream(onListen: (sub) {
      _officersStream.add(List.from(_officers));
    });
  }

  Future<OfficerModel?> getOfficerByUserId(String userId) async {
    return _officers.cast<OfficerModel?>().firstWhere(
      (o) => o?.userId == userId,
      orElse: () => _officers.first,
    );
  }

  Future<void> updateOfficerWorkload(String officerId, int delta) async {
    final idx = _officers.indexWhere((o) => o.id == officerId || o.employeeId == officerId);
    if (idx != -1) {
      final o = _officers[idx];
      _officers[idx] = OfficerModel(
        id: o.id,
        userId: o.userId,
        name: o.name,
        email: o.email,
        employeeId: o.employeeId,
        department: o.department,
        designation: o.designation,
        phone: o.phone,
        currentWorkload: (o.currentWorkload + delta).clamp(0, 999),
        pendingClaims: (o.pendingClaims + delta).clamp(0, 999),
        isAvailable: o.isAvailable,
        isOnDuty: o.isOnDuty,
        specialty: o.specialty,
        joinedAt: o.joinedAt,
      );
      _officersStream.add(List.from(_officers));
    }
    if (_db != null) {
      try {
        await _db!.collection(AppConstants.officersCollection).doc(officerId).update({
          'currentWorkload': FieldValue.increment(delta),
          'pendingClaims': FieldValue.increment(delta),
        });
      } catch (_) {}
    }
  }

  // ===================== MOCK DATA INITIALIZATION =====================

  static List<ClaimModel> _initMockClaims() {
    return [
      ClaimModel(
        id: 'clm_8841_demo',
        claimNumber: 'CLM-2024-8841',
        userId: 'usr_customer_demo',
        userEmail: 'alex.wright@insurex.com',
        userName: 'Alexander Wright',
        policyId: 'POL-AUTO-8821',
        policyNumber: 'POL-AUTO-8821',
        officerId: 'OFF-4491',
        officerName: 'Marcus Vance',
        claimType: 'Vehicle Collision',
        incidentDate: DateTime(2024, 10, 24, 14, 30),
        incidentLocation: 'Intersection of 5th Ave & Pine St, Seattle, WA',
        description: 'Rear-ended at traffic signal by commercial van. Front bumper, grille, and right headlight assembly severely damaged.',
        estimatedDamage: 4500.0,
        claimAmount: 4200.0,
        reservedValue: 4800.0,
        status: AppConstants.statusUnderVerification,
        priority: 'High',
        createdAt: DateTime(2024, 10, 24, 15, 45),
        updatedAt: DateTime(2024, 10, 24, 16, 20),
        currentStep: 3,
        totalSteps: 7,
        timeline: [
          'FNOL Submitted - Oct 24, 2024 15:45',
          'Assigned to Field Adjuster Marcus Vance - Oct 24, 2024 16:00',
          'Documents Under Verification - Oct 24, 2024 16:20',
        ],
      ),
      ClaimModel(
        id: 'clm_9210_demo',
        claimNumber: 'CLM-2024-9210',
        userId: 'usr_customer_demo',
        userEmail: 'alex.wright@insurex.com',
        userName: 'Alexander Wright',
        policyId: 'POL-HOME-4412',
        policyNumber: 'POL-HOME-4412',
        officerId: 'OFF-4491',
        officerName: 'Marcus Vance',
        claimType: 'Property Damage',
        incidentDate: DateTime(2024, 9, 12),
        incidentLocation: '1420 Evergreen Terrace, Seattle, WA',
        description: 'Windstorm caused large tree limb to damage roof shingles and guttering.',
        estimatedDamage: 2200.0,
        claimAmount: 1850.0,
        reservedValue: 2200.0,
        status: AppConstants.statusApproved,
        priority: 'Medium',
        createdAt: DateTime(2024, 9, 12, 11, 0),
        updatedAt: DateTime(2024, 9, 15, 14, 0),
        currentStep: 6,
        totalSteps: 7,
      ),
      ClaimModel(
        id: 'clm_7102_demo',
        claimNumber: 'CLM-2024-7102',
        userId: 'usr_customer_demo',
        userEmail: 'alex.wright@insurex.com',
        userName: 'Alexander Wright',
        policyId: 'POL-AUTO-8821',
        policyNumber: 'POL-AUTO-8821',
        officerId: 'OFF-3320',
        officerName: 'Sarah Jenkins',
        claimType: 'Windshield Damage',
        incidentDate: DateTime(2024, 7, 5),
        incidentLocation: 'I-5 Northbound, Milepost 172',
        description: 'Gravel from construction dump truck struck windshield causing star fracture.',
        estimatedDamage: 650.0,
        claimAmount: 500.0,
        reservedValue: 650.0,
        status: AppConstants.statusCompleted,
        priority: 'Low',
        createdAt: DateTime(2024, 7, 5, 9, 30),
        updatedAt: DateTime(2024, 7, 8, 16, 0),
        currentStep: 7,
        totalSteps: 7,
      ),
    ];
  }

  static List<DocumentModel> _initMockDocuments() {
    return [
      DocumentModel(
        id: 'doc_1',
        claimId: 'clm_8841_demo',
        customerId: 'usr_customer_demo',
        documentType: 'Police Incident Report',
        fileName: 'SPD_Incident_Report_2024_8841.pdf',
        fileUrl: 'https://res.cloudinary.com/d2c6a4ta/raw/upload/v1/insurex_docs/SPD_Report.pdf',
        fileSize: '1.4 MB',
        cloudinaryPublicId: 'spd_report_8841',
        resourceType: 'raw',
        verificationStatus: AppConstants.docVerified,
        verifiedBy: 'Marcus Vance',
        verifiedAt: DateTime(2024, 10, 24, 16, 15),
        uploadedAt: DateTime(2024, 10, 24, 15, 48),
      ),
      DocumentModel(
        id: 'doc_2',
        claimId: 'clm_8841_demo',
        customerId: 'usr_customer_demo',
        documentType: 'Driving License',
        fileName: 'Driver_License_Front_Back.pdf',
        fileUrl: 'https://res.cloudinary.com/d2c6a4ta/image/upload/v1/insurex_docs/Driver_License.png',
        fileSize: '840 KB',
        cloudinaryPublicId: 'driver_license_8841',
        resourceType: 'image',
        verificationStatus: AppConstants.docVerified,
        verifiedBy: 'Marcus Vance',
        verifiedAt: DateTime(2024, 10, 24, 16, 18),
        uploadedAt: DateTime(2024, 10, 24, 15, 50),
      ),
      DocumentModel(
        id: 'doc_3',
        claimId: 'clm_8841_demo',
        customerId: 'usr_customer_demo',
        documentType: 'Repair Facility Estimate',
        fileName: 'Bellevue_Collision_Estimate.pdf',
        fileUrl: 'https://res.cloudinary.com/d2c6a4ta/raw/upload/v1/insurex_docs/Bellevue_Estimate.pdf',
        fileSize: '2.1 MB',
        cloudinaryPublicId: 'repair_estimate_8841',
        resourceType: 'raw',
        verificationStatus: AppConstants.docPending,
        uploadedAt: DateTime(2024, 10, 24, 15, 52),
      ),
    ];
  }

  static List<EvidenceModel> _initMockEvidence() {
    return [
      EvidenceModel(
        id: 'ev_1',
        claimId: 'clm_8841_demo',
        customerId: 'usr_customer_demo',
        type: 'image',
        fileName: 'Bumper_Impact_Angle.jpg',
        fileUrl: 'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&w=800&q=80',
        cloudinaryPublicId: 'ev_bumper_impact',
        resourceType: 'image',
        description: 'Rear bumper and tailgate compression',
        uploadedAt: DateTime(2024, 10, 24, 15, 55),
      ),
      EvidenceModel(
        id: 'ev_2',
        claimId: 'clm_8841_demo',
        customerId: 'usr_customer_demo',
        type: 'image',
        fileName: 'Right_Quarter_Panel.jpg',
        fileUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?auto=format&fit=crop&w=800&q=80',
        cloudinaryPublicId: 'ev_quarter_panel',
        resourceType: 'image',
        description: 'Right quarter panel buckle & alignment gap',
        uploadedAt: DateTime(2024, 10, 24, 15, 56),
      ),
      EvidenceModel(
        id: 'ev_3',
        claimId: 'clm_8841_demo',
        customerId: 'usr_customer_demo',
        type: 'video',
        fileName: 'Accident_Walkaround.mp4',
        fileUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        cloudinaryPublicId: 'ev_walkaround_vid',
        resourceType: 'video',
        description: '360 degree vehicle walkaround video',
        uploadedAt: DateTime(2024, 10, 24, 15, 58),
      ),
    ];
  }

  static List<PolicyModel> _initMockPolicies() {
    return [
      PolicyModel(
        id: 'pol_home_4412',
        userId: 'usr_customer_demo',
        policyNumber: 'POL-HOME-4412',
        policyName: 'Home Protection Plus',
        policyType: 'Home Insurance',
        coverageDetails: 'Comprehensive Dwelling & Property Protection',
        totalCoverage: 550000.0,
        deductible: 1000.0,
        annualPremium: 81.67 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        endDate: DateTime.now().add(const Duration(days: 245)),
        status: 'Active',
        tier: 'Gold',
      ),
      PolicyModel(
        id: 'pol_auto_8821',
        userId: 'usr_customer_demo',
        policyNumber: 'POL-AUTO-8821',
        policyName: 'Comprehensive Auto Cover',
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
        tier: 'Platinum',
      ),
      PolicyModel(
        id: 'pol_health_2307',
        userId: 'usr_customer_demo',
        policyNumber: 'POL-HEALTH-2307',
        policyName: 'Family Health Shield',
        policyType: 'Health Insurance',
        coverageDetails: 'Inpatient Hospitalization, Pre-Post & Daycare',
        totalCoverage: 1000000.0,
        deductible: 250.0,
        annualPremium: 1250.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 305)),
        status: 'Active',
        tier: 'Platinum',
      ),
      PolicyModel(
        id: 'pol_travel_5198',
        userId: 'usr_customer_demo',
        policyNumber: 'POL-TRAVEL-5198',
        policyName: 'Travel Secure',
        policyType: 'Travel Insurance',
        coverageDetails: 'Worldwide Emergency Medical & Trip Cancellation',
        totalCoverage: 500000.0,
        deductible: 100.0,
        annualPremium: 450.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        status: 'Active',
        tier: 'Gold',
      ),
      PolicyModel(
        id: 'pol_pa_6734',
        userId: 'usr_customer_demo',
        policyNumber: 'POL-PA-6734',
        policyName: 'Personal Accident Protect',
        policyType: 'Personal Accident Insurance',
        coverageDetails: 'Accidental Death & Permanent Total Disability Cover',
        totalCoverage: 750000.0,
        deductible: 0.0,
        annualPremium: 325.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 320)),
        status: 'Active',
        tier: 'Silver',
      ),
      PolicyModel(
        id: 'pol_home_3381',
        userId: 'usr_customer_demo',
        policyNumber: 'POL-HOME-3381',
        policyName: 'Old Home Protection',
        policyType: 'Home Insurance',
        coverageDetails: 'Dwelling & Natural Hazard Basic Protection',
        totalCoverage: 350000.0,
        deductible: 1500.0,
        annualPremium: 106.67 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 400)),
        endDate: DateTime.now().subtract(const Duration(days: 35)),
        status: 'Expired',
        tier: 'Silver',
        isActive: false,
      ),
    ];
  }

  static List<OfficerModel> _initMockOfficers() {
    return [
      OfficerModel(
        id: 'off_1',
        userId: 'usr_officer_demo',
        name: 'Marcus Vance',
        email: 'officer@insurex.com',
        employeeId: 'EMP-7721',
        department: 'Auto & Physical Damage',
        designation: 'Senior Claims Adjuster',
        phone: '+1 (555) 721-4091',
        currentWorkload: 14,
        pendingClaims: 3,
        isAvailable: true,
        isOnDuty: true,
        specialty: 'Collision & Structural Damage',
        joinedAt: DateTime(2021, 4, 15),
      ),
      OfficerModel(
        id: 'off_2',
        userId: 'usr_officer_2',
        name: 'Sarah Jenkins',
        email: 's.jenkins@insurex.com',
        employeeId: 'EMP-6604',
        department: 'Property & Casualty',
        designation: 'Field Inspection Lead',
        phone: '+1 (555) 332-0199',
        currentWorkload: 9,
        pendingClaims: 1,
        isAvailable: true,
        isOnDuty: true,
        specialty: 'Property & Windstorm',
        joinedAt: DateTime(2022, 1, 10),
      ),
    ];
  }

  static List<NotificationModel> _initMockNotifications() {
    return [
      NotificationModel(
        id: 'notif_1',
        userId: 'usr_customer_demo',
        claimId: 'clm_8841_demo',
        title: 'Officer Assigned',
        message: 'Marcus Vance has been assigned to your claim CLM-2024-8841.',
        type: AppConstants.notifOfficerAssigned,
        isRead: false,
        createdAt: DateTime(2024, 10, 24, 16, 0),
      ),
      NotificationModel(
        id: 'notif_2',
        userId: 'usr_customer_demo',
        claimId: 'clm_8841_demo',
        title: 'Document Verified',
        message: 'Your Police Incident Report has been verified by adjuster Marcus Vance.',
        type: AppConstants.notifDocVerified,
        isRead: false,
        createdAt: DateTime(2024, 10, 24, 16, 15),
      ),
    ];
  }

  static List<AuditLogModel> _initMockAuditLogs() {
    return [
      AuditLogModel(
        id: 'log_1',
        userId: 'usr_customer_demo',
        userName: 'Alexander Wright',
        role: AppConstants.roleCustomer,
        action: AppConstants.auditClaimCreated,
        claimId: 'clm_8841_demo',
        description: 'Customer submitted First Notice of Loss for claim CLM-2024-8841.',
        timestamp: DateTime(2024, 10, 24, 15, 45),
      ),
      AuditLogModel(
        id: 'log_2',
        userId: 'usr_admin_demo',
        userName: 'Admin Desk',
        role: AppConstants.roleAdmin,
        action: AppConstants.auditOfficerAssigned,
        claimId: 'clm_8841_demo',
        description: 'Admin auto-assigned claim CLM-2024-8841 to Marcus Vance (Workload: 14).',
        timestamp: DateTime(2024, 10, 24, 16, 0),
      ),
      AuditLogModel(
        id: 'log_3',
        userId: 'usr_officer_demo',
        userName: 'Marcus Vance',
        role: AppConstants.roleOfficer,
        action: AppConstants.auditDocVerified,
        claimId: 'clm_8841_demo',
        description: 'Officer Marcus Vance verified Police Incident Report document.',
        timestamp: DateTime(2024, 10, 24, 16, 15),
      ),
    ];
  }

  static List<MessageModel> _initMockMessages() {
    return [
      MessageModel(
        id: 'msg_1',
        claimId: 'clm_8841_demo',
        senderId: 'usr_officer_demo',
        senderName: 'Marcus Vance',
        senderRole: AppConstants.roleOfficer,
        receiverId: 'usr_customer_demo',
        message: 'Hello Mr. Wright, I have reviewed your police incident report. Could you please provide the itemized repair estimate from the body shop?',
        createdAt: DateTime(2024, 10, 24, 16, 25),
      ),
      MessageModel(
        id: 'msg_2',
        claimId: 'clm_8841_demo',
        senderId: 'usr_customer_demo',
        senderName: 'Alexander Wright',
        senderRole: AppConstants.roleCustomer,
        receiverId: 'usr_officer_demo',
        message: 'Hi Marcus, I just uploaded the PDF estimate from Bellevue Collision. Please let me know if you need anything else.',
        createdAt: DateTime(2024, 10, 24, 16, 30),
      ),
    ];
  }
}
