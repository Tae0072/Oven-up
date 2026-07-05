package com.ovenup.server.user.dto;

/** 내 정보 응답 (05_API §2.4) */
public record MyProfile(long id, String email, String name, String phone, String role,
                        int pointBalance, boolean notifyEnabled) {
}
