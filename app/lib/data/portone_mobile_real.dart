/// 모바일(안드로이드/iOS) 전용 — PortOne 공식 Flutter SDK(웹뷰)로 결제창을 띄운다.
library;

import 'package:flutter/material.dart';
import 'package:portone_flutter/v2/model/entity/currency.dart';
import 'package:portone_flutter/v2/model/entity/payment_pay_method.dart';
import 'package:portone_flutter/v2/model/request/payment_request.dart';
import 'package:portone_flutter/v2/model/response/payment_response.dart';
import 'package:portone_flutter/v2/portone_payment.dart';

import 'payment_config.dart';

/// PortOne 결제창 화면(위젯). 성공 시 [onSuccess]에 paymentId, 실패 시 [onFail]에 메시지.
Widget buildPortonePaymentView({
  required String paymentId,
  required String orderName,
  required int amount,
  required String payMethod,
  required String channelKey,
  required void Function(String paymentId) onSuccess,
  required void Function(String message) onFail,
}) {
  return PortonePayment(
    appBar: AppBar(title: const Text('결제')),
    initialChild: const Center(child: CircularProgressIndicator()),
    data: PaymentRequest(
      storeId: kPortoneStoreId,
      channelKey: channelKey,
      payMethod: payMethod == 'CARD' ? PaymentPayMethod.CARD : PaymentPayMethod.EASY_PAY,
      orderName: orderName,
      totalAmount: amount,
      currency: Currency.KRW,
      paymentId: paymentId,
      appScheme: 'ovenup',
    ),
    callback: (PaymentResponse response) {
      final code = response.code;
      if (code != null && code.isNotEmpty) {
        onFail(response.message ?? '결제가 취소되었어요.');
      } else {
        onSuccess(response.paymentId);
      }
    },
  );
}
