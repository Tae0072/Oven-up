package com.ovenup.server.notification.dto;

import java.time.LocalDateTime;

/** 알림 응답 DTO (05_API §9). */
public final class NotificationDtos {

    private NotificationDtos() {
    }

    /** 알림 한 건 */
    public record NotificationView(long notificationId, String title, String body, String type,
                                   Long relatedOrderId, boolean read, LocalDateTime createdAt) {
    }

    /** 안 읽은 알림 개수 */
    public record UnreadCount(long unread) {
    }
}
