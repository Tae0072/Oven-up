package com.ovenup.server.order;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 주문 항목 (order_item). 04_ERD.
 * 주문 당시의 메뉴 이름·단가를 함께 저장한다(나중에 메뉴 가격이 바뀌어도 과거 주문은 안 변함).
 */
@Entity
@Table(name = "order_item")
public class OrderItemEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long menuId;

    private String menuName;

    /** 옵션 포함 단가(주문 당시) */
    private int unitPrice;

    private int quantity;

    /** 선택 옵션 요약 (예: "치즈 추가, 베이컨 추가") */
    private String optionsDesc;

    protected OrderItemEntity() {
    }

    public OrderItemEntity(Long menuId, String menuName, int unitPrice, int quantity, String optionsDesc) {
        this.menuId = menuId;
        this.menuName = menuName;
        this.unitPrice = unitPrice;
        this.quantity = quantity;
        this.optionsDesc = optionsDesc;
    }

    public Long getId() {
        return id;
    }

    public Long getMenuId() {
        return menuId;
    }

    public String getMenuName() {
        return menuName;
    }

    public int getUnitPrice() {
        return unitPrice;
    }

    public int getQuantity() {
        return quantity;
    }

    public String getOptionsDesc() {
        return optionsDesc;
    }

    public int getLineTotal() {
        return unitPrice * quantity;
    }
}
