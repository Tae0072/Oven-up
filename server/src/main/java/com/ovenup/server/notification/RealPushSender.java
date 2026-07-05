package com.ovenup.server.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 실제 FCM 푸시 발송기 자리 (app.push.mock=false).
 *
 * ⚠️ 실제 FCM 연동은 준비물이 필요해 여기서는 뼈대만 둔다.
 * 완성 방법(가이드: 문서 레포 '가이드/푸시_알림_FCM.md'):
 *  1) Firebase 프로젝트 + 서비스 계정 키
 *  2) 손님 기기의 FCM 토큰을 서버에 저장(기기 토큰 등록 API)
 *  3) 여기서 FCM HTTP v1 API로 해당 토큰에 알림 전송
 *
 * 지금은 로그만 남긴다(인앱 알림은 정상 저장/조회됨).
 */
@Component
@ConditionalOnProperty(name = "app.push.mock", havingValue = "false")
public class RealPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(RealPushSender.class);

    @Override
    public void send(Long userId, String title, String body) {
        // TODO: FCM HTTP v1로 userId의 기기 토큰에 실제 푸시 발송 (가이드 참고)
        log.warn("[REAL-PUSH:미구현] FCM 연동 필요. userId={} title='{}'", userId, title);
    }
}
