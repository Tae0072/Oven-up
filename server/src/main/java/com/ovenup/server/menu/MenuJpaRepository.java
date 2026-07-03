package com.ovenup.server.menu;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * 메뉴 DB 접근용 리포지토리. Spring Data JPA가 구현체를 자동 생성한다.
 */
public interface MenuJpaRepository extends JpaRepository<MenuEntity, Long> {

    List<MenuEntity> findAllByOrderByIdAsc();

    List<MenuEntity> findByCategoryOrderByIdAsc(String category);
}
