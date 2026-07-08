package com.ovenup.server.user;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserEntity, Long> {

    Optional<UserEntity> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<UserEntity> findByLoginId(String loginId);

    boolean existsByLoginId(String loginId);

    /** 관리자(사장님) 목록 — 새 주문 알림 대상 */
    List<UserEntity> findByRole(String role);
}
