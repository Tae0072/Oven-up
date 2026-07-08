package com.ovenup.server.order;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<OrderEntity, Long> {

    List<OrderEntity> findByUserIdOrderByIdDesc(Long userId);

    // 관리자용: 전체/상태별 주문 목록 (최신순)
    List<OrderEntity> findAllByOrderByIdDesc();

    List<OrderEntity> findByStatusOrderByIdDesc(String status);

    /** 예약 리마인드 대상: 예약 시각이 [from, to] 사이이고 아직 리마인드 안 보낸 주문 */
    List<OrderEntity> findByScheduledAtBetweenAndReminderSentFalse(LocalDateTime from, LocalDateTime to);
}
