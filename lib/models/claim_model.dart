import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String claimNumber;
  final String userId;
  final String userEmail;
  final String userName;
  final String policyId;
  final String policyNumber;
  final String? officerId;
  final String? officerName;
  final String claimType;
  final DateTime incidentDate;
  final String incidentLocation;
  final String description;
  final double estimatedDamage;
  final double claimAmount;
  final double? reservedValue;
  final String status;
  final String priority; // Critical, High, Medium, Low
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;
  final String? additionalInfoRequest;
  final List<String> timeline;
  final int currentStep;
  final int totalSteps;
  final bool isFnolSubmitted;

  // Aliases for Firestore schema alignment and UI reference
  String get claimId => id;
  String get customerId => userId;
  String get incidentType => claimType;
  double get estimatedLoss => estimatedDamage;

  ClaimModel({
    required this.id,
    required this.claimNumber,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.policyId,
    required this.policyNumber,
    this.officerId,
    this.officerName,
    required this.claimType,
    required this.incidentDate,
    required this.incidentLocation,
    required this.description,
    required this.estimatedDamage,
    required this.claimAmount,
    this.reservedValue,
    required this.status,
    this.priority = 'Medium',
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.additionalInfoRequest,
    this.timeline = const [],
    this.currentStep = 1,
    this.totalSteps = 7,
    this.isFnolSubmitted = true,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> map, String id) {
    final effectiveId = id.isNotEmpty ? id : (map['claimId']?.toString() ?? '');
    final effectiveUserId = (map['customerId'] ?? map['userId'] ?? '').toString();
    final claimNum = map['claimNumber']?.toString() ?? (effectiveId.isNotEmpty ? 'CLM-${effectiveId.substring(0, effectiveId.length > 8 ? 8 : effectiveId.length)}' : 'CLM-NEW');
    
    return ClaimModel(
      id: effectiveId,
      claimNumber: claimNum,
      userId: effectiveUserId,
      userEmail: map['userEmail']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      policyId: map['policyId']?.toString() ?? '',
      policyNumber: map['policyNumber']?.toString() ?? '',
      officerId: map['officerId']?.toString(),
      officerName: map['officerName']?.toString(),
      claimType: map['claimType']?.toString() ?? '',
      incidentDate: (map['incidentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      incidentLocation: map['incidentLocation']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      estimatedDamage: (map['estimatedDamage'] ?? 0).toDouble(),
      claimAmount: (map['claimAmount'] ?? 0).toDouble(),
      reservedValue: map['reservedValue'] != null ? (map['reservedValue']).toDouble() : null,
      status: map['status']?.toString() ?? 'submitted',
      priority: map['priority']?.toString() ?? 'Medium',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rejectionReason: map['rejectionReason']?.toString(),
      additionalInfoRequest: map['additionalInfoRequest']?.toString(),
      timeline: List<String>.from(map['timeline'] ?? []),
      currentStep: map['currentStep'] ?? 1,
      totalSteps: map['totalSteps'] ?? 7,
      isFnolSubmitted: map['isFnolSubmitted'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': id,
      'customerId': userId,
      'userId': userId,
      'claimNumber': claimNumber,
      'userEmail': userEmail,
      'userName': userName,
      'policyId': policyId,
      'policyNumber': policyNumber,
      'officerId': officerId,
      'officerName': officerName,
      'claimType': claimType,
      'incidentDate': Timestamp.fromDate(incidentDate),
      'incidentLocation': incidentLocation,
      'description': description,
      'estimatedDamage': estimatedDamage,
      'claimAmount': claimAmount,
      'reservedValue': reservedValue,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rejectionReason': rejectionReason,
      'additionalInfoRequest': additionalInfoRequest,
      'timeline': timeline,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
      'isFnolSubmitted': isFnolSubmitted,
    };
  }

  ClaimModel copyWith({
    String? officerId,
    String? officerName,
    String? status,
    String? priority,
    String? rejectionReason,
    String? additionalInfoRequest,
    List<String>? timeline,
    int? currentStep,
    double? reservedValue,
    DateTime? updatedAt,
  }) {
    return ClaimModel(
      id: id,
      claimNumber: claimNumber,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      policyId: policyId,
      policyNumber: policyNumber,
      officerId: officerId ?? this.officerId,
      officerName: officerName ?? this.officerName,
      claimType: claimType,
      incidentDate: incidentDate,
      incidentLocation: incidentLocation,
      description: description,
      estimatedDamage: estimatedDamage,
      claimAmount: claimAmount,
      reservedValue: reservedValue ?? this.reservedValue,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      rejectionReason: rejectionReason ?? this.rejectionReason,
      additionalInfoRequest: additionalInfoRequest ?? this.additionalInfoRequest,
      timeline: timeline ?? this.timeline,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps,
      isFnolSubmitted: isFnolSubmitted,
    );
  }
}

class DocumentModel {
  final String id;
  final String claimId;
  final String customerId;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final String? cloudinaryPublicId;
  final String? resourceType;
  final String verificationStatus; // pending, verified, rejected, reupload_required
  final String? verificationNote;
  final String? fileSize;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  // Compatibility aliases
  String get userId => customerId;
  String get documentId => id;

  DocumentModel({
    required this.id,
    required this.claimId,
    String? customerId,
    String? userId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    this.cloudinaryPublicId,
    this.resourceType = 'raw',
    this.verificationStatus = 'pending',
    this.verificationNote,
    this.fileSize,
    required this.uploadedAt,
    this.verifiedAt,
    this.verifiedBy,
  }) : customerId = customerId ?? userId ?? '';

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      claimId: map['claimId']?.toString() ?? '',
      customerId: (map['customerId'] ?? map['userId'] ?? '').toString(),
      documentType: map['documentType']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      fileUrl: map['fileUrl']?.toString() ?? '',
      cloudinaryPublicId: map['cloudinaryPublicId']?.toString(),
      resourceType: map['resourceType']?.toString() ?? 'raw',
      verificationStatus: map['verificationStatus']?.toString() ?? 'pending',
      verificationNote: map['verificationNote']?.toString(),
      fileSize: map['fileSize']?.toString() ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      verifiedBy: map['verifiedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'customerId': customerId,
      'userId': customerId,
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'resourceType': resourceType,
      'verificationStatus': verificationStatus,
      'verificationNote': verificationNote,
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
    };
  }

  DocumentModel copyWith({
    String? verificationStatus,
    String? verificationNote,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return DocumentModel(
      id: id,
      claimId: claimId,
      customerId: customerId,
      documentType: documentType,
      fileName: fileName,
      fileUrl: fileUrl,
      cloudinaryPublicId: cloudinaryPublicId,
      resourceType: resourceType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNote: verificationNote ?? this.verificationNote,
      fileSize: fileSize,
      uploadedAt: uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}

class EvidenceModel {
  final String id;
  final String claimId;
  final String customerId;
  final String type; // image, video
  final String fileName;
  final String fileUrl;
  final String? cloudinaryPublicId;
  final String? resourceType;
  final String description;
  final DateTime uploadedAt;
  final String? thumbnailUrl;

  // Compatibility aliases
  String get userId => customerId;
  String get evidenceId => id;

  EvidenceModel({
    required this.id,
    required this.claimId,
    String? customerId,
    String? userId,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    this.cloudinaryPublicId,
    this.resourceType,
    this.description = '',
    required this.uploadedAt,
    this.thumbnailUrl,
  }) : customerId = customerId ?? userId ?? '';

  factory EvidenceModel.fromMap(Map<String, dynamic> map, String id) {
    return EvidenceModel(
      id: id,
      claimId: map['claimId']?.toString() ?? '',
      customerId: (map['customerId'] ?? map['userId'] ?? '').toString(),
      type: map['type']?.toString() ?? 'image',
      fileName: map['fileName']?.toString() ?? '',
      fileUrl: map['fileUrl']?.toString() ?? '',
      cloudinaryPublicId: map['cloudinaryPublicId']?.toString(),
      resourceType: map['resourceType']?.toString() ?? (map['type'] == 'video' ? 'video' : 'image'),
      description: map['description']?.toString() ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'customerId': customerId,
      'userId': customerId,
      'type': type,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'resourceType': resourceType ?? (type == 'video' ? 'video' : 'image'),
      'description': description,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String? claimId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.claimId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      claimId: map['claimId']?.toString(),
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'claimId': claimId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final String role;
  final String action;
  final String? claimId;
  final String description;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.action,
    this.claimId,
    required this.description,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      claimId: map['claimId']?.toString(),
      description: map['description']?.toString() ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
      'action': action,
      'claimId': claimId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class MessageModel {
  final String id;
  final String claimId;
  final String senderId;
  final String senderRole;
  final String receiverId;
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;
  final String senderName;
  final bool isRead;

  // Compatibility aliases
  String get content => message;
  String? get fileUrl => attachmentUrl;
  String? get fileType => attachmentUrl != null ? (attachmentUrl!.endsWith('.mp4') ? 'video' : 'image') : null;

  MessageModel({
    required this.id,
    required this.claimId,
    required this.senderId,
    required this.senderRole,
    this.receiverId = '',
    String? message,
    String? content,
    String? attachmentUrl,
    String? fileUrl,
    String? fileType,
    required this.createdAt,
    this.senderName = '',
    this.isRead = false,
  })  : message = message ?? content ?? '',
        attachmentUrl = attachmentUrl ?? fileUrl;

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      claimId: map['claimId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderRole: map['senderRole']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      message: (map['message'] ?? map['content'] ?? '').toString(),
      attachmentUrl: map['attachmentUrl']?.toString() ?? map['fileUrl']?.toString(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'senderId': senderId,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'senderName': senderName,
      'content': message,
      'fileUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
