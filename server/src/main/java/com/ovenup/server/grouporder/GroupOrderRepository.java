package com.ovenup.server.grouporder;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupOrderRepository extends JpaRepository<GroupOrderEntity, Long> {

    List<GroupOrderEntity> findByUserIdOrderByIdDesc(Long userId);
}
