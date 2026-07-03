package com.ovenup.server.menu;

/**
 * 메뉴 옵션 (예: 치즈 추가 +1,000원).
 * 참고: 04_데이터구조_ERD menu_option, 05_API_명세서 §3.2
 */
public record MenuOption(long id, String name, int extraPrice) {
}
