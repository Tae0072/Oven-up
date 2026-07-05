import '../utils/format.dart';

/// 주문 상세의 항목 한 줄 (05_API §4.4)
class OrderLineView {
  final int menuId;
  final String menuName;
  final int unitPrice;
  final int quantity;
  final String optionsDesc;

  const OrderLineView({
    required this.menuId,
    required this.menuName,
    required this.unitPrice,
    required this.quantity,
    required this.optionsDesc,
  });

  int get lineTotal => unitPrice * quantity;

  factory OrderLineView.fromJson(Map<String, dynamic> json) => OrderLineView(
        menuId: (json['menuId'] as num?)?.toInt() ?? 0,
        menuName: (json['menuName'] as String?) ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        optionsDesc: (json['optionsDesc'] as String?) ?? '',
      );
}

/// 주문 상세 (05_API §4.4)
class OrderDetail {
  final int orderId;
  final String orderNo;
  final String status;
  final String fulfillmentType;
  final DateTime? scheduledAt;
  final String? deliveryAddress;
  final int totalPrice;
  final int discountPrice;
  final List<OrderLineView> items;

  const OrderDetail({
    required this.orderId,
    required this.orderNo,
    required this.status,
    required this.fulfillmentType,
    required this.totalPrice,
    required this.discountPrice,
    required this.items,
    this.scheduledAt,
    this.deliveryAddress,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        orderId: (json['orderId'] as num).toInt(),
        orderNo: (json['orderNo'] as String?) ?? '',
        status: (json['status'] as String?) ?? '',
        fulfillmentType: (json['fulfillmentType'] as String?) ?? '',
        scheduledAt: parseServerDateTime(json['scheduledAt']),
        deliveryAddress: json['deliveryAddress'] as String?,
        totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
        discountPrice: (json['discountPrice'] as num?)?.toInt() ?? 0,
        items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => OrderLineView.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
