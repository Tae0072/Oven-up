package com.ovenup.server.menu;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class AdminMenuControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private String adminToken() throws Exception {
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"admin@oven.com\",\"password\":\"admin1234\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    private String userToken(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"12345678\",\"name\":\"손님\",\"phone\":\"010-0000-0000\"}"));
        String res = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"12345678\"}"))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.data.accessToken");
    }

    @Test
    void nonAdminForbidden() throws Exception {
        String u = userToken("menu_user0@oven.com");
        mockMvc.perform(get("/api/admin/menus").header("Authorization", "Bearer " + u))
                .andExpect(status().isForbidden());
    }

    @Test
    void createToggleSoldOutAndDelete() throws Exception {
        String admin = adminToken();
        // 등록
        String created = mockMvc.perform(post("/api/admin/menus").header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"테스트 샌드위치\",\"description\":\"임시\",\"price\":5000,"
                                + "\"category\":\"샌드위치\",\"bread\":\"바게트\",\"emoji\":\"🥪\",\"best\":false}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("판매중"))
                .andReturn().getResponse().getContentAsString();
        Object menuId = JsonPath.read(created, "$.data.id");

        // 품절 처리
        mockMvc.perform(patch("/api/admin/menus/" + menuId + "/soldout").header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"soldOut\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("품절"));

        // 품절 메뉴는 장바구니 담기 거부
        String u = userToken("menu_user1@oven.com");
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + u)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"menuId\":" + menuId + ",\"quantity\":1,\"optionIds\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("MENU_SOLD_OUT"));

        // 판매중으로 복구 → 담기 가능
        mockMvc.perform(patch("/api/admin/menus/" + menuId + "/soldout").header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"soldOut\":false}"))
                .andExpect(jsonPath("$.data.status").value("판매중"));
        mockMvc.perform(post("/api/cart/items").header("Authorization", "Bearer " + u)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"menuId\":" + menuId + ",\"quantity\":1,\"optionIds\":[]}"))
                .andExpect(status().isCreated());

        // 수정
        mockMvc.perform(put("/api/admin/menus/" + menuId).header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"테스트 샌드위치2\",\"price\":6000,\"category\":\"샌드위치\","
                                + "\"bread\":\"치아바타\",\"emoji\":\"🥪\",\"best\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.price").value(6000))
                .andExpect(jsonPath("$.data.isBest").value(true));

        // 삭제
        mockMvc.perform(delete("/api/admin/menus/" + menuId).header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk());
    }
}
