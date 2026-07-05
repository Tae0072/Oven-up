package com.ovenup.server.social;

/**
 * OAuth 인가 코드(code)를 액세스 토큰으로 바꿔주는 창구.
 * 웹 로그인은 "카카오/네이버 페이지로 이동 → 인가 코드 반환" 방식이라,
 * 코드를 토큰으로 교환하는 단계가 필요하다. (교환에 쓰는 키/시크릿은 서버에만 둔다)
 */
public interface SocialAuthCodeExchanger {

    /**
     * @param provider    kakao | naver
     * @param code        소셜 로그인 후 돌려받은 인가 코드
     * @param redirectUri 인가 요청에 사용한 리다이렉트 주소 (카카오는 동일 값 필수)
     * @param state       인가 요청에 사용한 state (네이버 필수)
     * @return 소셜 액세스 토큰
     */
    String exchange(String provider, String code, String redirectUri, String state);
}
