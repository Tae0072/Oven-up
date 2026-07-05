/// PortOne(포트원) 결제 설정.
/// 실행 시 --dart-define 으로 주입한다(키를 코드에 하드코딩하지 않음).
/// 예) --dart-define=PORTONE_STORE_ID=store-... --dart-define=PORTONE_CHANNEL_KEY=channel-key-...
/// 값이 없으면 기존 dev mock 결제로 동작한다(테스트/CI 안전).
const String kPortoneStoreId = String.fromEnvironment('PORTONE_STORE_ID');
const String kPortoneChannelKey = String.fromEnvironment('PORTONE_CHANNEL_KEY');

/// 실제 결제창(PortOne)을 띄울 수 있는 상태인가?
bool get isRealPaymentEnabled => kPortoneStoreId.isNotEmpty && kPortoneChannelKey.isNotEmpty;

/// 앱 결제수단 코드 → PortOne V2 payMethod 문자열.
/// 카드는 CARD, 간편결제(카카오페이 등)는 EASY_PAY. (실제 가능 여부는 콘솔의 채널 설정을 따름)
String portonePayMethod(String methodCode) =>
    methodCode == 'CARD' ? 'CARD' : 'EASY_PAY';
