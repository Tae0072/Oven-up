import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 초기화 도우미.
/// - 모바일: android/app/google-services.json 설정을 사용 (푸시와 동일)
/// - 웹: 아래 웹 앱 구성을 사용 (Firebase 콘솔 > ovenup-web)
///   ※ 웹 apiKey는 원래 공개되는 값이라 코드에 넣어도 안전하다 (권한은 Firebase 규칙이 결정).
const FirebaseOptions kFirebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyAvfKWzs7fJmkIQ0EU0zd-k43qhfcQJJ-8',
  appId: '1:574847401193:web:910d6722bb4afdf922c478',
  messagingSenderId: '574847401193',
  projectId: 'ven-up',
  authDomain: 'ven-up.firebaseapp.com',
  storageBucket: 'ven-up.firebasestorage.app',
);

/// Firebase가 초기화돼 있도록 보장한다. 성공하면 true.
Future<bool> ensureFirebase() async {
  if (Firebase.apps.isNotEmpty) return true;
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: kFirebaseWebOptions);
    } else {
      await Firebase.initializeApp();
    }
    return true;
  } catch (e) {
    debugPrint('[FIREBASE] 초기화 실패: $e');
    return Firebase.apps.isNotEmpty;
  }
}
