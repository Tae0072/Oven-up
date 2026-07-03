package com.ovenup.server.grouporder;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 단체 주문 문의 (group_order). 04_ERD / 05_API §6.
 * 즉시 결제가 아니라 협의형. status: 접수/협의중/확정/취소. adminMemo는 사장님 답변.
 */
@Entity
@Table(name = "group_order")
public class GroupOrderEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private LocalDateTime desiredAt;

    private int headcount;

    @Column(length = 1000)
    private String detail;

    private String contact;

    private String status;

    @Column(length = 1000)
    private String adminMemo;

    private LocalDateTime createdAt;

    protected GroupOrderEntity() {
    }

    public GroupOrderEntity(Long userId, LocalDateTime desiredAt, int headcount, String detail, String contact) {
        this.userId = userId;
        this.desiredAt = desiredAt;
        this.headcount = headcount;
        this.detail = detail;
        this.contact = contact;
        this.status = "접수";
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public LocalDateTime getDesiredAt() {
        return desiredAt;
    }

    public int getHeadcount() {
        return headcount;
    }

    public String getDetail() {
        return detail;
    }

    public String getContact() {
        return contact;
    }

    public String getStatus() {
        return status;
    }

    public String getAdminMemo() {
        return adminMemo;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
