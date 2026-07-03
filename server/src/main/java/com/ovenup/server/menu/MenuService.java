package com.ovenup.server.menu;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 메뉴 데이터를 제공하는 서비스. 이제 DB(JPA)에서 읽어온다.
 * DB의 엔티티(MenuEntity)를 화면/앱이 쓰는 응답용 DTO(Menu)로 바꿔서 돌려준다.
 * (응답 형태는 그대로라 앱은 수정 없이 동작 — 05_API §3.1~3.2)
 */
@Service
@Transactional(readOnly = true)
public class MenuService {

    private final MenuJpaRepository menuRepository;

    public MenuService(MenuJpaRepository menuRepository) {
        this.menuRepository = menuRepository;
    }

    /** category(생략 시 전체) 로 메뉴 목록 조회. */
    public List<Menu> findAll(String category) {
        List<MenuEntity> entities = (category == null || category.isBlank())
                ? menuRepository.findAllByOrderByIdAsc()
                : menuRepository.findByCategoryOrderByIdAsc(category);
        return entities.stream().map(MenuService::toDto).toList();
    }

    public Optional<Menu> findById(long id) {
        return menuRepository.findById(id).map(MenuService::toDto);
    }

    /** DB 엔티티 → 응답용 DTO 변환 */
    private static Menu toDto(MenuEntity entity) {
        List<MenuOption> options = entity.getOptions().stream()
                .map(o -> new MenuOption(o.getId(), o.getName(), o.getExtraPrice()))
                .toList();
        return new Menu(
                entity.getId(),
                entity.getName(),
                entity.getDescription(),
                entity.getPrice(),
                entity.getCategory(),
                entity.getBread(),
                entity.getEmoji(),
                entity.isBest(),
                entity.getImageUrl(),
                entity.getStatus(),
                options
        );
    }
}
