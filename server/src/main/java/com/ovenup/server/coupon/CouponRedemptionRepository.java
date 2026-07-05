package com.ovenup.server.coupon;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CouponRedemptionRepository extends JpaRepository<CouponRedemptionEntity, Long> {

    boolean existsByCouponIdAndUserId(Long couponId, Long userId);
}
