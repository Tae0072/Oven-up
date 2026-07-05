package com.ovenup.server.coupon;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.cart.CartLineComputed;
import com.ovenup.server.cart.CartService;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.coupon.dto.CouponDtos.CouponCheckResult;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 손님 쿠폰 API (05_API §10). 로그인 필요.
 * - GET /api/coupons/check?code=XXX : 현재 장바구니 기준으로 쿠폰 적용 가능/할인액 미리보기
 */
@RestController
public class CouponController {

    private final CouponService couponService;
    private final CartService cartService;

    public CouponController(CouponService couponService, CartService cartService) {
        this.couponService = couponService;
        this.cartService = cartService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    @GetMapping("/api/coupons/check")
    public ApiResponse<CouponCheckResult> check(HttpServletRequest request, @RequestParam String code,
                                                @RequestParam(required = false) Integer amount) {
        Long userId = requireUserId(request);
        // amount가 오면 그 금액 기준(주문 전 미리보기). 없으면 서버 장바구니 합계.
        int gross = (amount != null && amount > 0)
                ? amount
                : cartService.computeLines(userId).stream().mapToInt(CartLineComputed::lineprice).sum();
        return ApiResponse.ok(couponService.check(userId, code, gross));
    }
}
