package com.ovenup.server.inquiry;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 고객의 소리 문의 (inquiry). 05_API §7 / 03_기능 §8.
 * 본인 글만 조회. 사장님 답변은 InquiryReplyEntity로 별도 저장.
 * status: 접수/답변완료.
 */
@Entity
@Table(name = "inquiry")
public class InquiryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private String title;

    @Column(length = 2000)
    private String content;

    private String imageUrl;

    private String status;

    private LocalDateTime createdAt;

    protected InquiryEntity() {
    }

    public InquiryEntity(Long userId, String title, String content, String imageUrl) {
        this.userId = userId;
        this.title = title;
        this.content = content;
        this.imageUrl = imageUrl;
        this.status = "접수";
        this.createdAt = LocalDateTime.now();
    }

    public void markAnswered() {
        this.status = "답변완료";
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getTitle() {
        return title;
    }

    public String getContent() {
        return content;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getStatus() {
        return status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
