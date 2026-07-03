package com.ovenup.server.order;

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
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    /** 회원가입+로그인 후 토큰 반환 */
    private String token(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"12345678\",\"name\":\"손님\",\"phone\":\"010-0000-0000\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"12345678\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    @Test
    void createOrderRequiresLogin() throws Exception {
        mockMvc.perform(post("/api/orders").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"DINE_IN\",\"items\":[{\"menuId\":1,\"quantity\":1}]}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createOrderSucceeds() throws Exception {
        String t = token("order1@oven.com");
        mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"DINE_IN\",\"items\":[{\"menuId\":1,\"quantity\":2}]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.totalPrice").value(25800))
                .andExpect(jsonPath("$.data.orderNo").exists())
                .andExpect(jsonPath("$.data.status").exists());
    }

    @Test
    void deliveryBlockedWhenLessThanTwoSandwiches() throws Exception {
        String t = token("order2@oven.com");
        mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"DELIVERY\",\"deliveryAddress\":\"명지에코펠리스 305호\",\"items\":[{\"menuId\":1,\"quantity\":1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("DELIVERY_NOT_ALLOWED"));
    }

    @Test
    void listAndDetailReturnMyOrder() throws Exception {
        String t = token("order3@oven.com");
        String created = mockMvc.perform(post("/api/orders").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fulfillmentType\":\"TAKEOUT\",\"items\":[{\"menuId\":1,\"quantity\":2}]}"))
                .andReturn().getResponse().getContentAsString();
        Object orderId = JsonPath.read(created, "$.data.orderId");

        mockMvc.perform(get("/api/orders").header("Authorization", "Bearer " + t))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));

        mockMvc.perform(get("/api/orders/" + orderId).header("Authorization", "Bearer " + t))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.items[0].unitPrice").value(12900))
                .andExpect(jsonPath("$.data.items[0].quantity").value(2));
    }
}
