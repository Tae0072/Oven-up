package com.ovenup.server.inquiry;

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
class AdminSupportControllerTest {

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

    private long createInquiry(String token) throws Exception {
        String res = mockMvc.perform(post("/api/inquiries").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"문의합니다\",\"content\":\"영업시간 알려주세요\",\"imageUrl\":\"\"}"))
                .andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(res, "$.data.inquiryId")).longValue();
    }

    private long createGroupOrder(String token) throws Exception {
        String res = mockMvc.perform(post("/api/group-orders").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"desiredAt\":\"\",\"headcount\":20,\"detail\":\"회사 워크숍\",\"contact\":\"010-1234-5678\"}"))
                .andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(res, "$.data.groupOrderId")).longValue();
    }

    @Test
    void adminCanReplyInquiryAndCustomerSeesIt() throws Exception {
        String u = userToken("sup_user1@oven.com");
        long inquiryId = createInquiry(u);
        String admin = adminToken();

        mockMvc.perform(post("/api/admin/inquiries/" + inquiryId + "/reply")
                        .header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"평일 10시~20시 운영해요\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("평일 10시~20시 운영해요"));

        // 손님 상세에 답변 + 상태 답변완료
        mockMvc.perform(get("/api/inquiries/" + inquiryId).header("Authorization", "Bearer " + u))
                .andExpect(jsonPath("$.data.status").value("답변완료"))
                .andExpect(jsonPath("$.data.reply.content").value("평일 10시~20시 운영해요"));
    }

    @Test
    void adminInquiryListArray() throws Exception {
        createInquiry(userToken("sup_user2@oven.com"));
        mockMvc.perform(get("/api/admin/inquiries").header("Authorization", "Bearer " + adminToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void inquiryReplyForbiddenForNonAdmin() throws Exception {
        String u = userToken("sup_user3@oven.com");
        long inquiryId = createInquiry(u);
        mockMvc.perform(post("/api/admin/inquiries/" + inquiryId + "/reply")
                        .header("Authorization", "Bearer " + u)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"내가 답변\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanUpdateGroupOrder() throws Exception {
        String u = userToken("sup_user4@oven.com");
        long groupId = createGroupOrder(u);
        String admin = adminToken();

        mockMvc.perform(patch("/api/admin/group-orders/" + groupId)
                        .header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"협의중\",\"adminMemo\":\"연락드릴게요\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("협의중"))
                .andExpect(jsonPath("$.data.adminMemo").value("연락드릴게요"));
    }

    @Test
    void groupOrderInvalidStatusRejected() throws Exception {
        String u = userToken("sup_user5@oven.com");
        long groupId = createGroupOrder(u);
        mockMvc.perform(patch("/api/admin/group-orders/" + groupId)
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"우주정복\",\"adminMemo\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    void groupOrderListForbiddenForNonAdmin() throws Exception {
        String u = userToken("sup_user6@oven.com");
        mockMvc.perform(get("/api/admin/group-orders").header("Authorization", "Bearer " + u))
                .andExpect(status().isForbidden());
    }
}
