package com.ovenup.server.menu;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

/**
 * 메뉴 DB 테이블 (menu). 04_데이터구조_ERD menu.
 * - category: 배달조건 판정용 분류(예: "샌드위치")
 * - bread: 화면 카테고리 탭용 빵 종류
 * - options: 이 메뉴의 옵션들 (menu_option 테이블, menu_id로 연결)
 */
@Entity
@Table(name = "menu")
public class MenuEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(length = 500)
    private String description;

    private int price;

    private String category;

    private String bread;

    private String emoji;

    private boolean best;

    private String imageUrl;

    private String status;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "menu_id")
    private List<MenuOptionEntity> options = new ArrayList<>();

    protected MenuEntity() {
    }

    public MenuEntity(String name, String description, int price, String category,
                      String bread, String emoji, boolean best, String imageUrl,
                      String status, List<MenuOptionEntity> options) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.category = category;
        this.bread = bread;
        this.emoji = emoji;
        this.best = best;
        this.imageUrl = imageUrl;
        this.status = status;
        this.options = options;
    }

    /** 관리자 메뉴 수정 */
    public void update(String name, String description, int price, String category,
                       String bread, String emoji, boolean best) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.category = category;
        this.bread = bread;
        this.emoji = emoji;
        this.best = best;
    }

    /** 판매 상태 변경 (판매중 / 품절) */
    public void changeStatus(String status) {
        this.status = status;
    }

    public boolean isSoldOut() {
        return "품절".equals(status);
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public int getPrice() {
        return price;
    }

    public String getCategory() {
        return category;
    }

    public String getBread() {
        return bread;
    }

    public String getEmoji() {
        return emoji;
    }

    public boolean isBest() {
        return best;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getStatus() {
        return status;
    }

    public List<MenuOptionEntity> getOptions() {
        return options;
    }
}
