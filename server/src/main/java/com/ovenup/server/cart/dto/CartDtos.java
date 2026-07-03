package com.ovenup.server.cart.dto;

import java.util.List;

/**
 * 장바구니 요청/응답 DTO 모음 (05_API §3.3~3.5).
 */
public final class CartDtos {

    private CartDtos() {
    }

    /** 담기 요청 (§3.4) */
    public record AddCartItemRequest(Long menuId, int quantity, List<Long> optionIds) {
    }

    /** 수량 변경 요청 (§3.5) */
    public record UpdateQuantityRequest(int quantity) {
    }

    /** 장바구니 한 줄 응답 (§3.3) */
    public record CartLineView(long cartItemId, long menuId, String menuName, int quantity,
                               List<Long> optionIds, String optionsDesc, int lineprice) {
    }

    /** 장바구니 전체 응답 (§3.3) */
    public record CartView(List<CartLineView> items, int totalPrice) {
    }
}
