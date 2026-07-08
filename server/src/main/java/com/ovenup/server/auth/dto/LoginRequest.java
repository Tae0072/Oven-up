package com.ovenup.server.auth.dto;

/** 로그인 요청 (05_API §2.2) */
public record LoginRequest(String email, String password) {
}
