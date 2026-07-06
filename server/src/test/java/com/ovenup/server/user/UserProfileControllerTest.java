package com.ovenup.server.user;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.jayway.jsonpath.JsonPath;

@SpringBootTest
@AutoConfigureMockMvc
class UserProfileControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private String token(String email, String pw) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + pw
                        + "\",\"name\":\"홍길동\",\"phone\":\"010-1111-2222\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"" + pw + "\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    @Test
    void updateProfileChangesNameAndPhone() throws Exception {
        String t = token("prof1@oven.com", "12345678");
        mockMvc.perform(patch("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"김태오\",\"phone\":\"010-9999-8888\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("김태오"))
                .andExpect(jsonPath("$.data.phone").value("010-9999-8888"));

        mockMvc.perform(get("/api/users/me").header("Authorization", "Bearer " + t))
                .andExpect(jsonPath("$.data.name").value("김태오"));
    }

    @Test
    void updateProfileRejectsEmptyBody() throws Exception {
        String t = token("prof2@oven.com", "12345678");
        // 바꿀 내용이 하나도 없으면 거절 (name 빈값은 "이름은 그대로"라는 뜻으로 바뀜)
        mockMvc.perform(patch("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    void updateNicknameAndAddress() throws Exception {
        String t = token("prof3@oven.com", "12345678");
        // 소셜 온보딩과 같은 흐름: 닉네임 → 주소 순서로 각각 저장
        mockMvc.perform(patch("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nickname\":\"빵순이\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.nickname").value("빵순이"))
                .andExpect(jsonPath("$.data.name").value("빵순이"));
        mockMvc.perform(patch("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"address\":\"명지에코펠리스 101호\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.address").value("명지에코펠리스 101호"));
    }

    @Test
    void updateProfileRequiresLogin() throws Exception {
        mockMvc.perform(patch("/api/users/me").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"익명\",\"phone\":\"\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void changePasswordThenLoginWithNew() throws Exception {
        String t = token("pw1@oven.com", "12345678");
        mockMvc.perform(patch("/api/users/me/password").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"12345678\",\"newPassword\":\"87654321\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"pw1@oven.com\",\"password\":\"87654321\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists());
    }

    @Test
    void changePasswordRejectsWrongCurrent() throws Exception {
        String t = token("pw2@oven.com", "12345678");
        mockMvc.perform(patch("/api/users/me/password").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"wrongpass\",\"newPassword\":\"87654321\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("PASSWORD_MISMATCH"));
    }

    @Test
    void changePasswordRejectsShortNew() throws Exception {
        String t = token("pw3@oven.com", "12345678");
        mockMvc.perform(patch("/api/users/me/password").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"12345678\",\"newPassword\":\"123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    void notifyDefaultsOnAndCanToggleOff() throws Exception {
        String t = token("notify1@oven.com", "12345678");
        mockMvc.perform(get("/api/users/me").header("Authorization", "Bearer " + t))
                .andExpect(jsonPath("$.data.notifyEnabled").value(true));

        mockMvc.perform(patch("/api/users/me/notify").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.notifyEnabled").value(false));

        mockMvc.perform(get("/api/users/me").header("Authorization", "Bearer " + t))
                .andExpect(jsonPath("$.data.notifyEnabled").value(false));
    }

    @Test
    void deleteAccountWrongPasswordRejected() throws Exception {
        String t = token("del1@oven.com", "12345678");
        mockMvc.perform(delete("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"currentPassword\":\"wrongpass\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("PASSWORD_MISMATCH"));
    }

    @Test
    void deleteAccountThenLoginFails() throws Exception {
        String t = token("del2@oven.com", "12345678");
        mockMvc.perform(delete("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"currentPassword\":\"12345678\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"del2@oven.com\",\"password\":\"12345678\"}"))
                .andExpect(status().isUnauthorized());
    }
}
