package com.ovenup.server.user;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 회원 DB 테이블. 04_데이터구조_ERD user.
 * ('user'는 일부 DB 예약어라 테이블명은 'users' 사용 — orders 와 같은 이유)
 */
@Entity
@Table(name = "users")
public class UserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    /** BCrypt로 해시된 비밀번호 (평문 저장 금지) */
    private String password;

    private String name;

    private String phone;

    /** 권한: USER(손님) / ADMIN(사장님) */
    private String role;

    private int pointBalance;

    private LocalDateTime createdAt;

    protected UserEntity() {
    }

    public UserEntity(String email, String password, String name, String phone) {
        this.email = email;
        this.password = password;
        this.name = name;
        this.phone = phone;
        this.role = "USER";
        this.pointBalance = 0;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getPassword() {
        return password;
    }

    public String getName() {
        return name;
    }

    public String getPhone() {
        return phone;
    }

    public String getRole() {
        return role;
    }

    public int getPointBalance() {
        return pointBalance;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
