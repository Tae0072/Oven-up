package com.ovenup.server.cart;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 장바구니 항목 (cart_item). 회원별 서버 저장. 04_ERD cart_item / 05_API §3.3~3.5.
 * optionIds 는 선택 옵션 id를 콤마로 이어 저장한다(예: "101,102"). 없으면 빈 문자열.
 */
@Entity
@Table(name = "cart_item")
public class CartItemEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private Long menuId;

    private int quantity;

    private String optionIds;

    private LocalDateTime createdAt;

    protected CartItemEntity() {
    }

    public CartItemEntity(Long userId, Long menuId, int quantity, String optionIds) {
        this.userId = userId;
        this.menuId = menuId;
        this.quantity = quantity;
        this.optionIds = optionIds;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public Long getMenuId() {
        return menuId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getOptionIds() {
        return optionIds;
    }
}
