package com.ovenup.server.user.dto;

/** 프로필 수정 요청 (이름·연락처) */
public record UpdateProfileRequest(String name, String phone) {
}
