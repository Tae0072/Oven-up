package com.ovenup.server.order;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.cart.CartLineComputed;
import com.ovenup.server.cart.CartService;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.coupon.CouponEntity;
import com.ovenup.server.coupon.CouponService;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;
import com.ovenup.server.order.dto.CreateOrderRequest;
import com.ovenup.server.order.dto.DeliveryCheckRequest;
import com.ovenup.server.order.dto.OrderResponses.DeliveryCheck;
import com.ovenup.server.order.dto.OrderResponses.OrderCreated;
import com.ovenup.server.order.dto.OrderResponses.OrderDetail;
import com.ovenup.server.order.dto.OrderResponses.OrderItemView;
import com.ovenup.server.order.dto.OrderResponses.OrderSummary;
import com.ovenup.server.order.dto.StatsResponses.DailyPoint;
import com.ovenup.server.order.dto.StatsResponses.DashboardStats;
import com.ovenup.server.order.dto.StatsResponses.StatusCount;
import com.ovenup.server.order.dto.StatsResponses.TopMenu;
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
    private final CouponService couponService;
    private final UserRepository userRepository;
    private final com.ovenup.server.building.BuildingPolicy buildingPolicy;
    private final int earnPercent;

    public OrderService(CartService cartService, OrderRepository orderRepository,
                        PaymentVerifier paymentVerifier, NotificationService notificationService,
                        CouponService couponService, UserRepository userRepository,
                        com.ovenup.server.building.BuildingPolicy buildingPolicy,
                        @Value("${app.point.earn-percent:1}") int earnPercent) {
        this.cartService = cartService;
        this.orderRepository = orderRepository;
        this.paymentVerifier = paymentVerifier;
        this.notificationService = notificationService;
        this.couponService = couponService;
        this.userRepository = userRepository;
        this.buildingPolicy = buildingPolicy;
        this.earnPercent = earnPercent;
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

        // 앱이 보낸 현재 위치(GPS)가 있으면 건물 반경 안인지 보조 확인한다.
        // (주소는 아래에서 별도 검증. 위치 미제공/실패는 통과 — 실내 GPS는 자주 안 잡히기 때문)
        if (request.lat() != null && request.lng() != null
                && !buildingPolicy.isWithinRadius(request.lat(), request.lng())) {
            throw ApiException.badRequest("LOCATION_NOT_ALLOWED",
                    buildingPolicy.name() + " 건물 안에서만 주문할 수 있어요. 건물로 이동한 뒤 다시 시도해 주세요.");
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
        validateReservation(scheduledAt);
        int gross = subtotal + deliveryFee;

        // 쿠폰 검증(있으면) → 할인액 (금액은 서버가 재계산, 조작 방지)
        CouponEntity coupon = couponService.resolveForOrder(userId, request.couponCode(), gross);
        int couponDiscount = coupon != null ? coupon.discountFor(gross) : 0;

        // 적립금 사용(있으면) → 잔액과 남은 결제금액 범위로 제한
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        int maxPoints = Math.max(0, Math.min(user.getPointBalance(), gross - couponDiscount));
        int pointsUsed = Math.max(0, Math.min(request.usePoints(), maxPoints));

        int discount = couponDiscount + pointsUsed;
        int total = gross - discount;

        List<OrderItemEntity> items = lines.stream()
                .map(l -> new OrderItemEntity(l.menuId(), l.menuName(), l.unitPrice(), l.quantity(), l.optionsDesc()))
                .toList();

        OrderEntity order = new OrderEntity(userId, total, discount, fulfillment, scheduledAt,
                deliveryAddress, deliveryFee, request.requestMsg(), "결제대기",
                new java.util.ArrayList<>(items));
        order = orderRepository.save(order);
        order.assignOrderNo(order.getCreatedAt().format(ORDER_NO_DATE)
                + "-" + String.format("%04d", order.getId()));
        orderRepository.save(order);

        // 적립금 차감 + 쿠폰 사용 기록
        if (pointsUsed > 0) {
            user.usePoints(pointsUsed);
            userRepository.save(user);
        }
        if (coupon != null) {
            couponService.redeem(coupon.getId(), userId, order.getId());
        }

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

        // 결제금액의 일정 비율 적립 지급
        int earn = (int) Math.floor(order.getTotalPrice() * (earnPercent / 100.0));
        if (earn > 0) {
            userRepository.findById(order.getUserId()).ifPresent(u -> {
                u.addPoints(earn);
                userRepository.save(u);
            });
        }

        // 손님에게 접수 알림
        String paidBody = earn > 0
                ? String.format("결제가 완료되어 주문이 접수됐어요. (%,d P 적립)", earn)
                : "결제가 완료되어 주문이 접수됐어요.";
        notificationService.notifyUser(order.getUserId(), "주문 " + order.getOrderNo(),
                paidBody, "ORDER_PAID", order.getId());
        // 사장님(관리자)에게도 새 주문 알림
        String fulfillLabel = switch (order.getFulfillmentType()) {
            case "DINE_IN" -> "매장";
            case "TAKEOUT" -> "포장";
            case "DELIVERY" -> "배달";
            default -> order.getFulfillmentType();
        };
        notificationService.notifyAdmins("새 주문 " + order.getOrderNo(),
                String.format("%s 주문이 들어왔어요. (%,d원)", fulfillLabel, order.getTotalPrice()),
                "NEW_ORDER", order.getId());
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
                .map(i -> new OrderItemView(i.getMenuId(), i.getMenuName(), i.getUnitPrice(), i.getQuantity(), i.getOptionsDesc()))
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

    /**
     * 관리자 대시보드 통계 (A5). 매출·주문건수는 "결제 완료(취소 제외)" 주문만 집계한다.
     * DB 종류(H2/MySQL)에 상관없이 동작하도록 자바에서 계산한다(데이터가 크지 않음).
     */
    @Transactional(readOnly = true)
    public DashboardStats adminStats() {
        List<OrderEntity> all = orderRepository.findAll();
        LocalDate today = LocalDate.now();
        LocalDate weekStart = today.minusDays(6); // 오늘 포함 최근 7일

        // 결제 완료(취소 제외) 주문 = 매출 집계 대상. 결제 시각(paidAt) 기준 날짜.
        List<OrderEntity> paid = all.stream()
                .filter(o -> o.getPaidAt() != null && !"취소".equals(o.getStatus()))
                .toList();

        long todaySales = 0;
        int todayOrders = 0;
        long weekSales = 0;
        int weekOrders = 0;
        long totalSales = 0;
        int totalOrders = paid.size();
        java.util.Map<LocalDate, long[]> byDay = new java.util.HashMap<>(); // [sales, orders]
        java.util.Map<String, long[]> byMenu = new java.util.LinkedHashMap<>(); // [qty, sales]

        for (OrderEntity o : paid) {
            int amount = o.getTotalPrice();
            totalSales += amount;
            LocalDate day = o.getPaidAt().toLocalDate();
            long[] d = byDay.computeIfAbsent(day, k -> new long[2]);
            d[0] += amount;
            d[1] += 1;
            if (day.equals(today)) {
                todaySales += amount;
                todayOrders++;
            }
            if (!day.isBefore(weekStart)) {
                weekSales += amount;
                weekOrders++;
            }
            for (OrderItemEntity item : o.getItems()) {
                long[] m = byMenu.computeIfAbsent(item.getMenuName(), k -> new long[2]);
                m[0] += item.getQuantity();
                m[1] += (long) item.getLineTotal();
            }
        }

        // 최근 7일 일별 시리즈(오래된→최신, 매출 없는 날은 0)
        List<DailyPoint> daily = new java.util.ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            long[] d = byDay.getOrDefault(day, new long[2]);
            daily.add(new DailyPoint(day.toString(), d[0], (int) d[1]));
        }

        // 상태별 건수(전체 주문 기준 — 사장님이 처리 대기 흐름을 본다)
        java.util.Map<String, Integer> statusMap = new java.util.LinkedHashMap<>();
        for (OrderEntity o : all) {
            statusMap.merge(o.getStatus(), 1, Integer::sum);
        }
        List<StatusCount> statusCounts = statusMap.entrySet().stream()
                .map(e -> new StatusCount(e.getKey(), e.getValue()))
                .toList();

        // 인기 메뉴 TOP 5 (판매 수량 기준)
        List<TopMenu> topMenus = byMenu.entrySet().stream()
                .map(e -> new TopMenu(e.getKey(), (int) e.getValue()[0], e.getValue()[1]))
                .sorted((a, b) -> Integer.compare(b.quantity(), a.quantity()))
                .limit(5)
                .toList();

        return new DashboardStats(todaySales, todayOrders, weekSales, weekOrders,
                totalSales, totalOrders, daily, statusCounts, topMenus);
    }

    @Transactional(readOnly = true)
    public OrderDetail orderDetail(Long userId, long orderId) {
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "주문을 찾을 수 없습니다."));
        if (!order.getUserId().equals(userId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "본인 주문만 볼 수 있어요.");
        }
        List<OrderItemView> items = order.getItems().stream()
                .map(i -> new OrderItemView(i.getMenuId(), i.getMenuName(), i.getUnitPrice(), i.getQuantity(), i.getOptionsDesc()))
                .toList();
        return new OrderDetail(order.getId(), order.getOrderNo(), order.getStatus(), order.getFulfillmentType(),
                order.getScheduledAt(), order.getDeliveryAddress(), order.getTotalPrice(),
                order.getDiscountPrice(), items);
    }

    private int sandwichCount(List<CartLineComputed> lines) {
        return lines.stream().filter(CartLineComputed::sandwich).mapToInt(CartLineComputed::quantity).sum();
    }

    private boolean isBuildingOk(String address) {
        return buildingPolicy.isAddressAllowed(address);
    }

    // 영업시간 (예약 가능 시간대). 10:00 ~ 20:00 (마지막 예약 19:xx).
    private static final int OPEN_HOUR = 10;
    private static final int CLOSE_HOUR = 20;

    /** 예약 시간 검증 (S9). null이면 지금 주문이라 통과. */
    private void validateReservation(LocalDateTime scheduledAt) {
        if (scheduledAt == null) {
            return;
        }
        if (!scheduledAt.isAfter(LocalDateTime.now())) {
            throw ApiException.badRequest("INVALID_RESERVATION", "예약 시간은 현재보다 이후여야 해요.");
        }
        int hour = scheduledAt.getHour();
        if (hour < OPEN_HOUR || hour >= CLOSE_HOUR) {
            throw ApiException.badRequest("INVALID_RESERVATION",
                    String.format("예약은 영업시간(%d시~%d시) 안에서만 가능해요.", OPEN_HOUR, CLOSE_HOUR));
        }
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
