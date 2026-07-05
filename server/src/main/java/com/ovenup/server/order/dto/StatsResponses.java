package com.ovenup.server.order.dto;

import java.util.List;

/**
 * 관리자 대시보드 통계 응답 (A5 / 03_기능 §11).
 * 매출·주문건수는 "결제 완료(취소 제외)" 주문만 집계한다.
 */
public final class StatsResponses {

    private StatsResponses() {
    }

    /** 하루치 매출 포인트(그래프용) */
    public record DailyPoint(String date, long sales, int orders) {
    }

    /** 상태별 주문 건수 */
    public record StatusCount(String status, int count) {
    }

    /** 인기 메뉴(판매 수량 기준) */
    public record TopMenu(String menuName, int quantity, long sales) {
    }

    /** 대시보드 전체 응답 */
    public record DashboardStats(
            long todaySales, int todayOrders,
            long weekSales, int weekOrders,
            long totalSales, int totalOrders,
            List<DailyPoint> daily,
            List<StatusCount> statusCounts,
            List<TopMenu> topMenus) {
    }
}
