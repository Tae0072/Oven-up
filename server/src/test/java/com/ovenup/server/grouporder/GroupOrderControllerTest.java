package com.ovenup.server.grouporder;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
class GroupOrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private String token(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"12345678\",\"name\":\"손님\",\"phone\":\"010-0000-0000\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"12345678\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    @Test
    void requiresLogin() throws Exception {
        mockMvc.perform(get("/api/group-orders")).andExpect(status().isUnauthorized());
    }

    @Test
    void createAndList() throws Exception {
        String t = token("group1@oven.com");
        mockMvc.perform(post("/api/group-orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"desiredAt\":\"2026-08-01T12:00:00\",\"headcount\":30,"
                                + "\"detail\":\"행사용 30개\",\"contact\":\"010-1234-5678\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("접수"))
                .andExpect(jsonPath("$.data.groupOrderId").isNumber());

        mockMvc.perform(get("/api/group-orders").header("Authorization", "Bearer " + t))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].headcount").value(30))
                .andExpect(jsonPath("$.data[0].status").value("접수"));
    }

    @Test
    void rejectsInvalidHeadcount() throws Exception {
        String t = token("group2@oven.com");
        mockMvc.perform(post("/api/group-orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"desiredAt\":\"2026-08-01T12:00:00\",\"headcount\":0,"
                                + "\"detail\":\"\",\"contact\":\"010-1234-5678\"}"))
                .andExpect(status().isBadRequest());
    }
}
