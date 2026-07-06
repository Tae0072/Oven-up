package com.ovenup.server.user.dto;

/** 내 정보 응답 (05_API §2.4) */
public record MyProfile(long id, String email, String loginId, String name, String nickname,
                        String phone, String address, String role,
                        int pointBalance, boolean notifyEnabled) {
}
