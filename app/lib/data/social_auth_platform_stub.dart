/// 웹이 아닌 플랫폼(안드로이드/iOS/테스트)용 빈 구현.
/// 웹 리다이렉트 로그인은 웹에서만 동작한다. (모바일은 이후 SDK 연동 단계에서 추가)
library;

String currentOrigin() => '';

void redirectTo(String url) {}

String? readSessionValue(String key) => null;

void writeSessionValue(String key, String value) {}

void removeSessionValue(String key) {}

void cleanUrl() {}
