package com.ovenup.server.social;

/**
 * 소셜 액세스 토큰을 확인해 사용자 정보를 돌려주는 창구.
 * - 로컬/테스트: MockSocialProfileVerifier (app.social.mock=true, 기본)
 * - 실제: RealSocialProfileVerifier (app.social.mock=false, 카카오/네이버 API 호출)
 */
public interface SocialProfileVerifier {

    /** provider = "kakao" | "naver". 토큰이 유효하지 않으면 ApiException(401)을 던진다. */
    SocialProfile verify(String provider, String accessToken);
}
