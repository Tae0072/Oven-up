package com.ovenup.server.order;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.cart.CartLineComputed;
import com.ovenup.server.cart.CartService;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.order.dto.CreateOrderRequest;
import com.ovenup.server.order.dto.DeliveryCheckRequest;
import com.ovenup.server.order.dto.OrderResponses.DeliveryCheck;
import com.ovenup.server.order.dto.OrderResponses.OrderCreated;
import com.ovenup.server.order.dto.OrderResponses.OrderDetail;
import com.ovenup.server.order.dto.OrderResponses.OrderItemView;
import com.ovenup.server.order.dto.OrderResponses.OrderSummary;

/**
 * 주문 처리. (05_API §4, 03_기능_명세서 §4·§6)
 * 주문 항목은 **서버 장바구니(cart_item)** 에서 읽는다. 금액·배달조건을 서버가 재검증하고,
 * 주문 성공 시 장바구니를 비운다. (화면 값 신뢰 금지)
 */
@Service
public class OrderService {

    private static final String DELIVERABLE_BUILDING = "명지에코펠리스";
    private static final int MIN_SANDWICH_FOR_DELIVERY = 2;
    private static final int DELIVERY_FEE = 0;
    private static final Set<String> FULFILLMENT_TYPES = Set.of("DINE_IN", "TAKEOUT", "DELIVERY");
    private static final DateTimeFormatter ORDER_NO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final CartService cartService;
    private final OrderRepository orderRepository;

    public OrderService(CartService cartService, OrderRepository orderRepository) {
        this.cartService = cartService;
        this.orderRepository = orderRepository;
    }

    @Transactional
    public OrderCreated createOrder(Long userId, CreateOrderRequest request) {
        String fulfillment = request.fulfillmentType();
        if (fulfillment == null || !FULFILLMENT_TYPES.contains(fulfillment)) {
            throw ApiException.badRequest("INVALID_INPUT", "수령 방식이 올바르지 않습니다.");
        }

        List<CartLineComputed> lines = cartService.computeLines(userId);
        if (lines.isEmpty()) {
            throw ApiException.badRequest("EMPTY_CART", "장바구니가 비어 있어요.");
        }
        int subtotal = lines.stream().mapToInt(CartLineComputed::lineprice).sum();
        int sandwichCount = sandwichCount(lines);

        String deliveryAddress = null;
        int deliveryFee = 0;
        if ("DELIVERY".equals(fulfillment)) {
            deliveryAddress = request.deliveryAddress();
            if (!isBuildingOk(deliveryAddress)) {
                throw ApiException.badRequest("DELIVERY_NOT_ALLOWED",
                        "명지에코펠리스 건물만 배달 가능해요. 픽업으로 주문해 주세요.");
            }
            if (sandwichCount < MIN_SANDWICH_FOR_DELIVERY) {
                throw ApiException.badRequest("DELIVERY_NOT_ALLOWED",
                        "직배송은 샌드위치 2개 이상부터 가능해요. 픽업으로 주문해 주세요.");
            }
            deliveryFee = DELIVERY_FEE;
        }

        LocalDateTime scheduledAt = parseScheduledAt(request.scheduledAt());
        int total = subtotal + deliveryFee;

        List<OrderItemEntity> items = lines.stream()
                .map(l -> new OrderItemEntity(l.menuId(), l.menuName(), l.unitPrice(), l.quantity(), l.optionsDesc()))
                .toList();

        OrderEntity order = new OrderEntity(userId, total, 0, fulfillment, scheduledAt,
                deliveryAddress, deliveryFee, request.requestMsg(), "결제대기",
                new java.util.ArrayList<>(items));
        order = orderRepository.save(order);
        order.assignOrderNo(order.getCreatedAt().format(ORDER_NO_DATE)
                + "-" + String.format("%04d", order.getId()));
        orderRepository.save(order);

        // 주문이 만들어졌으니 장바구니를 비운다.
        cartService.clear(userId);

        return new OrderCreated(order.getId(), order.getOrderNo(), order.getTotalPrice(), order.getStatus());
    }

    @Transactional(readOnly = true)
    public DeliveryCheck deliveryCheck(Long userId, DeliveryCheckRequest request) {
        List<CartLineComputed> lines = cartService.computeLines(userId);
        if (!isBuildingOk(request.address())) {
            return new DeliveryCheck(false, "명지에코펠리스 건물만 배달 가능해요. 픽업으로 주문해 주세요.");
        }
        if (sandwichCount(lines) < MIN_SANDWICH_FOR_DELIVERY) {
            return new DeliveryCheck(false, "직배송은 샌드위치 2개 이상부터 가능해요. 픽업으로 주문해 주세요.");
        }
        return new DeliveryCheck(true, null);
    }

    @Transactional(readOnly = true)
    public List<OrderSummary> myOrders(Long userId) {
        return orderRepository.findByUserIdOrderByIdDesc(userId).stream()
                .map(o -> new OrderSummary(o.getId(), o.getOrderNo(), o.getTotalPrice(),
                        o.getFulfillmentType(), o.getScheduledAt(), o.getStatus(), o.getCreatedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public OrderDetail orderDetail(Long userId, long orderId) {
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "주문을 찾을 수 없습니다."));
        if (!order.getUserId().equals(userId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "본인 주문만 볼 수 있어요.");
        }
        List<OrderItemView> items = order.getItems().stream()
                .map(i -> new OrderItemView(i.getMenuName(), i.getUnitPrice(), i.getQuantity(), i.getOptionsDesc()))
                .toList();
        return new OrderDetail(order.getId(), order.getOrderNo(), order.getStatus(), order.getFulfillmentType(),
                order.getScheduledAt(), order.getDeliveryAddress(), order.getTotalPrice(),
                order.getDiscountPrice(), items);
    }

    private int sandwichCount(List<CartLineComputed> lines) {
        return lines.stream().filter(CartLineComputed::sandwich).mapToInt(CartLineComputed::quantity).sum();
    }

    private boolean isBuildingOk(String address) {
        return address != null && address.contains(DELIVERABLE_BUILDING);
    }

    private LocalDateTime parseScheduledAt(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (Exception e) {
            throw ApiException.badRequest("INVALID_INPUT", "예약 시간 형식이 올바르지 않습니다.");
        }
    }
}
