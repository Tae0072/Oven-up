package com.ovenup.server.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 개발용 모의 푸시 발송기 (app.push.mock=true, 기본).
 * 실제 기기 푸시는 보내지 않고 로그만 남긴다. 인앱 알림(저장/조회)은 정상 동작.
 */
@Component
@ConditionalOnProperty(name = "app.push.mock", havingValue = "true", matchIfMissing = true)
public class MockPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(MockPushSender.class);

    @Override
    public void send(Long userId, String title, String body) {
        log.info("[MOCK-PUSH] userId={} title='{}' body='{}'", userId, title, body);
    }
}
