package com.ovenup.server.inquiry.dto;

import java.time.LocalDateTime;

/** 고객의 소리 요청/응답 DTO (05_API §7). */
public final class InquiryDtos {

    private InquiryDtos() {
    }

    /** 문의 작성 요청 (§7.1) */
    public record CreateInquiryRequest(String title, String content, String imageUrl) {
    }

    /** 작성 응답 (§7.1) */
    public record InquiryCreated(long inquiryId, String status) {
    }

    /** 내 문의 목록 항목 (§7.2) */
    public record InquirySummary(long inquiryId, String title, String status, LocalDateTime createdAt) {
    }

    /** 사장님 답변 (§7.3) */
    public record ReplyView(String content, LocalDateTime createdAt) {
    }

    /** 문의 상세 (§7.3). reply는 없으면 null. */
    public record InquiryDetail(long inquiryId, String title, String content, String imageUrl,
                                String status, LocalDateTime createdAt, ReplyView reply) {
    }

    /** 관리자용 문의 항목 (내용·답변 포함) */
    public record AdminInquiryItem(long inquiryId, long userId, String title, String content,
                                   String imageUrl, String status, LocalDateTime createdAt, ReplyView reply) {
    }

    /** 관리자 답변 요청 */
    public record ReplyRequest(String content) {
    }
}
