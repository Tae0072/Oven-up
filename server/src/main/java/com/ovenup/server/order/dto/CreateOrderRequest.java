package com.ovenup.server.order.dto;

import java.util.List;

/**
 * 주문 생성 요청 (05_API §4.2).
 * - fulfillmentType: DINE_IN | TAKEOUT | DELIVERY
 * - scheduledAt: 예약주문이면 ISO 시각 문자열(예: 2026-07-05T14:30:00), 지금 주문이면 null
 * - deliveryAddress: 배달일 때만 (명지에코펠리스 건물 내)
 * - items: 주문 항목 (couponId/usePoint는 쿠폰·적립 도입 후 추가)
 */
public record CreateOrderRequest(
        String fulfillmentType,
        String scheduledAt,
        String deliveryAddress,
        String requestMsg,
        List<OrderItemRequest> items) {
}
