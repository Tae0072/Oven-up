package com.ovenup.server.coupon;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.coupon.dto.CouponDtos.CouponCheckResult;
import com.ovenup.server.coupon.dto.CouponDtos.CouponView;
import com.ovenup.server.coupon.dto.CouponDtos.CreateCouponRequest;

/** 쿠폰 처리 (05_API §10). 금액 계산·유효성은 서버에서 재검증(조작 방지). */
@Service
public class CouponService {

    private static final Set<String> TYPES = Set.of("AMOUNT", "PERCENT");

    private final CouponRepository couponRepository;
    private final CouponRedemptionRepository redemptionRepository;

    public CouponService(CouponRepository couponRepository, CouponRedemptionRepository redemptionRepository) {
        this.couponRepository = couponRepository;
        this.redemptionRepository = redemptionRepository;
    }

    /** 손님 미리보기: 예외 없이 유효 여부 + 할인액을 돌려준다. */
    @Transactional(readOnly = true)
    public CouponCheckResult check(Long userId, String code, int gross) {
        if (code == null || code.isBlank()) {
            return new CouponCheckResult(false, 0, "쿠폰 코드를 입력해 주세요.", code, null);
        }
        CouponEntity coupon = couponRepository.findByCode(code.trim()).orElse(null);
        if (coupon == null || !coupon.isActive()) {
            return new CouponCheckResult(false, 0, "사용할 수 없는 쿠폰이에요.", code, null);
        }
        if (coupon.getExpiresAt() != null && LocalDateTime.now().isAfter(coupon.getExpiresAt())) {
            return new CouponCheckResult(false, 0, "만료된 쿠폰이에요.", code, coupon.getName());
        }
        if (gross < coupon.getMinOrderAmount()) {
            return new CouponCheckResult(false, 0,
                    String.format("최소 주문금액 %,d원 이상부터 사용 가능해요.", coupon.getMinOrderAmount()),
                    code, coupon.getName());
        }
        if (redemptionRepository.existsByCouponIdAndUserId(coupon.getId(), userId)) {
            return new CouponCheckResult(false, 0, "이미 사용한 쿠폰이에요.", code, coupon.getName());
        }
        return new CouponCheckResult(true, coupon.discountFor(gross), null, code, coupon.getName());
    }

    /** 주문 확정 시: 코드가 있으면 검증 후 쿠폰 반환(유효하지 않으면 예외). 코드 없으면 null. */
    @Transactional(readOnly = true)
    public CouponEntity resolveForOrder(Long userId, String code, int gross) {
        if (code == null || code.isBlank()) {
            return null;
        }
        CouponCheckResult r = check(userId, code, gross);
        if (!r.valid()) {
            throw ApiException.badRequest("COUPON_INVALID", r.message());
        }
        return couponRepository.findByCode(code.trim()).orElseThrow();
    }

    @Transactional
    public void redeem(Long couponId, Long userId, Long orderId) {
        redemptionRepository.save(new CouponRedemptionEntity(couponId, userId, orderId));
    }

    // ===== 관리자 =====
    @Transactional
    public CouponView create(CreateCouponRequest req) {
        String code = req.code() == null ? "" : req.code().trim();
        if (code.isEmpty()) {
            throw ApiException.badRequest("INVALID_INPUT", "쿠폰 코드를 입력해 주세요.");
        }
        if (!TYPES.contains(req.type())) {
            throw ApiException.badRequest("INVALID_INPUT", "쿠폰 종류가 올바르지 않습니다(AMOUNT/PERCENT).");
        }
        if (req.value() <= 0) {
            throw ApiException.badRequest("INVALID_INPUT", "할인 값을 입력해 주세요.");
        }
        if (couponRepository.existsByCode(code)) {
            throw ApiException.conflict("DUPLICATE_CODE", "이미 있는 쿠폰 코드예요.");
        }
        LocalDateTime expires = parse(req.expiresAt());
        CouponEntity saved = couponRepository.save(new CouponEntity(code, req.name(), req.type(),
                req.value(), Math.max(0, req.minOrderAmount()), expires));
        return toView(saved);
    }

    @Transactional(readOnly = true)
    public List<CouponView> list() {
        return couponRepository.findAllByOrderByIdDesc().stream().map(this::toView).toList();
    }

    private CouponView toView(CouponEntity c) {
        return new CouponView(c.getId(), c.getCode(), c.getName(), c.getType(), c.getValue(),
                c.getMinOrderAmount(), c.getExpiresAt(), c.isActive());
    }

    private LocalDateTime parse(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (Exception e) {
            throw ApiException.badRequest("INVALID_INPUT", "만료 일시 형식이 올바르지 않습니다.");
        }
    }
}
