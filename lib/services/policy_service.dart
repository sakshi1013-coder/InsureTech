import 'dart:async';
import '../models/policy_model.dart';
import 'firestore_service.dart';

/// PolicyService: Handles policy queries and details from Firestore.
class PolicyService {
  static final PolicyService _instance = PolicyService._internal();
  factory PolicyService() => _instance;
  PolicyService._internal();

  final FirestoreService _firestore = FirestoreService();

  /// Stream policies belonging to a user
  Stream<List<PolicyModel>> getPoliciesForUser(String userId) {
    return _firestore.getPoliciesForUser(userId);
  }

  /// Stream all policies across system (for officers / underwriting)
  Stream<List<PolicyModel>> getAllPolicies() {
    return _firestore.getAllPolicies();
  }

  /// Create a new policy
  Future<String> createPolicy(PolicyModel policy) {
    return _firestore.createPolicy(policy);
  }

  /// Get specific policy by ID
  Future<PolicyModel?> getPolicyById(String policyId) {
    return _firestore.getPolicyById(policyId);
  }
}
