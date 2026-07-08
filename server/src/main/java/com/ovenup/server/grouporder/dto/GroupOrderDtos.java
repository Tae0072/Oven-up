package com.ovenup.server.grouporder.dto;

import java.time.LocalDateTime;

/** 단체 주문 요청/응답 DTO (05_API §6). */
public final class GroupOrderDtos {

    private GroupOrderDtos() {
    }

    /** 단체주문 문의 등록 요청 (§6.1) */
    public record CreateGroupOrderRequest(String desiredAt, int headcount, String detail, String contact) {
    }

    /** 등록 응답 (§6.1) */
    public record GroupOrderCreated(long groupOrderId, String status) {
    }

    /** 내 단체주문 목록 항목 (§6.2) */
    public record GroupOrderView(long groupOrderId, LocalDateTime desiredAt, int headcount, String detail,
                                 String contact, String status, String adminMemo, LocalDateTime createdAt) {
    }

    /** 관리자 상태·메모 갱신 요청 */
    public record AdminUpdateRequest(String status, String adminMemo) {
    }
}
