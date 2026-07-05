/// PortOne(포트원) 결제 설정.
/// 실행 시 --dart-define 으로 주입한다(키를 코드에 하드코딩하지 않음).
/// 예) --dart-define=PORTONE_STORE_ID=store-... --dart-define=PORTONE_CHANNEL_KEY=channel-key-...
/// 값이 없으면 기존 dev mock 결제로 동작한다(테스트/CI 안전).
const String kPortoneStoreId = String.fromEnvironment('PORTONE_STORE_ID');

/// 기본 채널 키. PortOne에서 "어느 결제사 창을 열지"는 채널 키가 결정한다.
const String kPortoneChannelKey = String.fromEnvironment('PORTONE_CHANNEL_KEY');

/// 결제수단별 채널 키 (선택). 콘솔에 결제사 채널을 추가로 만들었을 때 주입한다.
/// 예) 카드용 KG이니시스 테스트 채널 → --dart-define=PORTONE_CHANNEL_KEY_CARD=channel-key-...
/// 지정하지 않은 수단은 기본 채널(kPortoneChannelKey)로 열린다.
const String _channelKeyCard = String.fromEnvironment('PORTONE_CHANNEL_KEY_CARD');
const String _channelKeyKakaopay = String.fromEnvironment('PORTONE_CHANNEL_KEY_KAKAOPAY');
const String _channelKeyNaverpay = String.fromEnvironment('PORTONE_CHANNEL_KEY_NAVERPAY');
const String _channelKeyTosspay = String.fromEnvironment('PORTONE_CHANNEL_KEY_TOSSPAY');

/// 실제 결제창(PortOne)을 띄울 수 있는 상태인가?
bool get isRealPaymentEnabled => kPortoneStoreId.isNotEmpty && kPortoneChannelKey.isNotEmpty;

/// 앱 결제수단 코드 → 사용할 채널 키. (수단별 키가 없으면 기본 채널)
String portoneChannelKey(String methodCode) {
  final specific = switch (methodCode) {
    'CARD' => _channelKeyCard,
    'KAKAOPAY' => _channelKeyKakaopay,
    'NAVERPAY' => _channelKeyNaverpay,
    'TOSSPAY' => _channelKeyTosspay,
    _ => '',
  };
  return specific.isNotEmpty ? specific : kPortoneChannelKey;
}

/// 앱 결제수단 코드 → PortOne V2 payMethod 문자열.
/// 카드는 CARD, 간편결제(카카오페이 등)는 EASY_PAY. (실제 가능 여부는 콘솔의 채널 설정을 따름)
String portonePayMethod(String methodCode) =>
    methodCode == 'CARD' ? 'CARD' : 'EASY_PAY';
