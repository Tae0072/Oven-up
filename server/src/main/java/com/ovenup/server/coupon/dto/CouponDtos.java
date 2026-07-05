package com.ovenup.server.coupon.dto;

import java.time.LocalDateTime;

/** 쿠폰 요청/응답 DTO (05_API §10). */
public final class CouponDtos {

    private CouponDtos() {
    }

    /** 관리자 쿠폰 발급 요청 */
    public record CreateCouponRequest(String code, String name, String type, int value,
                                      int minOrderAmount, String expiresAt) {
    }

    /** 쿠폰 정보 */
    public record CouponView(long couponId, String code, String name, String type, int value,
                             int minOrderAmount, LocalDateTime expiresAt, boolean active) {
    }

    /** 쿠폰 적용 확인 결과(손님 미리보기) */
    public record CouponCheckResult(boolean valid, int discount, String message, String code, String name) {
    }
}
