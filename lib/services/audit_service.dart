import 'dart:async';
import '../models/claim_model.dart';
import 'firestore_service.dart';

/// AuditLogService: Creates and queries audit trails in Firestore.
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final FirestoreService _firestore = FirestoreService();

  /// Log action
  Future<void> log({
    required String userId,
    required String userName,
    required String role,
    required String action,
    String? claimId,
    required String description,
  }) {
    return _firestore.createAuditLog(AuditLogModel(
      id: '',
      userId: userId,
      userName: userName,
      role: role,
      action: action,
      claimId: claimId,
      description: description,
      timestamp: DateTime.now(),
    ));
  }

  /// Stream audit logs
  Stream<List<AuditLogModel>> getAuditLogs() {
    return _firestore.getAuditLogs();
  }
}
