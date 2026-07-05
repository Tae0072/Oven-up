import '../utils/format.dart';

/// 손님 알림 한 건 (05_API §9)
class AppNotification {
  final int notificationId;
  final String title;
  final String body;
  final String type; // ORDER_STATUS / ORDER_PAID
  final int? relatedOrderId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.relatedOrderId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        notificationId: (j['notificationId'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        type: (j['type'] as String?) ?? '',
        relatedOrderId: (j['relatedOrderId'] as num?)?.toInt(),
        read: (j['read'] as bool?) ?? false,
        createdAt: parseServerDateTime(j['createdAt']),
      );
}
