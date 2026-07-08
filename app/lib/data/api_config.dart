/// 서버 기본 주소 (앱 전체 공용).
/// - 웹 / 데스크톱: 기본 http://localhost:8080
/// - 실제 기기(태블릿/폰): localhost가 "기기 자신"을 가리키므로 PC의 IP를 주입해야 한다.
///   예) flutter run -d <기기ID> --dart-define=API_BASE_URL=http://192.168.50.164:8080
/// - 안드로이드 에뮬레이터: --dart-define=API_BASE_URL=http://10.0.2.2:8080
const String kApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
