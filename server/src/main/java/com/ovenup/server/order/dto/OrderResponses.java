package com.ovenup.server.order.dto;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 주문 관련 응답 DTO 모음 (05_API §4).
 */
public final class OrderResponses {

    private OrderResponses() {
    }

    /** 주문 생성 응답 (§4.2) */
    public record OrderCreated(long orderId, String orderNo, int totalPrice, String status) {
    }

    /** 내 주문 목록 항목 (§4.3) */
    public record OrderSummary(long orderId, String orderNo, int totalPrice, String fulfillmentType,
                               LocalDateTime scheduledAt, String status, LocalDateTime createdAt) {
    }

    /** 주문 상세의 항목 한 줄 (§4.4) */
    public record OrderItemView(String menuName, int unitPrice, int quantity, String optionsDesc) {
    }

    /** 주문 상세 (§4.4) */
    public record OrderDetail(long orderId, String orderNo, String status, String fulfillmentType,
                              LocalDateTime scheduledAt, String deliveryAddress, int totalPrice,
                              int discountPrice, List<OrderItemView> items) {
    }

    /** 배달 가능 여부 (§4.1) */
    public record DeliveryCheck(boolean deliverable, String reason) {
    }
}
