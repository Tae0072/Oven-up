package com.ovenup.server.menu;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * 서버가 처음 뜰 때 메뉴 테이블이 비어 있으면 5VEN UP 대표 메뉴 7종을 넣어준다(시드).
 * ⚠️ 지금은 초기 개발용 시드. 나중에 관리자 메뉴 관리(A3) 기능이 생기면 그쪽으로 관리한다.
 */
@Component
public class DataInitializer implements CommandLineRunner {

    private static final String SANDWICH = "샌드위치";
    private static final String ON_SALE = "ON_SALE";

    private final MenuJpaRepository menuRepository;

    public DataInitializer(MenuJpaRepository menuRepository) {
        this.menuRepository = menuRepository;
    }

    @Override
    public void run(String... args) {
        if (menuRepository.count() > 0) {
            return; // 이미 데이터가 있으면 다시 넣지 않음
        }

        menuRepository.save(new MenuEntity("LA갈비 바게트 샌드위치",
                "달콤짭짤한 LA갈비를 바삭한 바게트에 듬뿍. 5VEN UP 대표 메뉴.",
                12900, SANDWICH, "바게트", "🥖", true, "", ON_SALE, commonOptions()));
        menuRepository.save(new MenuEntity("잠봉 루꼴라 샌드위치",
                "잠봉과 루꼴라의 담백한 조합. 치아바타로 든든하게.",
                12000, SANDWICH, "치아바타", "🥪", false, "", ON_SALE, commonOptions()));
        menuRepository.save(new MenuEntity("차지키 연어 샌드위치",
                "훈제 연어와 상큼한 차지키 소스.",
                11000, SANDWICH, "바게트", "🐟", false, "", ON_SALE, commonOptions()));
        menuRepository.save(new MenuEntity("풀드포크 샌드위치",
                "오래 익힌 풀드포크를 샤워도우에.",
                11000, SANDWICH, "샤워도우", "🥓", false, "", ON_SALE, commonOptions()));
        menuRepository.save(new MenuEntity("머쉬룸 치즈 샌드위치",
                "버섯과 치즈의 고소한 풍미.",
                9500, SANDWICH, "샤워도우", "🍄", false, "", ON_SALE, commonOptions()));
        menuRepository.save(new MenuEntity("크랜베리 치킨 샌드위치",
                "크랜베리의 상큼함과 부드러운 치킨.",
                8500, SANDWICH, "치아바타", "🍗", false, "", ON_SALE, commonOptions()));
        menuRepository.save(new MenuEntity("당근라페 샌드위치",
                "새콤한 당근라페로 산뜻하게.",
                8500, SANDWICH, "치아바타", "🥕", false, "", ON_SALE, commonOptions()));
    }

    /** 메뉴마다 새 옵션 엔티티 목록을 만들어 준다(엔티티는 공유하면 안 됨). */
    private List<MenuOptionEntity> commonOptions() {
        List<MenuOptionEntity> options = new ArrayList<>();
        options.add(new MenuOptionEntity("치즈 추가", 1000));
        options.add(new MenuOptionEntity("베이컨 추가", 1500));
        options.add(new MenuOptionEntity("아보카도 추가", 2000));
        options.add(new MenuOptionEntity("매운 소스", 0));
        return options;
    }
}
