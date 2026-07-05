package com.ovenup.server.menu;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.menu.dto.MenuUpsertRequest;

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

    // ===== 관리자(사장님)용 =====

    /** 관리자: 전체 메뉴(품절 포함) */
    public List<Menu> adminList() {
        return menuRepository.findAllByOrderByIdAsc().stream().map(MenuService::toDto).toList();
    }

    /** 관리자: 메뉴 등록 */
    @Transactional
    public Menu create(MenuUpsertRequest req) {
        validate(req);
        MenuEntity saved = menuRepository.save(new MenuEntity(
                req.name().trim(), nullToEmpty(req.description()), req.price(),
                blankTo(req.category(), "샌드위치"), nullToEmpty(req.bread()),
                blankTo(req.emoji(), "🥪"), req.best(), null, "판매중", new ArrayList<>()));
        return toDto(saved);
    }

    /** 관리자: 메뉴 수정 */
    @Transactional
    public Menu update(long id, MenuUpsertRequest req) {
        validate(req);
        MenuEntity menu = menuRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("MENU_NOT_FOUND", "메뉴를 찾을 수 없습니다."));
        menu.update(req.name().trim(), nullToEmpty(req.description()), req.price(),
                blankTo(req.category(), "샌드위치"), nullToEmpty(req.bread()), blankTo(req.emoji(), "🥪"), req.best());
        return toDto(menu);
    }

    /** 관리자: 품절/판매중 토글 */
    @Transactional
    public Menu setSoldOut(long id, boolean soldOut) {
        MenuEntity menu = menuRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("MENU_NOT_FOUND", "메뉴를 찾을 수 없습니다."));
        menu.changeStatus(soldOut ? "품절" : "판매중");
        return toDto(menu);
    }

    /** 관리자: 메뉴 삭제 */
    @Transactional
    public void delete(long id) {
        if (!menuRepository.existsById(id)) {
            throw ApiException.notFound("MENU_NOT_FOUND", "메뉴를 찾을 수 없습니다.");
        }
        menuRepository.deleteById(id);
    }

    private void validate(MenuUpsertRequest req) {
        if (req.name() == null || req.name().trim().isEmpty()) {
            throw ApiException.badRequest("INVALID_INPUT", "메뉴 이름을 입력해 주세요.");
        }
        if (req.price() <= 0) {
            throw ApiException.badRequest("INVALID_INPUT", "가격을 입력해 주세요.");
        }
    }

    private String nullToEmpty(String s) {
        return s == null ? "" : s;
    }

    private String blankTo(String s, String fallback) {
        return (s == null || s.isBlank()) ? fallback : s;
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
