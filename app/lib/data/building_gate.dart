import 'package:geolocator/geolocator.dart';

import 'building_config.dart';

/// 현재 위치 확인 결과.
/// - inside: 건물 반경 안 (좌표 포함)
/// - outside: 건물 반경 밖 (좌표 포함) → 주문 차단
/// - unknown: 권한 거부·시간 초과 등으로 확인 불가 → 통과 (주소는 이미 건물로 고정돼 있어 보조 확인만 한다)
enum BuildingCheckResult { inside, outside, unknown }

class BuildingCheck {
  final BuildingCheckResult result;
  final double? lat;
  final double? lng;
  final double? distanceMeters;

  const BuildingCheck(this.result, {this.lat, this.lng, this.distanceMeters});
}

/// 현재 위치가 명지에코펠리스 반경 안인지 확인한다.
/// 웹은 브라우저 위치 권한, 모바일은 OS 위치 권한을 사용한다.
Future<BuildingCheck> checkInsideBuilding() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const BuildingCheck(BuildingCheckResult.unknown);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const BuildingCheck(BuildingCheckResult.unknown);
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, kBuildingLat, kBuildingLng);
    final inside = distance <= kBuildingRadiusMeters;
    return BuildingCheck(
      inside ? BuildingCheckResult.inside : BuildingCheckResult.outside,
      lat: pos.latitude,
      lng: pos.longitude,
      distanceMeters: distance,
    );
  } catch (_) {
    // 시간 초과, 위치 서비스 오류 등 — 확인 불가로 처리 (차단하지 않음)
    return const BuildingCheck(BuildingCheckResult.unknown);
  }
}
