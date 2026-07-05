package com.ovenup.server.grouporder;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.AdminUpdateRequest;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.CreateGroupOrderRequest;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderCreated;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderView;
import com.ovenup.server.notification.NotificationService;

/** 단체 주문 문의 처리 (05_API §6, 03_기능_명세서 §7). 협의형(즉시 결제 아님). */
@Service
public class GroupOrderService {

    private static final Set<String> ADMIN_STATUSES = Set.of("접수", "협의중", "확정", "취소");

    private final GroupOrderRepository groupOrderRepository;
    private final NotificationService notificationService;

    public GroupOrderService(GroupOrderRepository groupOrderRepository,
                             NotificationService notificationService) {
        this.groupOrderRepository = groupOrderRepository;
        this.notificationService = notificationService;
    }

    @Transactional
    public GroupOrderCreated create(Long userId, CreateGroupOrderRequest request) {
        if (request.headcount() <= 0) {
            throw ApiException.badRequest("INVALID_INPUT", "인원/수량을 입력해 주세요.");
        }
        LocalDateTime desiredAt = parseDateTime(request.desiredAt());
        GroupOrderEntity saved = groupOrderRepository.save(new GroupOrderEntity(
                userId, desiredAt, request.headcount(), request.detail(), request.contact()));
        return new GroupOrderCreated(saved.getId(), saved.getStatus());
    }

    @Transactional(readOnly = true)
    public List<GroupOrderView> myGroupOrders(Long userId) {
        return groupOrderRepository.findByUserIdOrderByIdDesc(userId).stream()
                .map(g -> new GroupOrderView(g.getId(), g.getDesiredAt(), g.getHeadcount(), g.getDetail(),
                        g.getContact(), g.getStatus(), g.getAdminMemo(), g.getCreatedAt()))
                .toList();
    }

    // ===== 관리자(사장님)용 =====

    /** 관리자: 전체 단체주문 문의(최신순) */
    @Transactional(readOnly = true)
    public List<GroupOrderView> adminList() {
        return groupOrderRepository.findAllByOrderByIdDesc().stream()
                .map(GroupOrderService::toView)
                .toList();
    }

    /** 관리자: 상태·메모 갱신 + 손님 알림 */
    @Transactional
    public GroupOrderView adminUpdate(long id, AdminUpdateRequest request) {
        if (request.status() != null && !request.status().isBlank()
                && !ADMIN_STATUSES.contains(request.status())) {
            throw ApiException.badRequest("INVALID_INPUT", "변경할 수 없는 상태입니다.");
        }
        GroupOrderEntity g = groupOrderRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("NOT_FOUND", "단체주문 문의를 찾을 수 없습니다."));
        String memo = request.adminMemo() == null ? "" : request.adminMemo().trim();
        g.updateByAdmin(request.status(), memo);
        groupOrderRepository.save(g);

        notificationService.notifyUser(g.getUserId(), "단체주문 문의 업데이트",
                "단체주문 문의가 '" + g.getStatus() + "' 상태로 업데이트됐어요.", "GROUP_ORDER", g.getId());
        return toView(g);
    }

    private static GroupOrderView toView(GroupOrderEntity g) {
        return new GroupOrderView(g.getId(), g.getDesiredAt(), g.getHeadcount(), g.getDetail(),
                g.getContact(), g.getStatus(), g.getAdminMemo(), g.getCreatedAt());
    }

    private LocalDateTime parseDateTime(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (Exception e) {
            throw ApiException.badRequest("INVALID_INPUT", "희망 일시 형식이 올바르지 않습니다.");
        }
    }
}
