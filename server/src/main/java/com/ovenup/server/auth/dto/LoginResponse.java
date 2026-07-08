package com.ovenup.server.auth.dto;

/** 로그인 응답 (05_API §2.2) */
public record LoginResponse(String accessToken, UserSummary user) {
}
