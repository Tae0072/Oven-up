package com.ovenup.server.order.dto;

import java.util.List;

/** 배달 가능 여부 확인 요청 (05_API §4.1). 항목은 지금 담긴 것들(서버 장바구니 도입 전까지 요청으로 전달). */
public record DeliveryCheckRequest(String address, List<OrderItemRequest> items) {
}
