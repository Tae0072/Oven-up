package com.ovenup.server.cart;

import java.util.List;

/**
 * 장바구니 한 줄을 메뉴/옵션 가격까지 계산해 담은 값(서비스 내부·주문 생성 공용).
 */
public record CartLineComputed(
        long cartItemId,
        long menuId,
        String menuName,
        int unitPrice,
        int quantity,
        List<Long> optionIds,
        String optionsDesc,
        boolean sandwich) {

    public int lineprice() {
        return unitPrice * quantity;
    }
}
