package com.ovenup.server.notification;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.notification.dto.NotificationDtos.NotificationView;

/**
 * 알림 처리 (05_API §9). 인앱 알림을 저장/조회하고, 만들 때 PushSender로 OS 푸시도 함께 보낸다.
 */
@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final PushSender pushSender;

    public NotificationService(NotificationRepository notificationRepository, PushSender pushSender) {
        this.notificationRepository = notificationRepository;
        this.pushSender = pushSender;
    }

    /** 알림 생성 + OS 푸시 발송(mock/real). 다른 도메인(주문 등)에서 이벤트 발생 시 호출. */
    @Transactional
    public void notifyUser(Long userId, String title, String body, String type, Long relatedOrderId) {
        notificationRepository.save(new NotificationEntity(userId, title, body, type, relatedOrderId));
        pushSender.send(userId, title, body);
    }

    @Transactional(readOnly = true)
    public List<NotificationView> myList(Long userId) {
        return notificationRepository.findByUserIdOrderByIdDesc(userId).stream()
                .map(n -> new NotificationView(n.getId(), n.getTitle(), n.getBody(), n.getType(),
                        n.getRelatedOrderId(), n.isReadFlag(), n.getCreatedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public long unreadCount(Long userId) {
        return notificationRepository.countByUserIdAndReadFlagFalse(userId);
    }

    @Transactional
    public void markRead(Long userId, long notificationId) {
        NotificationEntity n = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> ApiException.notFound("NOT_FOUND", "알림을 찾을 수 없습니다."));
        n.markRead();
        notificationRepository.save(n);
    }

    @Transactional
    public void markAllRead(Long userId) {
        List<NotificationEntity> unread = notificationRepository.findByUserIdAndReadFlagFalse(userId);
        for (NotificationEntity n : unread) {
            n.markRead();
        }
        notificationRepository.saveAll(unread);
    }
}
