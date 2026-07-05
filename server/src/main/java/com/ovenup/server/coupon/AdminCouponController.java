package com.ovenup.server.coupon;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.coupon.dto.CouponDtos.CouponView;
import com.ovenup.server.coupon.dto.CouponDtos.CreateCouponRequest;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 관리자 쿠폰 관리 API (05_API §10, 화면 A8). ADMIN 권한 필요.
 * - POST /api/admin/coupons : 쿠폰 발급
 * - GET  /api/admin/coupons : 쿠폰 목록
 */
@RestController
public class AdminCouponController {

    private final CouponService couponService;
    private final UserRepository userRepository;

    public AdminCouponController(CouponService couponService, UserRepository userRepository) {
        this.couponService = couponService;
        this.userRepository = userRepository;
    }

    private void requireAdmin(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        UserEntity user = userRepository.findById((Long) attr)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        if (!"ADMIN".equals(user.getRole())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "관리자만 접근할 수 있어요.");
        }
    }

    @PostMapping("/api/admin/coupons")
    public ResponseEntity<ApiResponse<CouponView>> create(HttpServletRequest request,
                                                          @RequestBody CreateCouponRequest body) {
        requireAdmin(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(couponService.create(body)));
    }

    @GetMapping("/api/admin/coupons")
    public ApiResponse<List<CouponView>> list(HttpServletRequest request) {
        requireAdmin(request);
        return ApiResponse.ok(couponService.list());
    }
}
