/// 12900 -> "12,900원" 처럼 천 단위 콤마를 붙여 준다.
/// (intl 패키지 없이 간단히 구현 — 입문자용으로 의존성 최소화)
String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  buffer.write('원');
  return buffer.toString();
}
