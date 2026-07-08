package com.ovenup.server.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import com.ovenup.server.common.ApiException;

/**
 * 개발/테스트용 소셜 검증기 (기본). 실제 카카오/네이버를 호출하지 않고,
 * 토큰 문자열을 그대로 사용자 정보로 해석한다. → 앱 등록/키 없이도 흐름을 확인 가능.
 *
 * 토큰 형식: "providerUserId:이름:이메일" (뒤 두 개는 선택). 예) "1001:카카오손님"
 * ⚠️ 실제 배포에서는 app.social.mock=false 로 두어 RealSocialProfileVerifier 를 쓴다.
 */
@Component
@ConditionalOnProperty(name = "app.social.mock", havingValue = "true", matchIfMissing = true)
public class MockSocialProfileVerifier implements SocialProfileVerifier {

    @Override
    public SocialProfile verify(String provider, String accessToken) {
        if (accessToken == null || accessToken.isBlank()) {
            throw ApiException.unauthorized("SOCIAL_TOKEN_INVALID", "소셜 토큰이 없습니다.");
        }
        String[] parts = accessToken.split(":");
        String providerUserId = parts[0].trim();
        if (providerUserId.isEmpty()) {
            throw ApiException.unauthorized("SOCIAL_TOKEN_INVALID", "소셜 토큰이 올바르지 않습니다.");
        }
        String name = (parts.length > 1 && !parts[1].isBlank()) ? parts[1].trim() : (label(provider) + "손님");
        String email = (parts.length > 2 && !parts[2].isBlank()) ? parts[2].trim() : null;
        return new SocialProfile(provider.toUpperCase(), providerUserId, name, email);
    }

    private String label(String provider) {
        return "naver".equalsIgnoreCase(provider) ? "네이버" : "카카오";
    }
}
