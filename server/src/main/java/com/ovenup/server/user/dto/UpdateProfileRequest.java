package com.ovenup.server.user.dto;

/** 프로필 수정 요청. null인 항목은 바꾸지 않는다. (이름·연락처·닉네임·주소) */
public record UpdateProfileRequest(String name, String phone, String nickname, String address) {
}
