package com.ovenup.server.review;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ReviewRepository extends JpaRepository<ReviewEntity, Long> {

    List<ReviewEntity> findByMenuIdOrderByIdDesc(long menuId);

    boolean existsByUserIdAndMenuId(Long userId, long menuId);
}
