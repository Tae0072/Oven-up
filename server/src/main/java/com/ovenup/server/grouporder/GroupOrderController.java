package com.ovenup.server.grouporder;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.CreateGroupOrderRequest;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderCreated;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderView;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 단체 주문 문의 API (05_API §6). 모두 로그인 필요.
 * - POST /api/group-orders : 단체주문 문의 접수 → 201
 * - GET  /api/group-orders : 내 단체주문 문의 목록(사장님 답변 포함)
 */
@RestController
public class GroupOrderController {

    private final GroupOrderService groupOrderService;

    public GroupOrderController(GroupOrderService groupOrderService) {
        this.groupOrderService = groupOrderService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    @PostMapping("/api/group-orders")
    public ResponseEntity<ApiResponse<GroupOrderCreated>> create(HttpServletRequest request,
                                                                 @RequestBody CreateGroupOrderRequest body) {
        GroupOrderCreated created = groupOrderService.create(requireUserId(request), body);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created));
    }

    @GetMapping("/api/group-orders")
    public ApiResponse<List<GroupOrderView>> myGroupOrders(HttpServletRequest request) {
        return ApiResponse.ok(groupOrderService.myGroupOrders(requireUserId(request)));
    }
}
