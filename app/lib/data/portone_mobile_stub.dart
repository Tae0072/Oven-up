/// 웹 빌드용 빈 구현 (모바일 결제창 위젯은 안드로이드/iOS에서만 사용).
library;

import 'package:flutter/widgets.dart';

Widget buildPortonePaymentView({
  required String paymentId,
  required String orderName,
  required int amount,
  required String payMethod,
  required String channelKey,
  required String customerName,
  required void Function(String paymentId) onSuccess,
  required void Function(String message) onFail,
}) {
  throw UnsupportedError('모바일에서만 지원하는 결제 방식입니다.');
}
