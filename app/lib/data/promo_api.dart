import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// 쿠폰 확인 결과 (05_API §10)
class CouponCheck {
  final bool valid;
  final int discount;
  final String? message;
  final String? name;

  const CouponCheck({required this.valid, required this.discount, this.message, this.name});

  factory CouponCheck.fromJson(Map<String, dynamic> j) => CouponCheck(
        valid: (j['valid'] as bool?) ?? false,
        discount: (j['discount'] as num?)?.toInt() ?? 0,
        message: j['message'] as String?,
        name: j['name'] as String?,
      );
}

/// 적립금 정보
class PointsInfo {
  final int balance;
  final int earnPercent;

  const PointsInfo({required this.balance, required this.earnPercent});

  factory PointsInfo.fromJson(Map<String, dynamic> j) => PointsInfo(
        balance: (j['balance'] as num?)?.toInt() ?? 0,
        earnPercent: (j['earnPercent'] as num?)?.toInt() ?? 0,
      );
}

/// 쿠폰·적립 조회 API (주문서/마이페이지 공용).
class PromoApi {
  final http.Client _client;

  PromoApi({http.Client? client}) : _client = client ?? http.Client();

  /// 쿠폰 적용 가능/할인액 확인. [amount]에 현재 주문금액을 넘기면 그 기준으로 확인.
  Future<CouponCheck> checkCoupon(String token, String code, {int? amount}) async {
    final amountParam = (amount != null && amount > 0) ? '&amount=$amount' : '';
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/coupons/check?code=${Uri.encodeQueryComponent(code)}$amountParam'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_msg(body, '쿠폰을 확인하지 못했어요'));
    }
    return CouponCheck.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 내 적립금 잔액 + 적립률
  Future<PointsInfo> fetchPoints(String token) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/points'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_msg(body, '적립금을 불러오지 못했어요'));
    }
    return PointsInfo.fromJson(body['data'] as Map<String, dynamic>);
  }

  String _msg(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}
