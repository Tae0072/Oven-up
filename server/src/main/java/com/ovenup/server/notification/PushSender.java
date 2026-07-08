package com.ovenup.server.notification;

/**
 * 실제 기기 푸시 발송기 (03_기능 §9). FCM 등으로 손님 기기에 알림을 보낸다.
 * - {@link MockPushSender} : 개발용(app.push.mock=true, 기본). 로그만 남기고 실제 발송은 안 함.
 * - {@link RealPushSender} : 실제 FCM 연동 자리(app.push.mock=false). 가이드 참고.
 *
 * 인앱 알림(NotificationEntity 저장)은 항상 만들어지고, 이 PushSender는 "추가로" OS 푸시를 보내는 역할.
 */
public interface PushSender {

    void send(Long userId, String title, String body);
}
