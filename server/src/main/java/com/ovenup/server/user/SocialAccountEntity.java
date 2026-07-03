package com.ovenup.server.user;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 소셜 계정 연결 (social_account). 04_ERD.
 * 한 회원이 카카오·네이버를 모두 연결할 수 있어 별도 테이블.
 * provider: KAKAO / NAVER, providerUserId: 카카오·네이버가 준 고유 사용자 id.
 */
@Entity
@Table(name = "social_account")
public class SocialAccountEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private String provider;

    private String providerUserId;

    private LocalDateTime createdAt;

    protected SocialAccountEntity() {
    }

    public SocialAccountEntity(Long userId, String provider, String providerUserId) {
        this.userId = userId;
        this.provider = provider;
        this.providerUserId = providerUserId;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getProvider() {
        return provider;
    }

    public String getProviderUserId() {
        return providerUserId;
    }
}
