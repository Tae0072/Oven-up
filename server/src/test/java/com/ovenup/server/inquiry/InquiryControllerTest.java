package com.ovenup.server.inquiry;

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
class InquiryControllerTest {

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
        mockMvc.perform(get("/api/inquiries")).andExpect(status().isUnauthorized());
    }

    @Test
    void createListAndDetail() throws Exception {
        String t = token("inq1@oven.com");
        String created = mockMvc.perform(post("/api/inquiries").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"문의 제목\",\"content\":\"문의 내용입니다\",\"imageUrl\":null}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("접수"))
                .andReturn().getResponse().getContentAsString();
        Object inquiryId = JsonPath.read(created, "$.data.inquiryId");

        mockMvc.perform(get("/api/inquiries").header("Authorization", "Bearer " + t))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("문의 제목"));

        mockMvc.perform(get("/api/inquiries/" + inquiryId).header("Authorization", "Bearer " + t))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("문의 내용입니다"))
                .andExpect(jsonPath("$.data.reply").doesNotExist());
    }

    @Test
    void rejectsEmptyTitle() throws Exception {
        String t = token("inq2@oven.com");
        mockMvc.perform(post("/api/inquiries").header("Authorization", "Bearer " + t)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"\",\"content\":\"내용\",\"imageUrl\":null}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void cannotSeeOthersInquiry() throws Exception {
        String owner = token("inq3@oven.com");
        String created = mockMvc.perform(post("/api/inquiries").header("Authorization", "Bearer " + owner)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"비밀 문의\",\"content\":\"내용\",\"imageUrl\":null}"))
                .andReturn().getResponse().getContentAsString();
        Object inquiryId = JsonPath.read(created, "$.data.inquiryId");

        String other = token("inq4@oven.com");
        mockMvc.perform(get("/api/inquiries/" + inquiryId).header("Authorization", "Bearer " + other))
                .andExpect(status().isNotFound());
    }
}
