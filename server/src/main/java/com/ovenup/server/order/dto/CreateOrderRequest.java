package com.ovenup.server.order.dto;

/**
 * 주문 생성 요청 (05_API §4.2).
 * 주문 항목은 서버 장바구니에서 읽으므로 요청에는 담지 않는다.
 * - fulfillmentType: DINE_IN | TAKEOUT | DELIVERY
 * - scheduledAt: 예약주문이면 ISO 시각 문자열(예: 2026-07-05T14:30:00), 지금 주문이면 null
 * - deliveryAddress: 배달일 때만 (명지에코펠리스 건물 내)
 * - couponCode: 사용할 쿠폰 코드(없으면 null)
 * - usePoints: 사용할 적립금(원). 없으면 0
 * - lat/lng: 앱이 확인한 현재 위치(선택). 있으면 서버가 건물 반경 안인지 보조 검증한다.
 */
public record CreateOrderRequest(
        String fulfillmentType,
        String scheduledAt,
        String deliveryAddress,
        String requestMsg,
        String couponCode,
        int usePoints,
        Double lat,
        Double lng) {
}
