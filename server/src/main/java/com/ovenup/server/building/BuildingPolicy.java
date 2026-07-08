package com.ovenup.server.building;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 서비스 대상 건물(명지에코펠리스) 정책.
 * 이 앱은 상가 건물 하나 안에서만 쓰는 전용 앱이라,
 * - 주소는 건물 주소만 허용하고 (등록·수정·주문 모두 서버가 재검증)
 * - 주문 시 보낸 현재 위치(GPS)가 건물 반경 안인지 보조 확인한다.
 * 값은 application.properties의 app.building.* 로 바꿀 수 있다 (건물 이전 대비).
 */
@Component
public class BuildingPolicy {

    private final String name;
    private final String roadAddress;
    private final double lat;
    private final double lng;
    private final double radiusMeters;

    public BuildingPolicy(
            @Value("${app.building.name:명지에코펠리스}") String name,
            @Value("${app.building.road-address:부산 강서구 명지국제2로28번길 34}") String roadAddress,
            @Value("${app.building.lat:35.0928292}") double lat,
            @Value("${app.building.lng:128.9088756}") double lng,
            @Value("${app.building.radius-m:250}") double radiusMeters) {
        this.name = name;
        this.roadAddress = roadAddress;
        this.lat = lat;
        this.lng = lng;
        this.radiusMeters = radiusMeters;
    }

    public String name() {
        return name;
    }

    /** 주소 문자열이 건물 주소인지 (건물명 또는 도로명주소 포함 — 공백 무시) */
    public boolean isAddressAllowed(String address) {
        if (address == null || address.isBlank()) {
            return false;
        }
        String norm = address.replace(" ", "");
        return norm.contains(name.replace(" ", ""))
                || norm.contains(roadAddress.replace(" ", ""));
    }

    /** 좌표가 건물 허용 반경 안인지 (실내 GPS 오차를 고려해 반경을 여유 있게 둔다) */
    public boolean isWithinRadius(double userLat, double userLng) {
        return distanceMeters(userLat, userLng) <= radiusMeters;
    }

    /** 하버사인 공식으로 건물 중심과의 거리(미터) */
    public double distanceMeters(double userLat, double userLng) {
        final double earthRadius = 6371000;
        double dLat = Math.toRadians(userLat - lat);
        double dLng = Math.toRadians(userLng - lng);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat)) * Math.cos(Math.toRadians(userLat))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return 2 * earthRadius * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
