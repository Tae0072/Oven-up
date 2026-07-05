package com.ovenup.server.review;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 메뉴 리뷰(별점 + 후기). 04_ERD review.
 * - 구매한 손님만 작성(서버에서 결제완료 주문에 해당 메뉴가 있는지 확인).
 * - 메뉴당 한 손님이 1개만 작성.
 */
@Entity
@Table(name = "review")
public class ReviewEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private long menuId;

    /** 별점 1~5 */
    private int rating;

    @Column(length = 500)
    private String content;

    /** 작성 당시 표시 이름(회원 이름) */
    private String authorName;

    private LocalDateTime createdAt;

    protected ReviewEntity() {
    }

    public ReviewEntity(Long userId, long menuId, int rating, String content, String authorName) {
        this.userId = userId;
        this.menuId = menuId;
        this.rating = rating;
        this.content = content;
        this.authorName = authorName;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public long getMenuId() {
        return menuId;
    }

    public int getRating() {
        return rating;
    }

    public String getContent() {
        return content;
    }

    public String getAuthorName() {
        return authorName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
