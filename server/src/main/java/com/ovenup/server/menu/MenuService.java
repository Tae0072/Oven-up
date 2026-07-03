package com.ovenup.server.menu;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

/**
 * 메뉴 데이터를 제공하는 서비스.
 * ⚠️ 지금은 메모리에 고정된 5VEN UP 대표 메뉴 7종(가짜 시드)입니다.
 *    로드맵 3단계에서 MySQL + JPA(menu 테이블)로 교체합니다. (04_ERD, 05_API §3)
 */
@Service
public class MenuService {

    private static final String SANDWICH = "샌드위치";
    private static final String ON_SALE = "ON_SALE";

    // 샌드위치 공통 옵션
    private static final List<MenuOption> COMMON_OPTIONS = List.of(
            new MenuOption(101, "치즈 추가", 1000),
            new MenuOption(102, "베이컨 추가", 1500),
            new MenuOption(103, "아보카도 추가", 2000),
            new MenuOption(104, "매운 소스", 0)
    );

    private final List<Menu> menus = List.of(
            new Menu(1, "LA갈비 바게트 샌드위치", "달콤짭짤한 LA갈비를 바삭한 바게트에 듬뿍. 5VEN UP 대표 메뉴.",
                    12900, SANDWICH, "바게트", "🥖", true, "", ON_SALE, COMMON_OPTIONS),
            new Menu(2, "잠봉 루꼴라 샌드위치", "잠봉과 루꼴라의 담백한 조합. 치아바타로 든든하게.",
                    12000, SANDWICH, "치아바타", "🥪", false, "", ON_SALE, COMMON_OPTIONS),
            new Menu(3, "차지키 연어 샌드위치", "훈제 연어와 상큼한 차지키 소스.",
                    11000, SANDWICH, "바게트", "🐟", false, "", ON_SALE, COMMON_OPTIONS),
            new Menu(4, "풀드포크 샌드위치", "오래 익힌 풀드포크를 샤워도우에.",
                    11000, SANDWICH, "샤워도우", "🥓", false, "", ON_SALE, COMMON_OPTIONS),
            new Menu(5, "머쉬룸 치즈 샌드위치", "버섯과 치즈의 고소한 풍미.",
                    9500, SANDWICH, "샤워도우", "🍄", false, "", ON_SALE, COMMON_OPTIONS),
            new Menu(6, "크랜베리 치킨 샌드위치", "크랜베리의 상큼함과 부드러운 치킨.",
                    8500, SANDWICH, "치아바타", "🍗", false, "", ON_SALE, COMMON_OPTIONS),
            new Menu(7, "당근라페 샌드위치", "새콤한 당근라페로 산뜻하게.",
                    8500, SANDWICH, "치아바타", "🥕", false, "", ON_SALE, COMMON_OPTIONS)
    );

    /** category(생략 시 전체) 로 메뉴 목록 조회. */
    public List<Menu> findAll(String category) {
        if (category == null || category.isBlank()) {
            return menus;
        }
        return menus.stream()
                .filter(m -> m.category().equals(category))
                .toList();
    }

    public Optional<Menu> findById(long id) {
        return menus.stream().filter(m -> m.id() == id).findFirst();
    }
}
