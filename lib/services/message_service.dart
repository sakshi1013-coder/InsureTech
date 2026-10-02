import 'dart:async';
import '../models/claim_model.dart';
import 'firestore_service.dart';

/// MessageService: Real-time Firestore chat between Customer and Officer.
class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final FirestoreService _firestore = FirestoreService();

  /// Stream messages for a claim conversation
  Stream<List<MessageModel>> getMessagesForClaim(String claimId) {
    return _firestore.getMessagesForClaim(claimId);
  }

  /// Send message
  Future<void> sendMessage({
    required String claimId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String receiverId,
    required String message,
    String? attachmentUrl,
  }) {
    return _firestore.sendMessage(MessageModel(
      id: '',
      claimId: claimId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      receiverId: receiverId,
      message: message,
      attachmentUrl: attachmentUrl,
      createdAt: DateTime.now(),
    ));
  }
}
