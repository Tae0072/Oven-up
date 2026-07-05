package com.ovenup.server.order.dto;

/** 관리자 주문 상태 변경 요청 (05_API §11 관리자). */
public record UpdateStatusRequest(String status) {
}
