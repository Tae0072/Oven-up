package com.ovenup.server.grouporder;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.CreateGroupOrderRequest;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderCreated;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderView;

/** 단체 주문 문의 처리 (05_API §6, 03_기능_명세서 §7). 협의형(즉시 결제 아님). */
@Service
public class GroupOrderService {

    private final GroupOrderRepository groupOrderRepository;

    public GroupOrderService(GroupOrderRepository groupOrderRepository) {
        this.groupOrderRepository = groupOrderRepository;
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
