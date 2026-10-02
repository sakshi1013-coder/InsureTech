import 'dart:async';
import '../models/claim_model.dart';
import 'firestore_service.dart';

/// NotificationService: Handles real-time Firestore notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirestoreService _firestore = FirestoreService();

  /// Stream notifications for specific user
  Stream<List<NotificationModel>> getNotificationsForUser(String userId) {
    return _firestore.getNotificationsForUser(userId);
  }

  /// Create a notification
  Future<void> sendNotification(NotificationModel notif) {
    return _firestore.createNotification(notif);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notifId) {
    return _firestore.markNotificationRead(notifId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) {
    return _firestore.markAllNotificationsRead(userId);
  }
}
