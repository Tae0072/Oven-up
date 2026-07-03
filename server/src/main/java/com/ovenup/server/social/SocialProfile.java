package com.ovenup.server.social;

/**
 * 소셜(카카오/네이버)에서 확인한 사용자 정보.
 * - provider: KAKAO / NAVER
 * - providerUserId: 소셜이 준 고유 사용자 id
 * - name: 표시 이름(닉네임), email: 있으면 자체 계정과 연결에 사용(없을 수 있음)
 */
public record SocialProfile(String provider, String providerUserId, String name, String email) {
}
