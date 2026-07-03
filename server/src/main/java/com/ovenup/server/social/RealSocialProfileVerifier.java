package com.ovenup.server.social;

import java.util.Map;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import com.ovenup.server.common.ApiException;

/**
 * 실제 카카오/네이버 사용자 정보 API를 호출해 토큰을 검증한다.
 * app.social.mock=false 일 때만 활성화된다.
 * - 카카오: GET https://kapi.kakao.com/v2/user/me  (Authorization: Bearer {앱이 받은 토큰})
 * - 네이버: GET https://openapi.naver.com/v1/nid/me
 * 두 API 모두 사용자 액세스 토큰만 있으면 되고, 앱 등록은 "토큰 발급"(앱 쪽)에서 필요하다.
 */
@Component
@ConditionalOnProperty(name = "app.social.mock", havingValue = "false")
public class RealSocialProfileVerifier implements SocialProfileVerifier {

    private final RestClient restClient = RestClient.create();

    @Override
    public SocialProfile verify(String provider, String accessToken) {
        String p = provider == null ? "" : provider.toLowerCase();
        try {
            if ("kakao".equals(p)) {
                return kakao(accessToken);
            }
            if ("naver".equals(p)) {
                return naver(accessToken);
            }
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            throw ApiException.unauthorized("SOCIAL_VERIFY_FAILED", "소셜 인증에 실패했어요.");
        }
        throw ApiException.badRequest("UNSUPPORTED_PROVIDER", "지원하지 않는 소셜 로그인입니다.");
    }

    private SocialProfile kakao(String token) {
        Map<?, ?> body = restClient.get().uri("https://kapi.kakao.com/v2/user/me")
                .header("Authorization", "Bearer " + token).retrieve().body(Map.class);
        if (body == null || body.get("id") == null) {
            throw ApiException.unauthorized("SOCIAL_TOKEN_INVALID", "카카오 토큰이 유효하지 않아요.");
        }
        String id = String.valueOf(body.get("id"));
        String name = "카카오손님";
        String email = null;
        if (body.get("kakao_account") instanceof Map<?, ?> account) {
            if (account.get("email") != null) {
                email = account.get("email").toString();
            }
            if (account.get("profile") instanceof Map<?, ?> profile && profile.get("nickname") != null) {
                name = profile.get("nickname").toString();
            }
        }
        return new SocialProfile("KAKAO", id, name, email);
    }

    private SocialProfile naver(String token) {
        Map<?, ?> body = restClient.get().uri("https://openapi.naver.com/v1/nid/me")
                .header("Authorization", "Bearer " + token).retrieve().body(Map.class);
        if (body == null || !(body.get("response") instanceof Map<?, ?> resp) || resp.get("id") == null) {
            throw ApiException.unauthorized("SOCIAL_TOKEN_INVALID", "네이버 토큰이 유효하지 않아요.");
        }
        String id = String.valueOf(resp.get("id"));
        String name = resp.get("name") != null ? resp.get("name").toString()
                : (resp.get("nickname") != null ? resp.get("nickname").toString() : "네이버손님");
        String email = resp.get("email") != null ? resp.get("email").toString() : null;
        return new SocialProfile("NAVER", id, name, email);
    }
}
