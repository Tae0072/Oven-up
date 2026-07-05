package com.ovenup.server.notification;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 손님 알림 (notification). 03_기능 §9.
 * 주문 상태 변경·결제 완료 등 이벤트가 생기면 해당 손님에게 알림을 만든다.
 * (실제 OS 푸시(FCM)는 이 알림을 만들 때 PushSender로 함께 보낸다 — 가이드 참고)
 */
@Entity
@Table(name = "notification")
public class NotificationEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private String title;

    @Column(length = 500)
    private String body;

    private String type; // ORDER_STATUS / ORDER_PAID 등

    private Long relatedOrderId; // 관련 주문(있으면)

    private boolean readFlag; // 읽음 여부

    private LocalDateTime createdAt;

    protected NotificationEntity() {
    }

    public NotificationEntity(Long userId, String title, String body, String type, Long relatedOrderId) {
        this.userId = userId;
        this.title = title;
        this.body = body;
        this.type = type;
        this.relatedOrderId = relatedOrderId;
        this.readFlag = false;
        this.createdAt = LocalDateTime.now();
    }

    public void markRead() {
        this.readFlag = true;
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

    public String getBody() {
        return body;
    }

    public String getType() {
        return type;
    }

    public Long getRelatedOrderId() {
        return relatedOrderId;
    }

    public boolean isReadFlag() {
        return readFlag;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
