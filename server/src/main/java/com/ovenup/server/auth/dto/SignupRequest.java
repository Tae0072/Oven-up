package com.ovenup.server.auth.dto;

/** 회원가입 요청 (05_API §2.1) */
public record SignupRequest(String email, String password, String name, String phone) {
}
