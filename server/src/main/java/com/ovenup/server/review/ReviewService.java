package com.ovenup.server.review;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.order.OrderEntity;
import com.ovenup.server.order.OrderItemEntity;
import com.ovenup.server.order.OrderRepository;
import com.ovenup.server.review.dto.CreateReviewRequest;
import com.ovenup.server.review.dto.ReviewResponses.MenuReviews;
import com.ovenup.server.review.dto.ReviewResponses.ReviewView;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

/**
 * 리뷰(별점·후기) 처리. (03_기능 §12)
 * - 결제 완료한 주문에 해당 메뉴가 있는 손님만 작성 가능.
 * - 메뉴당 한 손님이 1개만.
 */
@Service
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    public ReviewService(ReviewRepository reviewRepository, OrderRepository orderRepository,
                         UserRepository userRepository) {
        this.reviewRepository = reviewRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ReviewView create(Long userId, long menuId, CreateReviewRequest request) {
        int rating = request.rating();
        if (rating < 1 || rating > 5) {
            throw ApiException.badRequest("INVALID_INPUT", "별점은 1~5점 사이여야 해요.");
        }
        if (reviewRepository.existsByUserIdAndMenuId(userId, menuId)) {
            throw ApiException.conflict("REVIEW_DUPLICATED", "이미 이 메뉴에 리뷰를 남겼어요.");
        }
        if (!hasPurchased(userId, menuId)) {
            throw ApiException.badRequest("NOT_PURCHASED", "구매한 메뉴만 리뷰를 쓸 수 있어요.");
        }
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        String content = request.content() == null ? "" : request.content().trim();
        ReviewEntity saved = reviewRepository.save(
                new ReviewEntity(userId, menuId, rating, content, user.getName()));
        return toView(saved);
    }

    /** 결제 완료(paidAt != null, 취소 아님) 주문 중 이 메뉴를 담은 게 있으면 구매 이력으로 인정. */
    private boolean hasPurchased(Long userId, long menuId) {
        List<OrderEntity> orders = orderRepository.findByUserIdOrderByIdDesc(userId);
        for (OrderEntity o : orders) {
            if (o.getPaidAt() == null || "취소".equals(o.getStatus())) {
                continue;
            }
            for (OrderItemEntity item : o.getItems()) {
                if (item.getMenuId() != null && item.getMenuId() == menuId) {
                    return true;
                }
            }
        }
        return false;
    }

    /** 이 회원이 이 메뉴에 리뷰를 쓸 수 있는지 (구매 이력 + 중복 여부). */
    @Transactional(readOnly = true)
    public java.util.Map<String, Object> eligibility(Long userId, long menuId) {
        boolean already = reviewRepository.existsByUserIdAndMenuId(userId, menuId);
        boolean purchased = hasPurchased(userId, menuId);
        String reason = "";
        if (already) {
            reason = "이미 이 메뉴에 리뷰를 남겼어요.";
        } else if (!purchased) {
            reason = "구매한 메뉴만 리뷰를 쓸 수 있어요.";
        }
        return java.util.Map.of("canWrite", purchased && !already, "reason", reason);
    }

    @Transactional(readOnly = true)
    public MenuReviews listForMenu(long menuId) {
        List<ReviewEntity> reviews = reviewRepository.findByMenuIdOrderByIdDesc(menuId);
        int count = reviews.size();
        double avg = count == 0 ? 0
                : Math.round(reviews.stream().mapToInt(ReviewEntity::getRating).average().orElse(0) * 10) / 10.0;
        List<ReviewView> items = reviews.stream().map(ReviewService::toView).toList();
        return new MenuReviews(avg, count, items);
    }

    private static ReviewView toView(ReviewEntity r) {
        return new ReviewView(r.getId(), r.getRating(), r.getContent(), r.getAuthorName(), r.getCreatedAt());
    }
}
