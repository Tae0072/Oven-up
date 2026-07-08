import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 알림 API 호출 (05_API §9). 로그인 토큰 필요.
class NotificationApi {
  final http.Client _client;

  NotificationApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  /// 기기 토큰 등록 (푸시용). 로그인 후 FCM 토큰을 서버에 알려준다.
  Future<void> registerDeviceToken({required String token, required String fcmToken}) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/notifications/device-token'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'token': fcmToken}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw ApiException(_errorMessage(body, '기기 등록에 실패했어요'));
    }
  }

  /// 내 알림 목록
  Future<List<AppNotification>> fetchList(String token) async {
    final res = await _client.get(Uri.parse('$kApiBaseUrl/api/notifications'), headers: _auth(token));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '알림을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 안 읽은 알림 개수 (배지용). 실패하면 0으로 처리.
  Future<int> unreadCount(String token) async {
    try {
      final res = await _client.get(
        Uri.parse('$kApiBaseUrl/api/notifications/unread-count'),
        headers: _auth(token),
      );
      if (res.statusCode != 200) return 0;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ((body['data'] as Map<String, dynamic>)['unread'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 한 건 읽음 → 남은 안읽음 개수 반환
  Future<int> markRead(String token, int notificationId) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/notifications/$notificationId/read'),
      headers: _auth(token),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '처리에 실패했어요'));
    }
    return ((body['data'] as Map<String, dynamic>)['unread'] as num?)?.toInt() ?? 0;
  }

  /// 모두 읽음
  Future<void> markAllRead(String token) async {
    await _client.post(Uri.parse('$kApiBaseUrl/api/notifications/read-all'), headers: _auth(token));
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}
