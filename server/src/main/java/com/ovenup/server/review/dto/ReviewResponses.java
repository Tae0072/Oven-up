package com.ovenup.server.review.dto;

import java.time.LocalDateTime;
import java.util.List;

/** 리뷰 응답 DTO 모음 */
public final class ReviewResponses {

    private ReviewResponses() {
    }

    /** 리뷰 한 건 */
    public record ReviewView(long reviewId, int rating, String content,
                             String authorName, LocalDateTime createdAt) {
    }

    /** 메뉴 리뷰 요약 + 목록 */
    public record MenuReviews(double ratingAvg, int reviewCount, List<ReviewView> items) {
    }
}
