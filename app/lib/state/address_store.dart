import 'package:flutter/foundation.dart';

import '../data/auth_api.dart';
import 'auth_store.dart';

/// 현재 선택된 주소 (홈·메뉴 상단에 표시).
/// 로그인 회원은 서버(내 정보)의 주소와 동기화하고, 비회원은 앱 안에서만 기억한다.
class AddressStore extends ChangeNotifier {
  AddressStore._();

  static final AddressStore instance = AddressStore._();

  final AuthApi _authApi = AuthApi();

  String _address = '';
  bool _loaded = false;

  String get address => _address;

  /// 로그인 상태면 서버에서 내 주소를 불러온다 (한 번만).
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final token = AuthStore.instance.token;
    if (token == null) return;
    try {
      final profile = await _authApi.fetchProfile(token);
      _address = profile.address;
      _loaded = true;
      notifyListeners();
    } catch (_) {/* 네트워크 실패 시 다음 기회에 */}
  }

  /// 주소 변경. 로그인 상태면 서버에도 저장한다.
  Future<void> update(String newAddress) async {
    _address = newAddress;
    notifyListeners();
    final token = AuthStore.instance.token;
    if (token != null) {
      try {
        await _authApi.updateProfile(token: token, address: newAddress);
      } catch (_) {/* 저장 실패해도 화면 표시는 유지 */}
    }
  }

  /// 화면 표시만 갱신 (서버 저장은 이미 끝난 경우 — 주소 선택 화면에서 사용)
  void setLocal(String newAddress) {
    _address = newAddress;
    notifyListeners();
  }

  /// 로그아웃 등으로 초기화
  void clear() {
    _address = '';
    _loaded = false;
    notifyListeners();
  }
}
