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

/// 수령 방식 코드 → 한글 라벨 (05_API fulfillmentType)
String fulfillmentLabel(String code) {
  switch (code) {
    case 'DINE_IN':
      return '매장식사';
    case 'TAKEOUT':
      return '포장';
    case 'DELIVERY':
      return '배달';
    default:
      return code;
  }
}

/// 서버가 준 날짜/시간 문자열(ISO) → DateTime (없거나 형식 오류면 null)
DateTime? parseServerDateTime(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

/// DateTime → "2026-07-03 14:30"
String formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
