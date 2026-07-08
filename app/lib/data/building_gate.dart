import 'package:geolocator/geolocator.dart';

import 'building_config.dart';

/// 현재 위치 확인 결과.
/// - inside: 건물 반경 안 (좌표 포함) → 주문 진행
/// - outside: 건물 반경 밖 (좌표 포함) → 주문 차단
/// - permissionDenied: 위치 권한 거부 → 차단 + 설정 바로가기 안내
/// - serviceDisabled: 기기 위치(GPS) 꺼짐 → 차단 + 위치 설정 바로가기 안내
/// - unknown: 시간 초과 등 확인 실패 → 차단 (위치 필수 정책)
///   ※ 서버도 좌표 없는 주문을 거절하므로(LOCATION_REQUIRED) 앱에서 미리 안내한다.
enum BuildingCheckResult { inside, outside, permissionDenied, serviceDisabled, unknown }

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
      return const BuildingCheck(BuildingCheckResult.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const BuildingCheck(BuildingCheckResult.permissionDenied);
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // 실내에서 첫 위치를 잡는 데 시간이 걸릴 수 있어 넉넉히 준다 (위치 필수 정책)
        timeLimit: Duration(seconds: 15),
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
    // 시간 초과, 위치 서비스 오류 등 — 확인 실패
    return const BuildingCheck(BuildingCheckResult.unknown);
  }
}

/// 앱의 위치 권한 설정 화면 열기 (모바일 전용 — 웹은 false 반환)
Future<bool> openAppPermissionSettings() {
  try {
    return Geolocator.openAppSettings();
  } catch (_) {
    return Future.value(false);
  }
}

/// 기기의 위치(GPS) 설정 화면 열기 (모바일 전용 — 웹은 false 반환)
Future<bool> openDeviceLocationSettings() {
  try {
    return Geolocator.openLocationSettings();
  } catch (_) {
    return Future.value(false);
  }
}
