import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

/// 로그인 상태(토큰 + 회원)를 앱 전체에서 공유하고, 기기에 저장/복원한다.
/// - setSession/logout 시 기기 저장소(shared_preferences)에 반영
/// - 앱 시작 시 load()로 복원 → 앱을 껐다 켜도 로그인 유지
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  static const String _kToken = 'auth_token';
  static const String _kUserId = 'auth_user_id';
  static const String _kUserName = 'auth_user_name';
  static const String _kUserRole = 'auth_user_role';

  String? _token;
  AuthUser? _user;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isLoggedIn => _token != null;

  /// 앱 시작 시 기기에 저장된 로그인 정보를 복원한다.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null || token.isEmpty) return;
    _token = token;
    _user = AuthUser(
      id: prefs.getInt(_kUserId) ?? 0,
      name: prefs.getString(_kUserName) ?? '',
      role: prefs.getString(_kUserRole) ?? 'USER',
    );
    notifyListeners();
  }

  void setSession(String token, AuthUser user) {
    _token = token;
    _user = user;
    notifyListeners();
    _persist(token, user);
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
    _clear();
  }

  Future<void> _persist(String token, AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setInt(_kUserId, user.id);
    await prefs.setString(_kUserName, user.name);
    await prefs.setString(_kUserRole, user.role);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserRole);
  }
}
