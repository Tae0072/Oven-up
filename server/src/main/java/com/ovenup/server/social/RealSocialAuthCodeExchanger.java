package com.ovenup.server.social;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import com.ovenup.server.common.ApiException;

/**
 * 실제 카카오/네이버 토큰 API로 인가 코드를 액세스 토큰으로 교환한다.
 * app.social.mock=false 일 때만 활성화.
 * - 카카오: POST https://kauth.kakao.com/oauth/token   (REST API 키, Client Secret은 콘솔에서 켠 경우만)
 * - 네이버: POST https://nid.naver.com/oauth2.0/token  (Client ID/Secret 필요)
 * 키는 환경변수로만 주입한다(코드/설정에 하드코딩 금지, 커밋 금지).
 */
@Component
@ConditionalOnProperty(name = "app.social.mock", havingValue = "false")
public class RealSocialAuthCodeExchanger implements SocialAuthCodeExchanger {

    private static final Logger log = LoggerFactory.getLogger(RealSocialAuthCodeExchanger.class);

    private final RestClient restClient = RestClient.create();

    private final String kakaoRestApiKey;
    private final String kakaoClientSecret;
    private final String naverClientId;
    private final String naverClientSecret;

    public RealSocialAuthCodeExchanger(
            @Value("${app.social.kakao.rest-api-key:}") String kakaoRestApiKey,
            @Value("${app.social.kakao.client-secret:}") String kakaoClientSecret,
            @Value("${app.social.naver.client-id:}") String naverClientId,
            @Value("${app.social.naver.client-secret:}") String naverClientSecret) {
        this.kakaoRestApiKey = kakaoRestApiKey;
        this.kakaoClientSecret = kakaoClientSecret;
        this.naverClientId = naverClientId;
        this.naverClientSecret = naverClientSecret;
    }

    @Override
    public String exchange(String provider, String code, String redirectUri, String state) {
        String p = provider == null ? "" : provider.toLowerCase();
        try {
            if ("kakao".equals(p)) {
                return kakao(code, redirectUri);
            }
            if ("naver".equals(p)) {
                return naver(code, state);
            }
        } catch (ApiException e) {
            throw e;
        } catch (RestClientResponseException e) {
            // 어디서 왜 거절됐는지 서버 로그에 남긴다 (원인 진단용)
            log.warn("[SOCIAL] {} 코드 교환 거절: status={} body={}", p, e.getStatusCode(),
                    e.getResponseBodyAsString());
            throw ApiException.unauthorized("SOCIAL_CODE_EXCHANGE_FAILED", "소셜 인증 코드 교환에 실패했어요.");
        } catch (Exception e) {
            log.warn("[SOCIAL] {} 코드 교환 오류: {}", p, e.toString());
            throw ApiException.unauthorized("SOCIAL_CODE_EXCHANGE_FAILED", "소셜 인증 코드 교환에 실패했어요.");
        }
        throw ApiException.badRequest("UNSUPPORTED_PROVIDER", "지원하지 않는 소셜 로그인입니다.");
    }

    private String kakao(String code, String redirectUri) {
        requireConfigured(kakaoRestApiKey, "KAKAO_REST_API_KEY");
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "authorization_code");
        form.add("client_id", kakaoRestApiKey);
        form.add("redirect_uri", redirectUri == null ? "" : redirectUri);
        form.add("code", code);
        if (kakaoClientSecret != null && !kakaoClientSecret.isBlank()) {
            // 카카오 콘솔 [보안]에서 Client Secret을 "사용함"으로 켠 경우 필수
            form.add("client_secret", kakaoClientSecret);
        }
        return postForToken("https://kauth.kakao.com/oauth/token", form, "카카오");
    }

    private String naver(String code, String state) {
        requireConfigured(naverClientId, "NAVER_CLIENT_ID");
        requireConfigured(naverClientSecret, "NAVER_CLIENT_SECRET");
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "authorization_code");
        form.add("client_id", naverClientId);
        form.add("client_secret", naverClientSecret);
        form.add("code", code);
        form.add("state", state == null ? "" : state);
        return postForToken("https://nid.naver.com/oauth2.0/token", form, "네이버");
    }

    private String postForToken(String url, MultiValueMap<String, String> form, String label) {
        Map<?, ?> body = restClient.post().uri(url)
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form)
                .retrieve()
                .body(Map.class);
        if (body == null || body.get("access_token") == null) {
            log.warn("[SOCIAL] {} 토큰 응답에 access_token 없음: {}", label, body);
            throw ApiException.unauthorized("SOCIAL_CODE_INVALID", label + " 인증 코드가 유효하지 않아요.");
        }
        return body.get("access_token").toString();
    }

    private void requireConfigured(String value, String envName) {
        if (value == null || value.isBlank()) {
            throw ApiException.badRequest("SOCIAL_KEY_MISSING",
                    "서버에 " + envName + " 환경변수가 설정되지 않았어요.");
        }
    }
}
