package com.ovenup.server.notification;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.notification.dto.NotificationDtos.NotificationView;
import com.ovenup.server.user.UserRepository;

/**
 * 알림 처리 (05_API §9). 인앱 알림을 저장/조회하고, 만들 때 PushSender로 OS 푸시도 함께 보낸다.
 */
@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final PushSender pushSender;
    private final UserRepository userRepository;
    private final DeviceTokenRepository deviceTokenRepository;

    public NotificationService(NotificationRepository notificationRepository, PushSender pushSender,
                               UserRepository userRepository, DeviceTokenRepository deviceTokenRepository) {
        this.notificationRepository = notificationRepository;
        this.pushSender = pushSender;
        this.userRepository = userRepository;
        this.deviceTokenRepository = deviceTokenRepository;
    }

    /**
     * 기기 토큰 등록 (가이드 §3-1). 같은 토큰이 이미 있으면 주인만 갱신한다
     * (한 기기에서 다른 계정으로 다시 로그인한 경우).
     */
    @Transactional
    public void registerDeviceToken(Long userId, String token) {
        if (token == null || token.isBlank()) {
            throw ApiException.badRequest("INVALID_INPUT", "기기 토큰이 없습니다.");
        }
        deviceTokenRepository.findByToken(token).ifPresentOrElse(existing -> {
            if (!existing.getUserId().equals(userId)) {
                existing.reassignTo(userId);
                deviceTokenRepository.save(existing);
            }
        }, () -> deviceTokenRepository.save(new DeviceTokenEntity(userId, token)));
    }

    /**
     * 알림 생성 + OS 푸시 발송(mock/real). 다른 도메인(주문 등)에서 이벤트 발생 시 호출.
     * 손님이 알림을 꺼두었으면 저장/발송하지 않는다.
     */
    @Transactional
    public void notifyUser(Long userId, String title, String body, String type, Long relatedOrderId) {
        boolean enabled = userRepository.findById(userId).map(u -> u.isNotifyEnabled()).orElse(true);
        if (!enabled) {
            return;
        }
        notificationRepository.save(new NotificationEntity(userId, title, body, type, relatedOrderId));
        pushSender.send(userId, title, body);
    }

    /** 관리자(사장님) 전원에게 알림 — 새 주문 접수 등 가게 운영 이벤트용. */
    @Transactional
    public void notifyAdmins(String title, String body, String type, Long relatedOrderId) {
        userRepository.findByRole("ADMIN")
                .forEach(admin -> notifyUser(admin.getId(), title, body, type, relatedOrderId));
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
