package com.ovenup.server.review.dto;

/** 리뷰 작성 요청 (별점 1~5 + 후기) */
public record CreateReviewRequest(int rating, String content) {
}
