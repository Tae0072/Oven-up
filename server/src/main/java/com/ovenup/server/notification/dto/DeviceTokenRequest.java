package com.ovenup.server.notification.dto;

/** 기기 토큰 등록 요청 (가이드 §3-1). 앱이 FCM에서 받은 토큰을 보낸다. */
public record DeviceTokenRequest(String token) {
}
