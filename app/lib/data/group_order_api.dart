import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/group_order.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 단체 주문 문의 API 호출 (05_API §6). 모두 로그인 토큰이 필요하다.
class GroupOrderApi {
  final http.Client _client;

  GroupOrderApi({http.Client? client}) : _client = client ?? http.Client();

  /// 단체주문 문의 접수 → 접수번호(groupOrderId) 반환 (§6.1)
  Future<int> create({
    required String token,
    String? desiredAtIso,
    required int headcount,
    String? detail,
    String? contact,
  }) async {
    final payload = <String, dynamic>{'headcount': headcount};
    if (desiredAtIso != null && desiredAtIso.isNotEmpty) {
      payload['desiredAt'] = desiredAtIso;
    }
    if (detail != null && detail.isNotEmpty) {
      payload['detail'] = detail;
    }
    if (contact != null && contact.isNotEmpty) {
      payload['contact'] = contact;
    }
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/group-orders'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(body, '단체주문 문의에 실패했어요'));
    }
    return (body['data'] as Map<String, dynamic>)['groupOrderId'] as int;
  }

  /// 내 단체주문 문의 목록 (§6.2)
  Future<List<GroupOrder>> fetchMine(String token) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/group-orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '단체주문 내역을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => GroupOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}
