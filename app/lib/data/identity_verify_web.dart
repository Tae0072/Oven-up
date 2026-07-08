/// 웹 전용 — PortOne V2 브라우저 SDK(JS)로 본인인증 창을 띄운다.
/// (web/index.html 에서 https://cdn.portone.io/v2/browser-sdk.js 를 로드해 둠)
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

import 'identity_verify.dart' show newIdentityVerificationId;
import 'payment_config.dart';

@JS('PortOne.requestIdentityVerification')
external JSPromise<JSObject?> _requestIdentityVerification(JSObject options);

/// 본인인증 창을 띄우고, 성공하면 identityVerificationId를 돌려준다. 취소/실패 시 예외.
Future<String?> requestIdentityVerification(BuildContext context) async {
  final id = newIdentityVerificationId();
  final options = <String, Object?>{
    'storeId': kPortoneStoreId,
    'channelKey': kPortoneChannelKeyIdentity,
    'identityVerificationId': id,
  }.jsify()! as JSObject;

  final JSObject? result = await _requestIdentityVerification(options).toDart;
  if (result == null) {
    throw Exception('본인인증 결과를 받지 못했어요.');
  }
  final JSAny? code = result.getProperty('code'.toJS);
  if (code != null && !code.isUndefinedOrNull) {
    final JSAny? message = result.getProperty('message'.toJS);
    throw Exception(message?.dartify()?.toString() ?? '본인인증이 취소되었어요.');
  }
  return id;
}
