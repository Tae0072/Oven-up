package com.ovenup.server.order;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.order.dto.CreateOrderRequest;
import com.ovenup.server.order.dto.DeliveryCheckRequest;
import com.ovenup.server.order.dto.OrderResponses.DeliveryCheck;
import com.ovenup.server.order.dto.OrderResponses.OrderCreated;
import com.ovenup.server.order.dto.OrderResponses.OrderDetail;
import com.ovenup.server.order.dto.OrderResponses.OrderSummary;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 주문 API (05_API §4). 모두 로그인 필요. 주문 항목은 서버 장바구니에서 읽는다.
 * - POST /api/orders                : 주문 생성 (결제대기)
 * - POST /api/orders/delivery-check : 배달 가능 여부 확인
 * - GET  /api/orders                : 내 주문 목록
 * - GET  /api/orders/{id}           : 주문 상세 (본인만)
 */
@RestController
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    @PostMapping("/api/orders")
    public ResponseEntity<ApiResponse<OrderCreated>> create(HttpServletRequest request,
                                                            @RequestBody CreateOrderRequest body) {
        Long userId = requireUserId(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(orderService.createOrder(userId, body)));
    }

    @PostMapping("/api/orders/delivery-check")
    public ApiResponse<DeliveryCheck> deliveryCheck(HttpServletRequest request,
                                                    @RequestBody DeliveryCheckRequest body) {
        Long userId = requireUserId(request);
        return ApiResponse.ok(orderService.deliveryCheck(userId, body));
    }

    @GetMapping("/api/orders")
    public ApiResponse<List<OrderSummary>> myOrders(HttpServletRequest request) {
        return ApiResponse.ok(orderService.myOrders(requireUserId(request)));
    }

    @GetMapping("/api/orders/{id}")
    public ApiResponse<OrderDetail> detail(HttpServletRequest request, @PathVariable long id) {
        return ApiResponse.ok(orderService.orderDetail(requireUserId(request), id));
    }
}
