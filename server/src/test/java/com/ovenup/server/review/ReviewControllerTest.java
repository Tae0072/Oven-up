package com.ovenup.server.review;

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
class ReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private String token(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"12345678\",\"name\":\"리뷰어\",\"phone\":\"010-0000-0000\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"12345678\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    /** 메뉴 1을 주문하고 결제까지 완료 → 구매 이력 생성 */
    private void buyMenu1(String token) throws Exception {
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"menuId\":1,\"quantity\":1,\"optionIds\":[]}"));
        String created = mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"fulfillmentType\":\"TAKEOUT\"}"))
                .andReturn().getResponse().getContentAsString();
        long orderId = ((Number) JsonPath.read(created, "$.data.orderId")).longValue();
        mockMvc.perform(post("/api/orders/" + orderId + "/pay").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"method\":\"CARD\",\"paymentRef\":\"\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void purchaserCanReviewAndListShowsAverage() throws Exception {
        String t = token("rev1@oven.com");
        buyMenu1(t);
        mockMvc.perform(post("/api/menus/1/reviews").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":5,\"content\":\"정말 맛있어요\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.rating").value(5));

        mockMvc.perform(get("/api/menus/1/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reviewCount").isNumber())
                .andExpect(jsonPath("$.data.items").isArray());
    }

    @Test
    void nonPurchaserRejected() throws Exception {
        String t = token("rev2@oven.com");
        mockMvc.perform(post("/api/menus/1/reviews").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":4,\"content\":\"안 사먹었지만\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("NOT_PURCHASED"));
    }

    @Test
    void reviewRequiresLogin() throws Exception {
        mockMvc.perform(post("/api/menus/1/reviews").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":4,\"content\":\"익명\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void duplicateReviewRejected() throws Exception {
        String t = token("rev3@oven.com");
        buyMenu1(t);
        mockMvc.perform(post("/api/menus/1/reviews").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":5,\"content\":\"첫 리뷰\"}"))
                .andExpect(status().isCreated());
        mockMvc.perform(post("/api/menus/1/reviews").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":3,\"content\":\"두 번째\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error.code").value("REVIEW_DUPLICATED"));
    }

    @Test
    void invalidRatingRejected() throws Exception {
        String t = token("rev4@oven.com");
        buyMenu1(t);
        mockMvc.perform(post("/api/menus/1/reviews").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":9,\"content\":\"별 9개\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    void menuListIncludesRatingFields() throws Exception {
        mockMvc.perform(get("/api/menus"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].ratingAvg").exists())
                .andExpect(jsonPath("$.data[0].reviewCount").exists());
    }
}
