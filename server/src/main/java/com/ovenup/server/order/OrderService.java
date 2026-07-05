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
import com.ovenup.server.notification.NotificationService;
import com.ovenup.server.payment.PaymentResult;
import com.ovenup.server.payment.PaymentVerifier;
import com.ovenup.server.payment.dto.PaymentDtos.PaymentDone;

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
    private static final Set<String> PAYMENT_METHODS =
            Set.of("CARD", "KAKAOPAY", "NAVERPAY", "TOSSPAY", "SAMSUNGPAY");
    private static final DateTimeFormatter ORDER_NO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final CartService cartService;
    private final OrderRepository orderRepository;
    private final PaymentVerifier paymentVerifier;
    private final NotificationService notificationService;

    public OrderService(CartService cartService, OrderRepository orderRepository,
                        PaymentVerifier paymentVerifier, NotificationService notificationService) {
        this.cartService = cartService;
        this.orderRepository = orderRepository;
        this.paymentVerifier = paymentVerifier;
        this.notificationService = notificationService;
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

    /**
     * 주문 결제 (05_API §5). '결제대기' 주문을 결제 대행사에 검증한 뒤 '결제완료'로 바꾼다.
     * 금액은 서버가 계산한 주문 금액 기준으로 재검증한다(화면 값 신뢰 금지).
     */
    @Transactional
    public PaymentDone pay(Long userId, long orderId, String method, String paymentRef) {
        if (method == null || !PAYMENT_METHODS.contains(method)) {
            throw ApiException.badRequest("INVALID_INPUT", "결제 수단이 올바르지 않습니다.");
        }
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "주문을 찾을 수 없습니다."));
        if (!order.getUserId().equals(userId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "본인 주문만 결제할 수 있어요.");
        }
        if (!"결제대기".equals(order.getStatus())) {
            throw ApiException.conflict("ALREADY_PROCESSED", "이미 결제되었거나 처리된 주문이에요.");
        }

        PaymentResult result = paymentVerifier.verify(method, paymentRef, order.getTotalPrice());
        if (!result.success()) {
            throw ApiException.badRequest("PAYMENT_FAILED",
                    result.message() != null ? result.message() : "결제에 실패했어요.");
        }
        if (result.paidAmount() != order.getTotalPrice()) {
            // 서버 금액과 실제 결제금액이 다르면 거부(조작 방지)
            throw ApiException.badRequest("AMOUNT_MISMATCH", "결제 금액이 주문 금액과 일치하지 않아요.");
        }

        order.markPaid(method);
        orderRepository.save(order);
        // 손님에게 접수 알림
        notificationService.notifyUser(order.getUserId(), "주문 " + order.getOrderNo(),
                "결제가 완료되어 주문이 접수됐어요.", "ORDER_PAID", order.getId());
        return new PaymentDone(order.getId(), order.getOrderNo(), order.getStatus(), order.getPaymentMethod());
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

    // ===== 관리자(사장님)용 =====
    // 관리자가 상태를 바꿀 수 있는 값 (결제대기/결제완료는 결제 흐름이 정하므로 제외)
    private static final Set<String> ADMIN_STATUSES =
            Set.of("준비중", "준비완료", "픽업완료", "배달중", "배달완료", "취소");

    /** 관리자: 전체(또는 상태별) 주문 목록 */
    @Transactional(readOnly = true)
    public List<OrderSummary> adminList(String status) {
        List<OrderEntity> orders = (status == null || status.isBlank())
                ? orderRepository.findAllByOrderByIdDesc()
                : orderRepository.findByStatusOrderByIdDesc(status);
        return orders.stream()
                .map(o -> new OrderSummary(o.getId(), o.getOrderNo(), o.getTotalPrice(),
                        o.getFulfillmentType(), o.getScheduledAt(), o.getStatus(), o.getCreatedAt()))
                .toList();
    }

    /** 관리자: 주문 상세 (소유권 검사 없음) */
    @Transactional(readOnly = true)
    public OrderDetail adminDetail(long orderId) {
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "주문을 찾을 수 없습니다."));
        List<OrderItemView> items = order.getItems().stream()
                .map(i -> new OrderItemView(i.getMenuName(), i.getUnitPrice(), i.getQuantity(), i.getOptionsDesc()))
                .toList();
        return new OrderDetail(order.getId(), order.getOrderNo(), order.getStatus(), order.getFulfillmentType(),
                order.getScheduledAt(), order.getDeliveryAddress(), order.getTotalPrice(),
                order.getDiscountPrice(), items);
    }

    /** 관리자: 주문 상태 변경 */
    @Transactional
    public OrderDetail updateStatus(long orderId, String status) {
        if (status == null || !ADMIN_STATUSES.contains(status)) {
            throw ApiException.badRequest("INVALID_INPUT", "변경할 수 없는 상태입니다.");
        }
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "주문을 찾을 수 없습니다."));
        order.changeStatus(status);
        orderRepository.save(order);
        // 손님에게 상태 변경 알림 (§9)
        notificationService.notifyUser(order.getUserId(), "주문 " + order.getOrderNo(),
                statusMessage(status), "ORDER_STATUS", order.getId());
        return adminDetail(orderId);
    }

    /** 상태별 손님 안내 문구 */
    private String statusMessage(String status) {
        return switch (status) {
            case "준비중" -> "주문을 준비하고 있어요.";
            case "준비완료" -> "준비가 완료됐어요! 픽업/수령해 주세요.";
            case "픽업완료" -> "픽업이 완료됐어요. 맛있게 드세요!";
            case "배달중" -> "배달을 출발했어요.";
            case "배달완료" -> "배달이 완료됐어요. 맛있게 드세요!";
            case "취소" -> "주문이 취소됐어요.";
            default -> "주문 상태가 '" + status + "'(으)로 바뀌었어요.";
        };
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
