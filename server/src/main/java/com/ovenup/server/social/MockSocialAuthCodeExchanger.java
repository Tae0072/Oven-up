package com.ovenup.server.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 개발/테스트용(mock) 코드 교환기. 실제 카카오/네이버를 호출하지 않고
 * 인가 코드를 그대로 "토큰"으로 돌려준다 → MockSocialProfileVerifier 가
 * "providerUserId:이름" 형식으로 해석하는 기존 mock 흐름이 유지된다.
 */
@Component
@ConditionalOnProperty(name = "app.social.mock", havingValue = "true", matchIfMissing = true)
public class MockSocialAuthCodeExchanger implements SocialAuthCodeExchanger {

    @Override
    public String exchange(String provider, String code, String redirectUri, String state) {
        return code;
    }
}
