import 'package:cloud_firestore/cloud_firestore.dart';
import '../Manob/firebase_service.dart';
import '../Manob/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _notificationsCol = _firestore.collection(
    'notifications',
  );

  /// Streams notifications for a specific user ordered by createdAt descending.
  static Stream<List<NotificationModel>> streamUserNotifications(
    String userId,
  ) {
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Streams the count of unread notifications for a user.
  static Stream<int> streamUnreadCount(String userId) {
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marks a notification as read.
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).update({'isRead': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Marks all notifications for a user as read.
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final unreadSnap = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadSnap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Creates a new notification document.
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    String? relatedRequestId,
  }) async {
    try {
      await _notificationsCol.add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'relatedRequestId': relatedRequestId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignored
    }
  }
}
