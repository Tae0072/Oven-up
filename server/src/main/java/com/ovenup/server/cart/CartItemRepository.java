package com.ovenup.server.cart;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CartItemRepository extends JpaRepository<CartItemEntity, Long> {

    List<CartItemEntity> findByUserIdOrderByIdAsc(Long userId);

    Optional<CartItemEntity> findByIdAndUserId(Long id, Long userId);

    void deleteByUserId(Long userId);
}
