package com.ovenup.server.order;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.menu.MenuEntity;
import com.ovenup.server.menu.MenuJpaRepository;
import com.ovenup.server.menu.MenuOptionEntity;
import com.ovenup.server.order.dto.CreateOrderRequest;
import com.ovenup.server.order.dto.DeliveryCheckRequest;
import com.ovenup.server.order.dto.OrderItemRequest;
import com.ovenup.server.order.dto.OrderResponses.DeliveryCheck;
import com.ovenup.server.order.dto.OrderResponses.OrderCreated;
import com.ovenup.server.order.dto.OrderResponses.OrderDetail;
import com.ovenup.server.order.dto.OrderResponses.OrderItemView;
import com.ovenup.server.order.dto.OrderResponses.OrderSummary;

/**
 * 주문 처리. (05_API §4, 03_기능_명세서 §4·§6)
 * 핵심 보안 규칙:
 * - 금액은 화면 값을 믿지 않고 **서버가 메뉴 DB로 다시 계산**한다.
 * - 배달 조건(명지에코펠리스 건물 + 샌드위치 2개 이상)을 **서버에서 재검증**한다.
 *
 * 참고: 지금은 주문 항목을 요청으로 받는다. 서버 장바구니(05_API §3.3) 도입 후
 *       "서버 장바구니에서 항목을 읽는" 방식으로 교체 예정.
 */
@Service
public class OrderService {

    private static final String DELIVERABLE_BUILDING = "명지에코펠리스";
    private static final String SANDWICH = "샌드위치";
    private static final int MIN_SANDWICH_FOR_DELIVERY = 2;
    private static final int DELIVERY_FEE = 0;
    private static final Set<String> FULFILLMENT_TYPES = Set.of("DINE_IN", "TAKEOUT", "DELIVERY");
    private static final DateTimeFormatter ORDER_NO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final MenuJpaRepository menuRepository;
    private final OrderRepository orderRepository;

    public OrderService(MenuJpaRepository menuRepository, OrderRepository orderRepository) {
        this.menuRepository = menuRepository;
        this.orderRepository = orderRepository;
    }

    @Transactional
    public OrderCreated createOrder(Long userId, CreateOrderRequest request) {
        String fulfillment = request.fulfillmentType();
        if (fulfillment == null || !FULFILLMENT_TYPES.contains(fulfillment)) {
            throw ApiException.badRequest("INVALID_INPUT", "수령 방식이 올바르지 않습니다.");
        }

        Calc calc = calcItems(request.items());

        String deliveryAddress = null;
        int deliveryFee = 0;
        if ("DELIVERY".equals(fulfillment)) {
            deliveryAddress = request.deliveryAddress();
            if (!isBuildingOk(deliveryAddress)) {
                throw ApiException.badRequest("DELIVERY_NOT_ALLOWED",
                        "명지에코펠리스 건물만 배달 가능해요. 픽업으로 주문해 주세요.");
            }
            if (calc.sandwichCount() < MIN_SANDWICH_FOR_DELIVERY) {
                throw ApiException.badRequest("DELIVERY_NOT_ALLOWED",
                        "직배송은 샌드위치 2개 이상부터 가능해요. 픽업으로 주문해 주세요.");
            }
            deliveryFee = DELIVERY_FEE;
        }

        LocalDateTime scheduledAt = parseScheduledAt(request.scheduledAt());
        int total = calc.totalPrice() + deliveryFee;

        OrderEntity order = new OrderEntity(userId, total, 0, fulfillment, scheduledAt,
                deliveryAddress, deliveryFee, request.requestMsg(), "결제대기", calc.items());
        order = orderRepository.save(order);
        order.assignOrderNo(order.getCreatedAt().format(ORDER_NO_DATE)
                + "-" + String.format("%04d", order.getId()));
        orderRepository.save(order);

        return new OrderCreated(order.getId(), order.getOrderNo(), order.getTotalPrice(), order.getStatus());
    }

    @Transactional(readOnly = true)
    public DeliveryCheck deliveryCheck(DeliveryCheckRequest request) {
        Calc calc = calcItems(request.items());
        if (!isBuildingOk(request.address())) {
            return new DeliveryCheck(false, "명지에코펠리스 건물만 배달 가능해요. 픽업으로 주문해 주세요.");
        }
        if (calc.sandwichCount() < MIN_SANDWICH_FOR_DELIVERY) {
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

    // ===== 내부 계산 =====

    private record Calc(List<OrderItemEntity> items, int totalPrice, int sandwichCount) {
    }

    private Calc calcItems(List<OrderItemRequest> requestItems) {
        if (requestItems == null || requestItems.isEmpty()) {
            throw ApiException.badRequest("EMPTY_ORDER", "주문 항목이 없습니다.");
        }
        List<OrderItemEntity> items = new ArrayList<>();
        int total = 0;
        int sandwich = 0;
        for (OrderItemRequest ri : requestItems) {
            if (ri.menuId() == null) {
                throw ApiException.badRequest("INVALID_INPUT", "메뉴가 지정되지 않았습니다.");
            }
            MenuEntity menu = menuRepository.findById(ri.menuId())
                    .orElseThrow(() -> ApiException.badRequest("MENU_NOT_FOUND", "없는 메뉴가 포함되어 있습니다."));
            int qty = ri.quantity() <= 0 ? 1 : ri.quantity();
            List<Long> optionIds = ri.optionIds() == null ? List.of() : ri.optionIds();
            List<MenuOptionEntity> chosen = menu.getOptions().stream()
                    .filter(o -> optionIds.contains(o.getId()))
                    .toList();
            int optionSum = chosen.stream().mapToInt(MenuOptionEntity::getExtraPrice).sum();
            int unitPrice = menu.getPrice() + optionSum;
            String optionsDesc = chosen.stream().map(MenuOptionEntity::getName).collect(Collectors.joining(", "));
            items.add(new OrderItemEntity(menu.getId(), menu.getName(), unitPrice, qty, optionsDesc));
            total += unitPrice * qty;
            if (SANDWICH.equals(menu.getCategory())) {
                sandwich += qty;
            }
        }
        return new Calc(items, total, sandwich);
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
