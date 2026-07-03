package com.ovenup.server.order.dto;

import java.util.List;

/** 주문 항목 요청 (menuId + 수량 + 선택 옵션 id들). 금액은 서버가 메뉴 DB로 재계산한다. */
public record OrderItemRequest(Long menuId, int quantity, List<Long> optionIds) {
}
