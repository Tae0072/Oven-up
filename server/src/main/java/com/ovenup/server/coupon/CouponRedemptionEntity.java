package com.ovenup.server.coupon;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** 쿠폰 사용 기록 (coupon_redemption). 한 손님이 한 쿠폰을 한 번만 쓰도록 확인용. */
@Entity
@Table(name = "coupon_redemption")
public class CouponRedemptionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long couponId;

    private Long userId;

    private Long orderId;

    private LocalDateTime createdAt;

    protected CouponRedemptionEntity() {
    }

    public CouponRedemptionEntity(Long couponId, Long userId, Long orderId) {
        this.couponId = couponId;
        this.userId = userId;
        this.orderId = orderId;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }
}
