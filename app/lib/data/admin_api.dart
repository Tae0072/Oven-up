import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order_detail.dart';
import '../models/order_summary.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 관리자(사장님) 주문 관리 API 호출 (05_API §11, 화면 A4). ADMIN 토큰 필요.
class AdminApi {
  final http.Client _client;

  AdminApi({http.Client? client}) : _client = client ?? http.Client();

  /// 전체(또는 상태별) 주문 목록
  Future<List<OrderSummary>> fetchOrders(String token, {String? status}) async {
    final uri = (status == null || status.isEmpty)
        ? Uri.parse('$kApiBaseUrl/api/admin/orders')
        : Uri.parse('$kApiBaseUrl/api/admin/orders?status=${Uri.encodeQueryComponent(status)}');
    final res = await _client.get(uri, headers: {'Authorization': 'Bearer $token'});
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '주문 목록을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 주문 상세 (관리자)
  Future<OrderDetail> fetchDetail(String token, int orderId) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/admin/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '주문을 불러오지 못했어요'));
    }
    return OrderDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 주문 상태 변경
  Future<OrderDetail> updateStatus(String token, int orderId, String status) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl/api/admin/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'status': status}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '상태를 바꾸지 못했어요'));
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

/// 관리자가 바꿀 수 있는 주문 상태 (서버 ADMIN_STATUSES와 맞춤)
const List<String> kAdminStatuses = [
  '준비중',
  '준비완료',
  '픽업완료',
  '배달중',
  '배달완료',
  '취소',
];
