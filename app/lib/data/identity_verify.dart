import 'package:flutter/widgets.dart';

import 'identity_verify_stub.dart'
    if (dart.library.js_interop) 'identity_verify_web.dart'
    if (dart.library.io) 'identity_verify_mobile.dart' as impl;

/// 휴대폰 본인인증(PASS식) 창을 열고, 성공하면 본인인증 ID를 돌려준다.
/// 취소/실패하면 null. (검증·정보조회는 서버가 PortOne API로 수행)
Future<String?> requestIdentityVerification(BuildContext context) =>
    impl.requestIdentityVerification(context);

/// 본인인증 건마다 쓰는 고유 ID 생성
String newIdentityVerificationId() =>
    'identity-${DateTime.now().millisecondsSinceEpoch}-${UniqueKey().hashCode}';
