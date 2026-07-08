package com.ovenup.server.auth.dto;

/**
 * 소셜 로그인 요청 (05_API §2.3). 두 가지 방식 중 하나로 보낸다.
 * 1) accessToken: 앱이 카카오/네이버 SDK로 직접 받은 액세스 토큰 (모바일 SDK 방식)
 * 2) code(+redirectUri, state): 웹 리다이렉트 로그인에서 받은 인가 코드.
 *    서버가 카카오/네이버 토큰 API로 교환해 검증한다. (웹 방식 — 시크릿이 서버에만 있음)
 */
public record SocialLoginRequest(String accessToken, String code, String redirectUri, String state) {
}
