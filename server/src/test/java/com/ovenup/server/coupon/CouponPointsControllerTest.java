package com.ovenup.server.coupon;

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
class CouponPointsControllerTest {

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

    private void addCart(String token) throws Exception {
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"menuId\":1,\"quantity\":2,\"optionIds\":[]}"));
    }

    @Test
    void nonAdminCannotCreateCoupon() throws Exception {
        String u = userToken("cp_user0@oven.com");
        mockMvc.perform(post("/api/admin/coupons").header("Authorization", "Bearer " + u)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"X\",\"name\":\"n\",\"type\":\"AMOUNT\",\"value\":1000,\"minOrderAmount\":0}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void couponDiscountAndPointsEarnThenUse() throws Exception {
        // 관리자: 쿠폰 발급 (3,000원 할인, 1만원 이상)
        String admin = adminToken();
        mockMvc.perform(post("/api/admin/coupons").header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"SAVE3000\",\"name\":\"3천원 할인\",\"type\":\"AMOUNT\",\"value\":3000,\"minOrderAmount\":10000}"))
                .andExpect(status().isCreated());

        String user = userToken("cp_user1@oven.com");
        addCart(user); // LA갈비 x2 = 25,800

        // 쿠폰 확인 → 할인 3,000
        mockMvc.perform(get("/api/coupons/check").param("code", "SAVE3000")
                        .header("Authorization", "Bearer " + user))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.valid").value(true))
                .andExpect(jsonPath("$.data.discount").value(3000));

        // 쿠폰 적용 주문 → 총액 22,800
        String created = mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + user)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"TAKEOUT\",\"couponCode\":\"SAVE3000\",\"usePoints\":0}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.totalPrice").value(22800))
                .andReturn().getResponse().getContentAsString();
        Object orderId = JsonPath.read(created, "$.data.orderId");

        // 결제 → 적립 1% = 228
        mockMvc.perform(post("/api/orders/" + orderId + "/pay").header("Authorization", "Bearer " + user)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"method\":\"CARD\",\"paymentRef\":\"\"}"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/points").header("Authorization", "Bearer " + user))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.balance").value(228));

        // 같은 쿠폰 재사용 불가
        addCart(user);
        mockMvc.perform(get("/api/coupons/check").param("code", "SAVE3000")
                        .header("Authorization", "Bearer " + user))
                .andExpect(jsonPath("$.data.valid").value(false));

        // 적립금 200 사용 주문 → 총액 25,600, 잔액 28
        String created2 = mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + user)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"TAKEOUT\",\"usePoints\":200}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.totalPrice").value(25600))
                .andReturn().getResponse().getContentAsString();
        assert created2 != null;
        mockMvc.perform(get("/api/points").header("Authorization", "Bearer " + user))
                .andExpect(jsonPath("$.data.balance").value(28));
    }
}
