package com.ovenup.server.order;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.notification.NotificationService;

/**
 * 예약 주문 리마인드 (03_기능 §9 확장).
 * 1분마다 "예약 시각이 30분 안으로 다가온" 주문을 찾아 손님에게 알림을 보낸다.
 * reminderSent 플래그로 중복 발송을 막는다.
 */
@Component
public class ReservationReminderScheduler {

    /** 리마인드를 보낼 예약 임박 기준(분) */
    private static final int REMIND_BEFORE_MINUTES = 30;

    /** 리마인드 대상 상태 (결제 전/취소 주문은 제외) */
    private static final Set<String> ACTIVE_STATUSES = Set.of("결제완료", "준비중", "준비완료");

    private final OrderRepository orderRepository;
    private final NotificationService notificationService;

    public ReservationReminderScheduler(OrderRepository orderRepository,
                                        NotificationService notificationService) {
        this.orderRepository = orderRepository;
        this.notificationService = notificationService;
    }

    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void remindUpcomingReservations() {
        LocalDateTime now = LocalDateTime.now();
        List<OrderEntity> due = orderRepository
                .findByScheduledAtBetweenAndReminderSentFalse(now, now.plusMinutes(REMIND_BEFORE_MINUTES));
        for (OrderEntity order : due) {
            if (!ACTIVE_STATUSES.contains(order.getStatus())) {
                continue;
            }
            String when = String.format("%02d:%02d", order.getScheduledAt().getHour(),
                    order.getScheduledAt().getMinute());
            notificationService.notifyUser(order.getUserId(), "예약 주문 " + order.getOrderNo(),
                    when + " 예약 시간이 30분 안으로 다가왔어요.", "ORDER_REMINDER", order.getId());
            order.markReminderSent();
            orderRepository.save(order);
        }
    }
}
