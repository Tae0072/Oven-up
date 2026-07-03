package com.ovenup.server.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

/**
 * 소셜 로그인 테스트 — mock 모드(app.social.mock 미설정 → 기본 mock).
 * mock 토큰 형식: "providerUserId:이름".
 */
@SpringBootTest
@AutoConfigureMockMvc
class AuthSocialControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void firstSocialLoginCreatesUser() throws Exception {
        mockMvc.perform(post("/api/auth/social/kakao").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accessToken\":\"1001:카카오손님\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.isNew").value(true))
                .andExpect(jsonPath("$.data.user.role").value("USER"));
    }

    @Test
    void secondSocialLoginIsNotNew() throws Exception {
        mockMvc.perform(post("/api/auth/social/naver").contentType(MediaType.APPLICATION_JSON)
                .content("{\"accessToken\":\"2002:네이버손님\"}"));
        mockMvc.perform(post("/api/auth/social/naver").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accessToken\":\"2002:네이버손님\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isNew").value(false));
    }

    @Test
    void unsupportedProviderReturns400() throws Exception {
        mockMvc.perform(post("/api/auth/social/google").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accessToken\":\"x\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("UNSUPPORTED_PROVIDER"));
    }

    @Test
    void emptyTokenReturns401() throws Exception {
        mockMvc.perform(post("/api/auth/social/kakao").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accessToken\":\"\"}"))
                .andExpect(status().isUnauthorized());
    }
}
