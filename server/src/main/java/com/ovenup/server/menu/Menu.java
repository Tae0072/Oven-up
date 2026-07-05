package com.ovenup.server.menu;

import java.util.List;

/**
 * 메뉴 한 개.
 * - category: 배달 조건 판정용 분류(예: "샌드위치"). 04_ERD §4 / 05_API §3.
 * - bread: 화면 카테고리 탭용 빵 종류(바게트/치아바타/샤워도우).
 * - imageUrl: 사진 주소(지금은 비어 있고 emoji로 대체).
 * - status: ON_SALE / SOLD_OUT
 */
public record Menu(
        long id,
        String name,
        String description,
        int price,
        String category,
        String bread,
        String emoji,
        boolean isBest,
        String imageUrl,
        String status,
        double ratingAvg,
        int reviewCount,
        List<MenuOption> options
) {
}
