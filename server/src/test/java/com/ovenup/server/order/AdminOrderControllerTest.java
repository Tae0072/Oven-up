package com.ovenup.server.order;

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
class AdminOrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    /** 시더가 만든 관리자 계정(admin@oven.com/admin1234)으로 로그인 */
    private String adminToken() throws Exception {
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"admin@oven.com\",\"password\":\"admin1234\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    /** 일반 손님 회원가입+로그인 */
    private String userToken(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"12345678\",\"name\":\"손님\",\"phone\":\"010-0000-0000\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"12345678\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    private long createOrder(String userToken) throws Exception {
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"menuId\":1,\"quantity\":2,\"optionIds\":[]}"));
        String created = mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"fulfillmentType\":\"TAKEOUT\"}"))
                .andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(created, "$.data.orderId")).longValue();
    }

    @Test
    void nonAdminForbidden() throws Exception {
        String u = userToken("adm_user1@oven.com");
        mockMvc.perform(get("/api/admin/orders").header("Authorization", "Bearer " + u))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
    }

    @Test
    void requiresLogin() throws Exception {
        mockMvc.perform(get("/api/admin/orders")).andExpect(status().isUnauthorized());
    }

    @Test
    void adminCanListAndChangeStatus() throws Exception {
        long orderId = createOrder(userToken("adm_user2@oven.com"));
        String admin = adminToken();

        mockMvc.perform(get("/api/admin/orders").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());

        mockMvc.perform(patch("/api/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"준비중\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("준비중"));
    }

    /** 주문을 만들고 결제까지 완료 → 매출 집계 대상이 된다. */
    private void createAndPay(String userToken) throws Exception {
        long orderId = createOrder(userToken);
        mockMvc.perform(post("/api/orders/" + orderId + "/pay").header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"method\":\"CARD\",\"paymentRef\":\"\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void adminStatsReflectsPaidOrders() throws Exception {
        createAndPay(userToken("stat_user1@oven.com"));
        String admin = adminToken();

        mockMvc.perform(get("/api/admin/stats").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalOrders").isNumber())
                .andExpect(jsonPath("$.data.todaySales").isNumber())
                .andExpect(jsonPath("$.data.daily").isArray())
                .andExpect(jsonPath("$.data.daily.length()").value(7))
                .andExpect(jsonPath("$.data.topMenus").isArray())
                .andExpect(jsonPath("$.data.statusCounts").isArray());
    }

    @Test
    void statsForbiddenForNonAdmin() throws Exception {
        String u = userToken("stat_user2@oven.com");
        mockMvc.perform(get("/api/admin/stats").header("Authorization", "Bearer " + u))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminRejectsInvalidStatus() throws Exception {
        long orderId = createOrder(userToken("adm_user3@oven.com"));
        String admin = adminToken();
        mockMvc.perform(patch("/api/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"우주정복\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }
}
