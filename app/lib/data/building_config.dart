/// 서비스 대상 건물(명지에코펠리스) 설정.
///
/// 이 앱은 상가 건물 '명지에코펠리스' 안에서만 쓰는 전용 앱이다.
/// - 주소: 건물 주소로 고정하고 층/호수만 입력받는다 (서버도 다시 검증)
/// - 위치: 주문할 때 현재 위치(GPS)가 건물 반경 안인지 보조 확인한다
///
/// 서버 쪽 같은 값: server .../building/BuildingPolicy.java (application.properties app.building.*)
library;

const String kBuildingName = '명지에코펠리스';
const String kBuildingRoadAddress = '부산 강서구 명지국제2로28번길 34';

/// 저장되는 주소의 앞부분. 뒤에 ', 층/호수'가 붙는다.
/// 예: "부산 강서구 명지국제2로28번길 34 명지에코펠리스, 305호"
const String kBuildingBaseAddress = '$kBuildingRoadAddress $kBuildingName';

/// 건물 중심 좌표 (구글지도 기준)
const double kBuildingLat = 35.0928292;
const double kBuildingLng = 128.9088756;

/// 허용 반경(미터). 실내에선 GPS 오차가 수십 m 나므로 여유 있게 둔다.
const double kBuildingRadiusMeters = 250;
