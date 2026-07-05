package com.ovenup.server.notification;

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
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private String userToken(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"12345678\",\"name\":\"손님\",\"phone\":\"010-0000-0000\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"12345678\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    private String adminToken() throws Exception {
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"admin@oven.com\",\"password\":\"admin1234\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    @Test
    void requiresLogin() throws Exception {
        mockMvc.perform(get("/api/notifications")).andExpect(status().isUnauthorized());
    }

    @Test
    void statusChangeCreatesNotificationForCustomer() throws Exception {
        String user = userToken("notif1@oven.com");
        // 주문 생성
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + user)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"menuId\":1,\"quantity\":2,\"optionIds\":[]}"));
        String created = mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + user)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"fulfillmentType\":\"TAKEOUT\"}"))
                .andReturn().getResponse().getContentAsString();
        Object orderId = JsonPath.read(created, "$.data.orderId");

        // 주문 직후엔 알림 없음
        mockMvc.perform(get("/api/notifications/unread-count").header("Authorization", "Bearer " + user))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unread").value(0));

        // 관리자가 상태 변경 → 손님 알림 생성
        String admin = adminToken();
        mockMvc.perform(patch("/api/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"준비완료\"}"))
                .andExpect(status().isOk());

        // 손님 알림 목록 확인
        String listRes = mockMvc.perform(get("/api/notifications").header("Authorization", "Bearer " + user))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].read").value(false))
                .andReturn().getResponse().getContentAsString();
        Object notifId = JsonPath.read(listRes, "$.data[0].notificationId");

        mockMvc.perform(get("/api/notifications/unread-count").header("Authorization", "Bearer " + user))
                .andExpect(jsonPath("$.data.unread").value(1));

        // 읽음 처리 → 안읽음 0
        mockMvc.perform(post("/api/notifications/" + notifId + "/read").header("Authorization", "Bearer " + user))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unread").value(0));
    }
}
