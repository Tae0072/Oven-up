import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_line.dart';
import '../models/order_detail.dart';
import '../models/order_summary.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 주문 API 호출 (05_API §4). 로그인 토큰이 필요하다.
/// 주문 항목은 서버 장바구니(§3.3)에서 읽으므로, 주문 전에 화면 장바구니를 서버로 동기화한다.
class OrderApi {
  final http.Client _client;

  OrderApi({http.Client? client}) : _client = client ?? http.Client();

  /// 주문 생성 → 주문번호(orderNo) 반환.
  /// 1) 서버 장바구니를 화면 장바구니와 맞추고(비우고 다시 담기) 2) 주문을 만든다.
  Future<OrderCreateResult> createOrder({
    required String token,
    required List<CartLine> lines,
    required String fulfillmentType,
    String? scheduledAtIso,
    String? deliveryAddress,
    String? requestMsg,
  }) async {
    final authHeader = {'Authorization': 'Bearer $token'};
    final jsonAuth = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

    // 1) 서버 장바구니 동기화
    await _client.delete(Uri.parse('$kApiBaseUrl/api/cart'), headers: authHeader);
    for (final line in lines) {
      await _client.post(
        Uri.parse('$kApiBaseUrl/api/cart/items'),
        headers: jsonAuth,
        body: jsonEncode({
          'menuId': line.menu.id,
          'quantity': line.quantity,
          'optionIds': line.options.map((o) => o.id).toList(),
        }),
      );
    }

    // 2) 주문 생성 (서버 장바구니에서 항목을 읽음)
    final payload = <String, dynamic>{'fulfillmentType': fulfillmentType};
    if (scheduledAtIso != null) {
      payload['scheduledAt'] = scheduledAtIso;
    }
    if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
      payload['deliveryAddress'] = deliveryAddress;
    }
    if (requestMsg != null && requestMsg.isNotEmpty) {
      payload['requestMsg'] = requestMsg;
    }

    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/orders'),
      headers: jsonAuth,
      body: jsonEncode(payload),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(body, '주문에 실패했어요'));
    }
    final data = body['data'] as Map<String, dynamic>;
    return OrderCreateResult.fromJson(data);
  }

  /// 주문 결제 (05_API §5). '결제대기' 주문을 결제 완료 처리한다.
  /// mock 결제에선 paymentRef가 비어도 된다.
  Future<PaymentDone> payOrder({
    required String token,
    required int orderId,
    required String method,
    String? paymentRef,
  }) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/orders/$orderId/pay'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'method': method, 'paymentRef': paymentRef ?? ''}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '결제에 실패했어요'));
    }
    return PaymentDone.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 내 주문 목록 (05_API §4.3)
  Future<List<OrderSummary>> fetchMyOrders(String token) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '주문 내역을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 주문 상세 (05_API §4.4)
  Future<OrderDetail> fetchOrderDetail(String token, int orderId) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '주문을 불러오지 못했어요'));
    }
    return OrderDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}

/// 주문 생성 결과 (05_API §4.2)
class OrderCreateResult {
  final int orderId;
  final String orderNo;
  final int totalPrice;
  final String status;

  const OrderCreateResult({
    required this.orderId,
    required this.orderNo,
    required this.totalPrice,
    required this.status,
  });

  factory OrderCreateResult.fromJson(Map<String, dynamic> j) => OrderCreateResult(
        orderId: (j['orderId'] as num).toInt(),
        orderNo: (j['orderNo'] as String?) ?? '',
        totalPrice: (j['totalPrice'] as num?)?.toInt() ?? 0,
        status: (j['status'] as String?) ?? '',
      );
}

/// 결제 결과 (05_API §5)
class PaymentDone {
  final int orderId;
  final String orderNo;
  final String status;
  final String paymentMethod;

  const PaymentDone({
    required this.orderId,
    required this.orderNo,
    required this.status,
    required this.paymentMethod,
  });

  factory PaymentDone.fromJson(Map<String, dynamic> j) => PaymentDone(
        orderId: (j['orderId'] as num).toInt(),
        orderNo: (j['orderNo'] as String?) ?? '',
        status: (j['status'] as String?) ?? '',
        paymentMethod: (j['paymentMethod'] as String?) ?? '',
      );
}
