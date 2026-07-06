package com.ovenup.server.review;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.review.dto.CreateReviewRequest;
import com.ovenup.server.review.dto.ReviewResponses.MenuReviews;
import com.ovenup.server.review.dto.ReviewResponses.ReviewView;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 리뷰 API (03_기능 §12).
 * - GET  /api/menus/{menuId}/reviews : 메뉴 리뷰 목록 + 요약 (공개)
 * - POST /api/menus/{menuId}/reviews : 리뷰 작성 (로그인 + 구매자)
 */
@RestController
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping("/api/menus/{menuId}/reviews")
    public ApiResponse<MenuReviews> list(@PathVariable long menuId) {
        return ApiResponse.ok(reviewService.listForMenu(menuId));
    }

    /** 리뷰 작성 가능 여부 (로그인 필요) — 앱이 작성 버튼 누를 때 미리 확인 */
    @GetMapping("/api/menus/{menuId}/reviews/eligibility")
    public ApiResponse<java.util.Map<String, Object>> eligibility(HttpServletRequest request,
                                                                  @PathVariable long menuId) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return ApiResponse.ok(reviewService.eligibility((Long) attr, menuId));
    }

    @PostMapping("/api/menus/{menuId}/reviews")
    public ResponseEntity<ApiResponse<ReviewView>> create(HttpServletRequest request, @PathVariable long menuId,
                                                          @RequestBody CreateReviewRequest body) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(reviewService.create((Long) attr, menuId, body)));
    }
}
