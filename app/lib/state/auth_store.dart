import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';

/// 로그인 상태(토큰 + 회원)를 앱 전체에서 공유하는 저장소.
/// ⚠️ 지금은 앱 메모리에만 저장(앱을 완전히 끄면 로그아웃됨). 이후 기기 저장(shared_preferences)으로 유지 가능.
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  String? _token;
  AuthUser? _user;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isLoggedIn => _token != null;

  void setSession(String token, AuthUser user) {
    _token = token;
    _user = user;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}
