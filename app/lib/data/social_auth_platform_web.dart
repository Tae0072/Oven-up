/// 웹 전용 구현 — 브라우저 리다이렉트, sessionStorage, 주소창 정리.
library;

import 'package:web/web.dart' as web;

/// 현재 페이지의 origin (예: http://localhost:8091)
String currentOrigin() => web.window.location.origin;

/// 브라우저를 해당 주소로 이동시킨다 (카카오/네이버 로그인 페이지로).
void redirectTo(String url) {
  web.window.location.href = url;
}

String? readSessionValue(String key) => web.window.sessionStorage.getItem(key);

void writeSessionValue(String key, String value) {
  web.window.sessionStorage.setItem(key, value);
}

void removeSessionValue(String key) {
  web.window.sessionStorage.removeItem(key);
}

/// 주소창에서 ?code=... 같은 쿼리를 지운다(새로고침 시 재사용 방지).
void cleanUrl() {
  final u = Uri.base;
  final cleaned = Uri(
    scheme: u.scheme,
    host: u.host,
    port: u.hasPort ? u.port : null,
    path: u.path,
    fragment: u.fragment.isEmpty ? null : u.fragment,
  ).toString();
  web.window.history.replaceState(null, '', cleaned);
}
