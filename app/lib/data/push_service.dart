import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_api.dart';

/// 푸시 알림(FCM) 도우미 — 모바일(안드로이드/iOS) 전용.
///
/// 흐름: 앱 시작 시 [init] → 로그인 후 [registerToken] 이
/// 1) 알림 권한을 요청하고 2) 이 기기의 FCM 토큰을 받아 3) 서버에 등록한다.
/// 서버는 결제완료/주문상태 변경 때 이 토큰으로 OS 푸시를 보낸다.
///
/// google-services.json 이 없거나 웹이면 조용히 아무것도 안 한다(개발 mock 흐름 유지).
class PushService {
  PushService._();

  static bool _ready = false;

  /// 앱 시작 시 1회 호출. Firebase 초기화 (실패해도 앱은 정상 동작).
  static Future<void> init() async {
    if (kIsWeb) return; // 웹 푸시는 추후 별도 설정(VAPID/서비스워커) 필요
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      // google-services.json 미설정 등 — 푸시 없이 동작
      debugPrint('[PUSH] Firebase 초기화 안 됨(푸시 비활성): $e');
    }
  }

  /// 로그인 후 호출: 권한 요청 → FCM 토큰 획득 → 서버 등록.
  /// 토큰이 갱신되면 자동으로 다시 등록한다.
  static Future<void> registerToken(String? authToken) async {
    if (!_ready || authToken == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(); // Android 13+/iOS 알림 권한
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        await NotificationApi().registerDeviceToken(token: authToken, fcmToken: fcmToken);
        debugPrint('[PUSH] 기기 토큰 등록 완료');
      }
      messaging.onTokenRefresh.listen((newToken) {
        NotificationApi()
            .registerDeviceToken(token: authToken, fcmToken: newToken)
            .catchError((Object _) {});
      });
    } catch (e) {
      debugPrint('[PUSH] 토큰 등록 실패(푸시 없이 계속): $e');
    }
  }
}
