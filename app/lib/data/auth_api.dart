import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 로그인 결과: 토큰 + 회원
class AuthResult {
  final String token;
  final AuthUser user;

  AuthResult(this.token, this.user);
}

/// 인증 API 호출 (05_API §2)
class AuthApi {
  final http.Client _client;

  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeader = {'Content-Type': 'application/json'};

  Future<int> signup({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/auth/signup'),
      headers: _jsonHeader,
      body: jsonEncode({'email': email, 'password': password, 'name': name, 'phone': phone}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(body, '회원가입에 실패했어요'));
    }
    final data = body['data'] as Map<String, dynamic>;
    return (data['userId'] as num).toInt();
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/auth/login'),
      headers: _jsonHeader,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '로그인에 실패했어요'));
    }
    final data = body['data'] as Map<String, dynamic>;
    return AuthResult(
      data['accessToken'] as String,
      AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// 소셜 로그인 (05_API §2.3). provider = 'kakao' | 'naver'.
  /// 두 방식 중 하나로 호출한다.
  /// - accessToken: SDK로 직접 받은 토큰 (또는 dev mock 토큰)
  /// - code(+redirectUri, state): 웹 리다이렉트 로그인의 인가 코드 → 서버가 토큰으로 교환
  Future<AuthResult> socialLogin({
    required String provider,
    String? accessToken,
    String? code,
    String? redirectUri,
    String? state,
  }) async {
    final payload = <String, String>{
      'accessToken': ?accessToken,
      'code': ?code,
      'redirectUri': ?redirectUri,
      'state': ?state,
    };
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/auth/social/$provider'),
      headers: _jsonHeader,
      body: jsonEncode(payload),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '소셜 로그인에 실패했어요'));
    }
    final data = body['data'] as Map<String, dynamic>;
    return AuthResult(
      data['accessToken'] as String,
      AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// 내 정보 조회 (05_API §2.4)
  Future<MyProfile> fetchProfile(String token) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '내 정보를 불러오지 못했어요'));
    }
    return MyProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 프로필(이름·연락처) 수정 (05_API §2.5)
  Future<MyProfile> updateProfile({
    required String token,
    required String name,
    required String phone,
  }) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl/api/users/me'),
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name, 'phone': phone}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '정보 수정에 실패했어요'));
    }
    return MyProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 비밀번호 변경 (05_API §2.5)
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl/api/users/me/password'),
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw ApiException(_errorMessage(body, '비밀번호 변경에 실패했어요'));
    }
  }

  /// 알림 켜기/끄기 (05_API §2.5)
  Future<MyProfile> setNotifyEnabled({required String token, required bool enabled}) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl/api/users/me/notify'),
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode({'enabled': enabled}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '알림 설정에 실패했어요'));
    }
    return MyProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 회원 탈퇴 (05_API §2.5). 현재 비밀번호 확인 필요.
  Future<void> deleteAccount({required String token, required String currentPassword}) async {
    final res = await _client.delete(
      Uri.parse('$kApiBaseUrl/api/users/me'),
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode({'currentPassword': currentPassword}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw ApiException(_errorMessage(body, '회원 탈퇴에 실패했어요'));
    }
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}

/// 내 정보 (05_API §2.4)
class MyProfile {
  final String email;
  final String name;
  final String phone;
  final String role;
  final int pointBalance;
  final bool notifyEnabled;

  const MyProfile({
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.pointBalance,
    this.notifyEnabled = true,
  });

  factory MyProfile.fromJson(Map<String, dynamic> j) => MyProfile(
        email: (j['email'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        role: (j['role'] as String?) ?? 'USER',
        pointBalance: (j['pointBalance'] as num?)?.toInt() ?? 0,
        notifyEnabled: (j['notifyEnabled'] as bool?) ?? true,
      );
}
