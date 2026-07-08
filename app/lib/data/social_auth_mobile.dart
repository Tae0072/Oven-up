import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// 모바일(안드로이드/iOS) 전용 — 카카오/네이버 공식 SDK로 로그인해
/// "사용자 액세스 토큰"을 받아온다. 이 토큰을 우리 서버에 보내면
/// 서버(RealSocialProfileVerifier)가 진짜인지 확인한다.
class SocialMobileAuth {
  SocialMobileAuth._();

  /// 로그인 후 액세스 토큰 반환. 취소/실패 시 예외.
  static Future<String> login(String provider) async {
    if (provider == 'naver') {
      return _naver();
    }
    return _kakao();
  }

  static Future<String> _kakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        // 카카오톡 앱이 있으면 앱으로 로그인 (더 편함)
        token = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (e) {
        // 사용자가 직접 취소한 경우는 그대로 알림
        if (e.code == 'CANCELED') rethrow;
        // 그 외(카카오톡 미로그인 등)는 계정(웹) 로그인으로 재시도
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      // 카카오톡이 없으면 브라우저 계정 로그인
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    return token.accessToken;
  }

  static Future<String> _naver() async {
    final NaverLoginResult res = await FlutterNaverLogin.logIn();
    if (res.status != NaverLoginStatus.loggedIn) {
      throw PlatformException(
          code: 'CANCELED', message: res.errorMessage ?? '네이버 로그인이 취소되었어요.');
    }
    final NaverToken token =
        res.accessToken ?? await FlutterNaverLogin.getCurrentAccessToken();
    return token.accessToken;
  }
}
