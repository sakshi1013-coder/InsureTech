import 'package:cloud_firestore/cloud_firestore.dart';

class PolicyModel {
  final String id;
  final String userId;
  final String policyNumber;
  final String policyName;
  final String policyType; // auto, health, home, life
  final String coverageDetails;
  final double totalCoverage;
  final double deductible;
  final double annualPremium;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // Active, Expired, Cancelled
  final String vehicleModel;
  final String vehicleLicense;
  final String vehicleVin;
  final String tier; // Gold, Silver, Bronze
  final bool isActive;

  String get customerId => userId;
  double get monthlyPremium => annualPremium > 0 ? (annualPremium / 12) : 112.50;
  double get premium => monthlyPremium;
  double get coverageAmount => totalCoverage;

  PolicyModel({
    required this.id,
    required this.userId,
    required this.policyNumber,
    required this.policyName,
    required this.policyType,
    required this.coverageDetails,
    required this.totalCoverage,
    required this.deductible,
    required this.annualPremium,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.vehicleModel = '',
    this.vehicleLicense = '',
    this.vehicleVin = '',
    this.tier = 'Gold',
    this.isActive = true,
  });

  factory PolicyModel.fromMap(Map<String, dynamic> map, String id) {
    return PolicyModel(
      id: id,
      userId: (map['customerId'] ?? map['userId'] ?? '').toString(),
      policyNumber: map['policyNumber'] ?? '',
      policyName: map['policyName'] ?? '',
      policyType: map['policyType'] ?? 'auto',
      coverageDetails: map['coverageDetails'] ?? '',
      totalCoverage: (map['totalCoverage'] ?? 0).toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      annualPremium: (map['annualPremium'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      status: map['status'] ?? 'Active',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleLicense: map['vehicleLicense'] ?? '',
      vehicleVin: map['vehicleVin'] ?? '',
      tier: map['tier'] ?? 'Gold',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerId': userId,
      'policyNumber': policyNumber,
      'policyName': policyName,
      'policyType': policyType,
      'coverageDetails': coverageDetails,
      'totalCoverage': totalCoverage,
      'deductible': deductible,
      'annualPremium': annualPremium,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'vehicleModel': vehicleModel,
      'vehicleLicense': vehicleLicense,
      'vehicleVin': vehicleVin,
      'tier': tier,
      'isActive': isActive,
    };
  }

  int get daysUntilExpiry {
    return endDate.difference(DateTime.now()).inDays;
  }

  bool get isExpired => status == 'Expired' || endDate.isBefore(DateTime.now());
}
