package com.ovenup.server.user;

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
    void updateProfileRejectsEmptyName() throws Exception {
        String t = token("prof2@oven.com", "12345678");
        mockMvc.perform(patch("/api/users/me").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"phone\":\"010-0000-0000\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
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
}
