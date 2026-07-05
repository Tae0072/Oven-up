package com.ovenup.server.coupon;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 쿠폰 (coupon). 03_기능 §10.
 * type: AMOUNT(정액 할인) / PERCENT(정률 할인).
 * - AMOUNT면 value원 할인, PERCENT면 value% 할인.
 * - minOrderAmount 이상 주문에서만 사용. expiresAt 지나면 사용 불가.
 * - 한 손님이 같은 쿠폰을 한 번만 쓰도록 CouponRedemption으로 관리.
 */
@Entity
@Table(name = "coupon")
public class CouponEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String code;

    private String name;

    private String type; // AMOUNT / PERCENT

    @Column(name = "discount_value") // 'value'는 H2 예약어라 컬럼명을 바꿔 매핑
    private int value; // 원(AMOUNT) 또는 % (PERCENT)

    private int minOrderAmount;

    private LocalDateTime expiresAt; // null이면 무기한

    private boolean active;

    private LocalDateTime createdAt;

    protected CouponEntity() {
    }

    public CouponEntity(String code, String name, String type, int value, int minOrderAmount,
                        LocalDateTime expiresAt) {
        this.code = code;
        this.name = name;
        this.type = type;
        this.value = value;
        this.minOrderAmount = minOrderAmount;
        this.expiresAt = expiresAt;
        this.active = true;
        this.createdAt = LocalDateTime.now();
    }

    /** 주문 총액(gross)에 대한 할인액(원)을 계산한다. 총액을 넘지 않게 자른다. */
    public int discountFor(int gross) {
        int discount = "PERCENT".equals(type) ? (int) Math.floor(gross * (value / 100.0)) : value;
        if (discount < 0) {
            discount = 0;
        }
        return Math.min(discount, gross);
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public int getValue() {
        return value;
    }

    public int getMinOrderAmount() {
        return minOrderAmount;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public boolean isActive() {
        return active;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
