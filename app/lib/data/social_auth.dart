import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'social_auth_platform_stub.dart'
    if (dart.library.js_interop) 'social_auth_platform_web.dart' as platform;

/// 카카오 REST API 키 / 네이버 Client ID.
/// 실행 시 --dart-define 으로 주입한다(코드에 키를 하드코딩하지 않음).
/// 예) flutter run -d web-server --web-port 8091 \
///       --dart-define=KAKAO_REST_API_KEY=... --dart-define=NAVER_CLIENT_ID=...
/// 키가 없으면 자동으로 기존 dev mock 로그인으로 동작한다(테스트/CI 안전).
const String kKakaoRestApiKey = String.fromEnvironment('KAKAO_REST_API_KEY');
const String kNaverClientId = String.fromEnvironment('NAVER_CLIENT_ID');

/// 모바일(안드로이드/iOS) SDK용 카카오 네이티브 앱 키.
/// 네이버 모바일은 빌드 시 환경변수(NAVER_CLIENT_ID/SECRET)로 매니페스트에 주입된다.
const String kKakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

/// 소셜 로그인 후 돌아왔을 때 주소에 실려 오는 값(인가 코드).
class SocialCallback {
  final String provider; // kakao | naver
  final String code;
  final String state;

  const SocialCallback({required this.provider, required this.code, required this.state});
}

/// 웹 리다이렉트 방식 소셜 로그인 도우미.
///
/// 흐름: [start] → 카카오/네이버 로그인 페이지로 이동 → 로그인 후 우리 앱 주소로
/// ?code=...&state=... 를 달고 돌아옴 → 앱 시작 시 [captureRedirectCallback]이 이를
/// 읽어 [pendingCallback]에 보관 → 로그인 화면이 서버로 code를 보내 로그인 완료.
class SocialAuth {
  SocialAuth._();

  static const String _stateKey = 'ovenup_social_state';

  /// 소셜 로그인에서 막 돌아온 경우 그 정보 (없으면 null)
  static SocialCallback? pendingCallback;

  /// 돌아왔지만 실패한 경우의 안내 문구 (없으면 null)
  static String? pendingError;

  /// 이 provider가 실제 로그인 가능한 상태인가? (웹 + 키 주입됨)
  static bool isRealEnabled(String provider) {
    if (!kIsWeb) return false;
    return provider == 'naver' ? kNaverClientId.isNotEmpty : kKakaoRestApiKey.isNotEmpty;
  }

  /// 모바일(안드로이드/iOS)에서 SDK 로그인이 가능한 상태인가? (키 주입됨)
  static bool isMobileRealEnabled(String provider) {
    if (kIsWeb) return false;
    return provider == 'naver' ? kNaverClientId.isNotEmpty : kKakaoNativeAppKey.isNotEmpty;
  }

  /// 인가 요청에 쓰는 리다이렉트 주소 = 현재 앱 주소(origin).
  /// 카카오/네이버 개발자 콘솔에 같은 값이 등록돼 있어야 한다.
  static String get redirectUri => platform.currentOrigin();

  /// 카카오/네이버 로그인 페이지로 이동한다. (페이지 전체가 이동됨)
  static void start(String provider) {
    final state = '$provider.${_randomToken()}';
    platform.writeSessionValue(_stateKey, state);
    final Uri url;
    if (provider == 'naver') {
      url = Uri.parse('https://nid.naver.com/oauth2.0/authorize').replace(queryParameters: {
        'response_type': 'code',
        'client_id': kNaverClientId,
        'redirect_uri': redirectUri,
        'state': state,
      });
    } else {
      url = Uri.parse('https://kauth.kakao.com/oauth/authorize').replace(queryParameters: {
        'response_type': 'code',
        'client_id': kKakaoRestApiKey,
        'redirect_uri': redirectUri,
        'state': state,
      });
    }
    platform.redirectTo(url.toString());
  }

  /// 앱 시작 직후 1회 호출: 주소창의 code/state를 읽어 보관하고 주소를 정리한다.
  static void captureRedirectCallback() {
    if (!kIsWeb) return;
    final params = Uri.base.queryParameters;
    final code = params['code'];
    final state = params['state'];
    final error = params['error'];
    if (code == null && error == null) return;

    platform.cleanUrl();
    final savedState = platform.readSessionValue(_stateKey);
    platform.removeSessionValue(_stateKey);

    if (error != null) {
      pendingError = '소셜 로그인이 취소되었어요. 다시 시도해 주세요.';
      return;
    }
    if (state == null || savedState == null || savedState != state) {
      // state 불일치 = 우리가 시작한 로그인이 아님(보안). 코드는 사용하지 않는다.
      pendingError = '로그인 요청이 만료되었어요. 다시 시도해 주세요.';
      return;
    }
    final provider = state.startsWith('naver.') ? 'naver' : 'kakao';
    pendingCallback = SocialCallback(provider: provider, code: code!, state: state);
  }

  static String _randomToken() {
    final rand = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
