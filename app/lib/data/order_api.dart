import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_line.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 주문 API 호출 (05_API §4). 로그인 토큰이 필요하다.
class OrderApi {
  final http.Client _client;

  OrderApi({http.Client? client}) : _client = client ?? http.Client();

  /// 주문 생성 → 주문번호(orderNo) 반환.
  /// 금액은 서버가 다시 계산하므로, 화면은 항목(메뉴/수량/옵션)만 보낸다.
  Future<String> createOrder({
    required String token,
    required List<CartLine> lines,
    required String fulfillmentType,
    String? scheduledAtIso,
    String? deliveryAddress,
    String? requestMsg,
  }) async {
    final items = lines
        .map((l) => {
              'menuId': l.menu.id,
              'quantity': l.quantity,
              'optionIds': l.options.map((o) => o.id).toList(),
            })
        .toList();

    final payload = <String, dynamic>{
      'fulfillmentType': fulfillmentType,
      'items': items,
    };
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
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      final error = body['error'];
      final message = (error is Map && error['message'] is String)
          ? error['message'] as String
          : '주문에 실패했어요';
      throw ApiException(message);
    }
    final data = body['data'] as Map<String, dynamic>;
    return data['orderNo'] as String;
  }
}
