/// 모바일 전용 — PortOne 공식 Flutter SDK(웹뷰)로 본인인증 창을 띄운다.
library;

import 'package:flutter/material.dart';
import 'package:portone_flutter/v2/model/request/identity_verification_request.dart';
import 'package:portone_flutter/v2/model/response/identity_verification_response.dart';
import 'package:portone_flutter/v2/portone_identity_verification.dart';

import 'identity_verify.dart' show newIdentityVerificationId;
import 'payment_config.dart';

/// 본인인증 화면을 띄우고, 성공하면 identityVerificationId를 돌려준다. 취소/실패 시 null.
Future<String?> requestIdentityVerification(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (routeCtx) => PortoneIdentityVerification(
        appBar: AppBar(title: const Text('휴대폰 본인인증')),
        initialChild: const Center(child: CircularProgressIndicator()),
        appScheme: 'ovenup',
        data: IdentityVerificationRequest(
          storeId: kPortoneStoreId,
          identityVerificationId: newIdentityVerificationId(),
          channelKey: kPortoneChannelKeyIdentity,
        ),
        callback: (IdentityVerificationResponse response) {
          final code = response.code;
          if (code != null && code.isNotEmpty) {
            Navigator.of(routeCtx).pop(); // 실패/취소
          } else {
            Navigator.of(routeCtx).pop(response.identityVerificationId);
          }
        },
      ),
    ),
  );
}
