package com.ovenup.server.auth.dto;

/**
 * 회원가입 요청 (05_API §2.1) — 아이디·비밀번호·전화번호·이메일·주소.
 * identityVerificationId: 휴대폰 본인인증(PASS식) 완료 ID — 있으면 서버가 PortOne에 재검증한다.
 */
public record SignupRequest(String loginId, String email, String password,
                            String name, String phone, String address,
                            String identityVerificationId) {
}
