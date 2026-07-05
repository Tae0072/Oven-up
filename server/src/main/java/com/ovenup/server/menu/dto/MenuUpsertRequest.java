package com.ovenup.server.menu.dto;

/**
 * 관리자 메뉴 등록/수정 요청 (05_API §11, 화면 A3).
 * - category: 배달조건 판정용(기본 "샌드위치")
 * - bread: 화면 카테고리 탭용 빵 종류
 */
public record MenuUpsertRequest(
        String name,
        String description,
        int price,
        String category,
        String bread,
        String emoji,
        boolean best) {
}
