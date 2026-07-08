package com.ovenup.server.notification;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/**
 * 손님 기기의 FCM 토큰. (가이드 §3-1)
 * 같은 손님이 여러 기기를 쓰면 기기마다 한 줄씩 저장된다.
 * 토큰은 기기+앱 설치 단위로 고유하므로 unique — 다른 계정으로 다시 로그인하면 주인을 갈아탄다.
 */
@Entity
@Table(name = "device_token", uniqueConstraints = @UniqueConstraint(columnNames = "token"))
public class DeviceTokenEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false, length = 512)
    private String token;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected DeviceTokenEntity() {
    }

    public DeviceTokenEntity(Long userId, String token) {
        this.userId = userId;
        this.token = token;
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getToken() {
        return token;
    }

    /** 토큰 주인 변경(다른 계정으로 로그인한 경우) */
    public void reassignTo(Long newUserId) {
        this.userId = newUserId;
        this.updatedAt = LocalDateTime.now();
    }
}
