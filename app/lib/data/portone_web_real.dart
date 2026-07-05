/// 웹 전용 — PortOne V2 브라우저 SDK(JS)로 결제창을 띄운다.
/// (web/index.html 에서 https://cdn.portone.io/v2/browser-sdk.js 를 로드해 둠)
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'payment_config.dart';

@JS('PortOne.requestPayment')
external JSPromise<JSObject?> _requestPayment(JSObject options);

/// 결제창을 띄우고, 성공하면 paymentId(서버 검증용 결제 식별자)를 돌려준다.
/// 취소/실패 시 예외를 던진다.
Future<String> requestPaymentWeb({
  required String paymentId,
  required String orderName,
  required int amount,
  required String payMethod,
}) async {
  final options = <String, Object?>{
    'storeId': kPortoneStoreId,
    'channelKey': kPortoneChannelKey,
    'paymentId': paymentId,
    'orderName': orderName,
    'totalAmount': amount,
    'currency': 'CURRENCY_KRW',
    'payMethod': payMethod,
  }.jsify()! as JSObject;

  final JSObject? result = await _requestPayment(options).toDart;
  if (result == null) {
    throw Exception('결제 결과를 받지 못했어요.');
  }
  // 실패/취소 시 code·message 가 들어온다 (성공 시 code 없음)
  final JSAny? code = result.getProperty('code'.toJS);
  if (code != null && !code.isUndefinedOrNull) {
    final JSAny? message = result.getProperty('message'.toJS);
    throw Exception(message?.dartify()?.toString() ?? '결제가 취소되었어요.');
  }
  final JSAny? resultPaymentId = result.getProperty('paymentId'.toJS);
  return resultPaymentId?.dartify()?.toString() ?? paymentId;
}
