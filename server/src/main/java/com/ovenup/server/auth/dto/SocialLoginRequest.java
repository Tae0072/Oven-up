package com.ovenup.server.auth.dto;

/** 소셜 로그인 요청 (05_API §2.3). 앱이 카카오/네이버에서 받은 액세스 토큰을 전달. */
public record SocialLoginRequest(String accessToken) {
}
