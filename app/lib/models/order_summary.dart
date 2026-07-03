import '../utils/format.dart';

/// 내 주문 목록의 한 건 (05_API §4.3)
class OrderSummary {
  final int orderId;
  final String orderNo;
  final int totalPrice;
  final String fulfillmentType;
  final DateTime? scheduledAt;
  final String status;
  final DateTime? createdAt;

  const OrderSummary({
    required this.orderId,
    required this.orderNo,
    required this.totalPrice,
    required this.fulfillmentType,
    required this.status,
    this.scheduledAt,
    this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        orderId: (json['orderId'] as num).toInt(),
        orderNo: (json['orderNo'] as String?) ?? '',
        totalPrice: (json['totalPrice'] as num).toInt(),
        fulfillmentType: (json['fulfillmentType'] as String?) ?? '',
        status: (json['status'] as String?) ?? '',
        scheduledAt: parseServerDateTime(json['scheduledAt']),
        createdAt: parseServerDateTime(json['createdAt']),
      );
}
