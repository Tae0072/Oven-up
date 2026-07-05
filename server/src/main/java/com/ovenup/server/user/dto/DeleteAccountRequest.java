package com.ovenup.server.user.dto;

/** 회원 탈퇴 요청 (현재 비밀번호 확인) */
public record DeleteAccountRequest(String currentPassword) {
}
