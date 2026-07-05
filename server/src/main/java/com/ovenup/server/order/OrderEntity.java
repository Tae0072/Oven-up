package com.ovenup.server.order;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

/**
 * 주문 (orders). 04_ERD. ('order'는 SQL 예약어라 테이블명 'orders' 사용)
 * - scheduledAt 있으면 예약 주문, 없으면 지금 주문.
 * - fulfillmentType: DINE_IN / TAKEOUT / DELIVERY
 * - status: 결제대기 → 결제완료 → 준비중 → ...
 */
@Entity
@Table(name = "orders")
public class OrderEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private String orderNo;

    private int totalPrice;

    private int discountPrice;

    private String fulfillmentType;

    private LocalDateTime scheduledAt;

    private String deliveryAddress;

    private int deliveryFee;

    @Column(length = 500)
    private String requestMsg;

    private String status;

    private String paymentMethod; // 결제 수단 (CARD/KAKAOPAY/...), 결제 전엔 null

    private LocalDateTime paidAt; // 결제 완료 시각, 결제 전엔 null

    private LocalDateTime createdAt;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "order_id")
    private List<OrderItemEntity> items = new ArrayList<>();

    protected OrderEntity() {
    }

    public OrderEntity(Long userId, int totalPrice, int discountPrice, String fulfillmentType,
                       LocalDateTime scheduledAt, String deliveryAddress, int deliveryFee,
                       String requestMsg, String status, List<OrderItemEntity> items) {
        this.userId = userId;
        this.totalPrice = totalPrice;
        this.discountPrice = discountPrice;
        this.fulfillmentType = fulfillmentType;
        this.scheduledAt = scheduledAt;
        this.deliveryAddress = deliveryAddress;
        this.deliveryFee = deliveryFee;
        this.requestMsg = requestMsg;
        this.status = status;
        this.items = items;
        this.createdAt = LocalDateTime.now();
    }

    /** 저장 후 id를 이용해 주문번호를 붙인다. */
    public void assignOrderNo(String orderNo) {
        this.orderNo = orderNo;
    }

    /** 결제 완료 처리: 상태를 '결제완료'로 바꾸고 결제 수단·시각을 기록한다. */
    public void markPaid(String paymentMethod) {
        this.status = "결제완료";
        this.paymentMethod = paymentMethod;
        this.paidAt = LocalDateTime.now();
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public LocalDateTime getPaidAt() {
        return paidAt;
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getOrderNo() {
        return orderNo;
    }

    public int getTotalPrice() {
        return totalPrice;
    }

    public int getDiscountPrice() {
        return discountPrice;
    }

    public String getFulfillmentType() {
        return fulfillmentType;
    }

    public LocalDateTime getScheduledAt() {
        return scheduledAt;
    }

    public String getDeliveryAddress() {
        return deliveryAddress;
    }

    public int getDeliveryFee() {
        return deliveryFee;
    }

    public String getRequestMsg() {
        return requestMsg;
    }

    public String getStatus() {
        return status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public List<OrderItemEntity> getItems() {
        return items;
    }
}
