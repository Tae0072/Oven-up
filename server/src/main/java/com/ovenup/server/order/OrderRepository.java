package com.ovenup.server.order;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<OrderEntity, Long> {

    List<OrderEntity> findByUserIdOrderByIdDesc(Long userId);

    // 관리자용: 전체/상태별 주문 목록 (최신순)
    List<OrderEntity> findAllByOrderByIdDesc();

    List<OrderEntity> findByStatusOrderByIdDesc(String status);
}
