package com.ovenup.server.order.dto;

/** 배달 가능 여부 확인 요청 (05_API §4.1). 항목은 서버 장바구니에서 읽으므로 주소만 받는다. */
public record DeliveryCheckRequest(String address) {
}
