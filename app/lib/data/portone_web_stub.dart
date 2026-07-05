/// 웹이 아닌 플랫폼용 빈 구현 (웹 결제창은 웹에서만 사용).
library;

Future<String> requestPaymentWeb({
  required String paymentId,
  required String orderName,
  required int amount,
  required String payMethod,
}) {
  throw UnsupportedError('웹에서만 지원하는 결제 방식입니다.');
}
