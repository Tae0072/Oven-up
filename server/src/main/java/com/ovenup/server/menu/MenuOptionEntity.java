package com.ovenup.server.menu;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 메뉴 옵션 DB 테이블 (menu_option). 04_데이터구조_ERD menu_option.
 */
@Entity
@Table(name = "menu_option")
public class MenuOptionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private int extraPrice;

    /** JPA가 내부적으로 쓰는 기본 생성자 (직접 쓰지 않음) */
    protected MenuOptionEntity() {
    }

    public MenuOptionEntity(String name, int extraPrice) {
        this.name = name;
        this.extraPrice = extraPrice;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public int getExtraPrice() {
        return extraPrice;
    }
}
