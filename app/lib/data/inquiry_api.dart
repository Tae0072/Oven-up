import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/inquiry.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 고객의 소리 API 호출 (05_API §7). 모두 로그인 토큰이 필요하다. 본인 글만 조회.
class InquiryApi {
  final http.Client _client;

  InquiryApi({http.Client? client}) : _client = client ?? http.Client();

  /// 문의 작성 → 문의번호(inquiryId) 반환 (§7.1)
  Future<int> create({
    required String token,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    final payload = <String, dynamic>{'title': title, 'content': content};
    if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['imageUrl'] = imageUrl;
    }
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/inquiries'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(body, '문의 작성에 실패했어요'));
    }
    return (body['data'] as Map<String, dynamic>)['inquiryId'] as int;
  }

  /// 내 문의 목록 (§7.2)
  Future<List<InquirySummary>> fetchMine(String token) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/inquiries'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '문의 내역을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => InquirySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 문의 상세 (본인 글만) (§7.3)
  Future<InquiryDetail> fetchDetail(String token, int inquiryId) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/inquiries/$inquiryId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '문의를 불러오지 못했어요'));
    }
    return InquiryDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}
