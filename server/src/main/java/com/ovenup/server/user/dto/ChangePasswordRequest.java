package com.ovenup.server.user.dto;

/** 비밀번호 변경 요청 (현재 비밀번호 확인 후 새 비밀번호로 교체) */
public record ChangePasswordRequest(String currentPassword, String newPassword) {
}
