package com.ovenup.server.notification;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<NotificationEntity, Long> {

    List<NotificationEntity> findByUserIdOrderByIdDesc(Long userId);

    long countByUserIdAndReadFlagFalse(Long userId);

    Optional<NotificationEntity> findByIdAndUserId(Long id, Long userId);

    List<NotificationEntity> findByUserIdAndReadFlagFalse(Long userId);
}
