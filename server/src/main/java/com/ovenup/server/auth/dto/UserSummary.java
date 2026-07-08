package com.ovenup.server.auth.dto;

/** 로그인 응답에 담기는 간단한 회원 정보 (05_API §2.2) */
public record UserSummary(long id, String name, String role) {
}
