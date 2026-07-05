package com.ovenup.server.order;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.order.dto.OrderResponses.OrderDetail;
import com.ovenup.server.order.dto.OrderResponses.OrderSummary;
import com.ovenup.server.order.dto.UpdateStatusRequest;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 관리자(사장님) 주문 관리 API (02_화면_정의서 A4 / 03_기능 §11).
 * 반드시 ADMIN 권한이어야 한다(서버에서 권한 확인).
 * - GET   /api/admin/orders            : 전체(또는 상태별) 주문 목록
 * - GET   /api/admin/orders/{id}       : 주문 상세
 * - PATCH /api/admin/orders/{id}/status: 주문 상태 변경
 */
@RestController
public class AdminOrderController {

    private final OrderService orderService;
    private final UserRepository userRepository;

    public AdminOrderController(OrderService orderService, UserRepository userRepository) {
        this.orderService = orderService;
        this.userRepository = userRepository;
    }

    /** 로그인 + ADMIN 권한 확인. 손님(USER)이면 403. */
    private void requireAdmin(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        UserEntity user = userRepository.findById((Long) attr)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        if (!"ADMIN".equals(user.getRole())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "관리자만 접근할 수 있어요.");
        }
    }

    @GetMapping("/api/admin/orders")
    public ApiResponse<List<OrderSummary>> list(HttpServletRequest request,
                                                @RequestParam(required = false) String status) {
        requireAdmin(request);
        return ApiResponse.ok(orderService.adminList(status));
    }

    @GetMapping("/api/admin/orders/{id}")
    public ApiResponse<OrderDetail> detail(HttpServletRequest request, @PathVariable long id) {
        requireAdmin(request);
        return ApiResponse.ok(orderService.adminDetail(id));
    }

    @PatchMapping("/api/admin/orders/{id}/status")
    public ApiResponse<OrderDetail> updateStatus(HttpServletRequest request, @PathVariable long id,
                                                 @RequestBody UpdateStatusRequest body) {
        requireAdmin(request);
        return ApiResponse.ok(orderService.updateStatus(id, body.status()));
    }
}
