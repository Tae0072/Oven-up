package com.ovenup.server.user;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UserAddressRepository extends JpaRepository<UserAddressEntity, Long> {

    List<UserAddressEntity> findByUserIdOrderByIdDesc(Long userId);

    boolean existsByUserIdAndAddress(Long userId, String address);
}
