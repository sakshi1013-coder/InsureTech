import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? photoUrl;
  final String? address;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.address,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      photoUrl: map['photoUrl'],
      address: map['address'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class OfficerModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String employeeId;
  final String department;
  final String designation;
  final String phone;
  final String? photoUrl;
  final int currentWorkload;
  final int pendingClaims;
  final bool isAvailable;
  final bool isOnDuty;
  final String specialty;
  final DateTime joinedAt;

  OfficerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.phone,
    this.photoUrl,
    this.currentWorkload = 0,
    this.pendingClaims = 0,
    this.isAvailable = true,
    this.isOnDuty = true,
    required this.specialty,
    required this.joinedAt,
  });

  factory OfficerModel.fromMap(Map<String, dynamic> map, String id) {
    return OfficerModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      employeeId: map['employeeId'] ?? '',
      department: map['department'] ?? 'Auto & Casualty',
      designation: map['designation'] ?? 'Senior Field Adjuster',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      currentWorkload: map['currentWorkload'] ?? 0,
      pendingClaims: map['pendingClaims'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      isOnDuty: map['isOnDuty'] ?? true,
      specialty: map['specialty'] ?? 'Auto Claims',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'department': department,
      'designation': designation,
      'phone': phone,
      'photoUrl': photoUrl,
      'currentWorkload': currentWorkload,
      'pendingClaims': pendingClaims,
      'isAvailable': isAvailable,
      'isOnDuty': isOnDuty,
      'specialty': specialty,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'O';
  }
}
