package com.ovenup.server.auth.dto;

/** 회원가입 요청 (05_API §2.1) — 아이디·비밀번호·전화번호·이메일·주소 */
public record SignupRequest(String loginId, String email, String password,
                            String name, String phone, String address) {
}
