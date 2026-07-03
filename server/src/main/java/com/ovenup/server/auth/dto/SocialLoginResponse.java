package com.ovenup.server.auth.dto;

/** 소셜 로그인 응답 (05_API §2.3). isNew=첫 로그인(자동 회원가입) 여부. */
public record SocialLoginResponse(String accessToken, UserSummary user, boolean isNew) {
}
