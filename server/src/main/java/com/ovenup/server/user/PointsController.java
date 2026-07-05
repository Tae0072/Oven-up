package com.ovenup.server.user;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 적립금 API (05_API §10). 로그인 필요.
 * - GET /api/points : 내 적립금 잔액 + 적립률(%)
 */
@RestController
public class PointsController {

    /** 결제 시 적립 비율(%) — 기본 1%. application.properties의 app.point.earn-percent로 조정. */
    private final int earnPercent;
    private final UserRepository userRepository;

    public PointsController(@Value("${app.point.earn-percent:1}") int earnPercent,
                            UserRepository userRepository) {
        this.earnPercent = earnPercent;
        this.userRepository = userRepository;
    }

    public record PointsView(int balance, int earnPercent) {
    }

    @GetMapping("/api/points")
    public ApiResponse<PointsView> myPoints(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        UserEntity user = userRepository.findById((Long) attr)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        return ApiResponse.ok(new PointsView(user.getPointBalance(), earnPercent));
    }
}
