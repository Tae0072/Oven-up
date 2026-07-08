package com.ovenup.server.notification;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.GoogleCredentials;

/**
 * 실제 FCM(HTTP v1) 푸시 발송기 (app.push.mock=false).
 *
 * 동작: 손님(userId)의 기기 토큰들을 조회 → 서비스 계정으로 구글 액세스 토큰 발급 →
 *       FCM v1 API로 각 기기에 알림 전송. 만료/무효 토큰(UNREGISTERED)은 삭제한다.
 *
 * 준비물(환경변수, 커밋 금지):
 * - FIREBASE_SERVICE_ACCOUNT : 서비스 계정 키 JSON 파일 경로 (예: D:\ai제작\firebase-service-account.json)
 *   프로젝트 ID는 키 파일 안의 project_id 를 그대로 읽는다.
 */
@Component
@ConditionalOnProperty(name = "app.push.mock", havingValue = "false")
public class RealPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(RealPushSender.class);
    private static final String FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

    private final DeviceTokenRepository deviceTokenRepository;
    private final RestClient restClient = RestClient.create();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final String serviceAccountPath;
    private GoogleCredentials credentials; // 지연 초기화
    private String projectId;

    public RealPushSender(DeviceTokenRepository deviceTokenRepository,
                          @Value("${app.push.service-account:}") String serviceAccountPath) {
        this.deviceTokenRepository = deviceTokenRepository;
        this.serviceAccountPath = serviceAccountPath;
    }

    @Override
    @Transactional
    public void send(Long userId, String title, String body) {
        List<DeviceTokenEntity> tokens = deviceTokenRepository.findByUserId(userId);
        if (tokens.isEmpty()) {
            log.info("[PUSH] userId={} 등록된 기기 토큰 없음 (인앱 알림만 저장됨)", userId);
            return;
        }
        String accessToken;
        try {
            accessToken = accessToken();
        } catch (Exception e) {
            log.warn("[PUSH] 구글 인증 실패(FIREBASE_SERVICE_ACCOUNT 확인): {}", e.toString());
            return;
        }
        for (DeviceTokenEntity device : tokens) {
            sendToDevice(device, title, body, accessToken);
        }
    }

    private void sendToDevice(DeviceTokenEntity device, String title, String body, String accessToken) {
        Map<String, Object> message = Map.of("message", Map.of(
                "token", device.getToken(),
                "notification", Map.of("title", title, "body", body)));
        try {
            restClient.post()
                    .uri("https://fcm.googleapis.com/v1/projects/{p}/messages:send", projectId)
                    .header("Authorization", "Bearer " + accessToken)
                    .body(message)
                    .retrieve()
                    .toBodilessEntity();
            log.info("[PUSH] 발송 성공 userId={} tokenId={}", device.getUserId(), device.getId());
        } catch (RestClientResponseException e) {
            String responseBody = e.getResponseBodyAsString();
            if (responseBody.contains("UNREGISTERED") || responseBody.contains("INVALID_ARGUMENT")) {
                // 앱 삭제/토큰 만료 → 조용히 정리
                deviceTokenRepository.deleteByToken(device.getToken());
                log.info("[PUSH] 만료 토큰 정리 tokenId={}", device.getId());
            } else {
                log.warn("[PUSH] 발송 실패 status={} body={}", e.getStatusCode(), responseBody);
            }
        } catch (Exception e) {
            log.warn("[PUSH] 발송 오류: {}", e.toString());
        }
    }

    /** 서비스 계정 키로 FCM 호출용 액세스 토큰을 얻는다 (자동 캐시/갱신). */
    private synchronized String accessToken() throws IOException {
        if (credentials == null) {
            if (serviceAccountPath == null || serviceAccountPath.isBlank()) {
                throw new IOException("FIREBASE_SERVICE_ACCOUNT 환경변수가 설정되지 않았습니다.");
            }
            try (FileInputStream in = new FileInputStream(serviceAccountPath)) {
                credentials = GoogleCredentials.fromStream(in).createScoped(FCM_SCOPE);
            }
            try (FileInputStream in = new FileInputStream(serviceAccountPath)) {
                JsonNode json = objectMapper.readTree(in);
                projectId = json.path("project_id").asText();
            }
        }
        credentials.refreshIfExpired();
        return credentials.getAccessToken().getTokenValue();
    }
}
