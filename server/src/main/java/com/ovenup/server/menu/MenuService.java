package com.ovenup.server.menu;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.menu.dto.MenuUpsertRequest;
import com.ovenup.server.review.ReviewEntity;
import com.ovenup.server.review.ReviewRepository;

/**
 * 메뉴 데이터를 제공하는 서비스. 이제 DB(JPA)에서 읽어온다.
 * DB의 엔티티(MenuEntity)를 화면/앱이 쓰는 응답용 DTO(Menu)로 바꿔서 돌려준다.
 * (응답 형태는 그대로라 앱은 수정 없이 동작 — 05_API §3.1~3.2)
 */
@Service
@Transactional(readOnly = true)
public class MenuService {

    private final MenuJpaRepository menuRepository;
    private final ReviewRepository reviewRepository;

    public MenuService(MenuJpaRepository menuRepository, ReviewRepository reviewRepository) {
        this.menuRepository = menuRepository;
        this.reviewRepository = reviewRepository;
    }

    /** category(생략 시 전체) 로 메뉴 목록 조회. */
    public List<Menu> findAll(String category) {
        List<MenuEntity> entities = (category == null || category.isBlank())
                ? menuRepository.findAllByOrderByIdAsc()
                : menuRepository.findByCategoryOrderByIdAsc(category);
        Map<Long, int[]> ratings = ratingMap();
        return entities.stream().map(e -> toDto(e, ratings)).toList();
    }

    public Optional<Menu> findById(long id) {
        Map<Long, int[]> ratings = ratingMap();
        return menuRepository.findById(id).map(e -> toDto(e, ratings));
    }

    // ===== 관리자(사장님)용 =====

    /** 관리자: 전체 메뉴(품절 포함) */
    public List<Menu> adminList() {
        Map<Long, int[]> ratings = ratingMap();
        return menuRepository.findAllByOrderByIdAsc().stream().map(e -> toDto(e, ratings)).toList();
    }

    /** 메뉴별 별점 합계·개수 맵을 만든다. (DB 무관하게 자바에서 집계) */
    private Map<Long, int[]> ratingMap() {
        Map<Long, int[]> map = new HashMap<>();
        for (ReviewEntity r : reviewRepository.findAll()) {
            int[] acc = map.computeIfAbsent(r.getMenuId(), k -> new int[2]);
            acc[0] += r.getRating();
            acc[1] += 1;
        }
        return map;
    }

    /** 관리자: 메뉴 등록 */
    @Transactional
    public Menu create(MenuUpsertRequest req) {
        validate(req);
        MenuEntity saved = menuRepository.save(new MenuEntity(
                req.name().trim(), nullToEmpty(req.description()), req.price(),
                blankTo(req.category(), "샌드위치"), nullToEmpty(req.bread()),
                blankTo(req.emoji(), "🥪"), req.best(), null, "판매중", new ArrayList<>()));
        return toDto(saved, Map.of());
    }

    /** 관리자: 메뉴 수정 */
    @Transactional
    public Menu update(long id, MenuUpsertRequest req) {
        validate(req);
        MenuEntity menu = menuRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("MENU_NOT_FOUND", "메뉴를 찾을 수 없습니다."));
        menu.update(req.name().trim(), nullToEmpty(req.description()), req.price(),
                blankTo(req.category(), "샌드위치"), nullToEmpty(req.bread()), blankTo(req.emoji(), "🥪"), req.best());
        return toDto(menu, ratingMap());
    }

    /** 관리자: 품절/판매중 토글 */
    @Transactional
    public Menu setSoldOut(long id, boolean soldOut) {
        MenuEntity menu = menuRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("MENU_NOT_FOUND", "메뉴를 찾을 수 없습니다."));
        menu.changeStatus(soldOut ? "품절" : "판매중");
        return toDto(menu, ratingMap());
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

    /** DB 엔티티 → 응답용 DTO 변환 (별점 맵에서 평균·개수 계산) */
    private static Menu toDto(MenuEntity entity, Map<Long, int[]> ratings) {
        List<MenuOption> options = entity.getOptions().stream()
                .map(o -> new MenuOption(o.getId(), o.getName(), o.getExtraPrice()))
                .toList();
        int[] acc = ratings.get(entity.getId());
        int count = acc == null ? 0 : acc[1];
        double avg = (acc == null || acc[1] == 0) ? 0
                : Math.round((double) acc[0] / acc[1] * 10) / 10.0;
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
                avg,
                count,
                options
        );
    }
}
