package com.ovenup.server.order;

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

/**
 * 건물 전용 위치 검증 (위치 필수 모드 = 운영 기본값).
 * - 좌표 없이 주문 → LOCATION_REQUIRED
 * - 건물 밖 좌표로 주문 → LOCATION_NOT_ALLOWED
 * - 건물 좌표로 주문 → 성공
 */
@SpringBootTest(properties = "app.building.require-location=true")
@AutoConfigureMockMvc
class BuildingLocationOrderTest {

    /** 건물 중심 좌표 (BuildingPolicy 기본값과 동일) */
    private static final String IN_BUILDING = "\"lat\":35.0928292,\"lng\":128.9088756";
    /** 건물에서 수 km 떨어진 좌표 (부산역 인근) */
    private static final String FAR_AWAY = "\"lat\":35.1151,\"lng\":129.0403";

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

    private void addToCart(String token, long menuId, int quantity) throws Exception {
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"menuId\":" + menuId + ",\"quantity\":" + quantity + ",\"optionIds\":[]}"));
    }

    @Test
    void orderWithoutLocationIsRejected() throws Exception {
        String t = token("loc1@oven.com");
        addToCart(t, 1, 1);
        mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"TAKEOUT\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("LOCATION_REQUIRED"));
    }

    @Test
    void orderFromOutsideBuildingIsRejected() throws Exception {
        String t = token("loc2@oven.com");
        addToCart(t, 1, 1);
        mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"TAKEOUT\"," + FAR_AWAY + "}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("LOCATION_NOT_ALLOWED"));
    }

    @Test
    void orderInsideBuildingSucceeds() throws Exception {
        String t = token("loc3@oven.com");
        addToCart(t, 1, 1);
        mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"TAKEOUT\"," + IN_BUILDING + "}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.orderNo").exists());
    }
}
