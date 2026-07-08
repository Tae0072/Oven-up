package com.ovenup.server.inquiry;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 고객의 소리 답변 (inquiry_reply). 문의 1건당 사장님 답변 1건.
 * 답변 등록은 향후 관리자 화면 작업에서 담당(현재는 데모 시더로 채움).
 */
@Entity
@Table(name = "inquiry_reply")
public class InquiryReplyEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long inquiryId;

    @Column(length = 2000)
    private String content;

    private LocalDateTime createdAt;

    protected InquiryReplyEntity() {
    }

    public InquiryReplyEntity(Long inquiryId, String content) {
        this.inquiryId = inquiryId;
        this.content = content;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getInquiryId() {
        return inquiryId;
    }

    public String getContent() {
        return content;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
