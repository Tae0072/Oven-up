package com.ovenup.server.config;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.coupon.CouponEntity;
import com.ovenup.server.coupon.CouponRepository;
import com.ovenup.server.grouporder.GroupOrderEntity;
import com.ovenup.server.grouporder.GroupOrderRepository;
import com.ovenup.server.inquiry.InquiryEntity;
import com.ovenup.server.inquiry.InquiryReplyEntity;
import com.ovenup.server.inquiry.InquiryReplyRepository;
import com.ovenup.server.inquiry.InquiryRepository;
import com.ovenup.server.menu.MenuEntity;
import com.ovenup.server.menu.MenuJpaRepository;
import com.ovenup.server.order.OrderEntity;
import com.ovenup.server.order.OrderItemEntity;
import com.ovenup.server.order.OrderRepository;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

/**
 * 손님이 바로 확인할 수 있게 넣는 "목업(데모) 데이터".
 * - 데모 손님 계정 / 관리자 계정
 * - 데모 손님의 샘플 주문 2건
 * - 데모 손님의 단체주문 문의 1건, 고객의 소리 2건(1건은 사장님 답변 포함)
 *
 * demo@oven.com 이 없을 때만 1회 넣는다(기존 DB에도 안전하게 적용).
 * @Order(2): 메뉴 시더(DataInitializer, @Order(1)) 다음에 실행되어 메뉴가 준비된 뒤 주문을 만든다.
 *
 * ⚠️ 데모 비밀번호는 로컬 확인용입니다. 실제 배포 전에는 삭제/변경하세요.
 */
@Component
@Order(2)
public class DemoDataInitializer implements CommandLineRunner {

    private static final String DEMO_EMAIL = "demo@oven.com";
    private static final DateTimeFormatter ORDER_NO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final MenuJpaRepository menuRepository;
    private final GroupOrderRepository groupOrderRepository;
    private final InquiryRepository inquiryRepository;
    private final InquiryReplyRepository inquiryReplyRepository;
    private final CouponRepository couponRepository;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public DemoDataInitializer(UserRepository userRepository, OrderRepository orderRepository,
                               MenuJpaRepository menuRepository, GroupOrderRepository groupOrderRepository,
                               InquiryRepository inquiryRepository, InquiryReplyRepository inquiryReplyRepository,
                               CouponRepository couponRepository) {
        this.userRepository = userRepository;
        this.orderRepository = orderRepository;
        this.menuRepository = menuRepository;
        this.groupOrderRepository = groupOrderRepository;
        this.inquiryRepository = inquiryRepository;
        this.inquiryReplyRepository = inquiryReplyRepository;
        this.couponRepository = couponRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        // 데모 쿠폰 1종(쿠폰이 하나도 없을 때만): WELCOME3000 = 3,000원 할인, 1만원 이상
        if (couponRepository.count() == 0) {
            couponRepository.save(new CouponEntity("WELCOME3000", "웰컴 3천원 할인", "AMOUNT", 3000, 10000, null));
        }

        if (userRepository.existsByEmail(DEMO_EMAIL)) {
            return; // 이미 데모 데이터가 있으면 넣지 않음
        }

        // 1) 데모 손님 + 관리자 계정
        UserEntity demo = userRepository.save(
                newUser(DEMO_EMAIL, "demo1234", "데모손님", "010-1111-1111", "USER"));
        userRepository.save(
                newUser("admin@oven.com", "admin1234", "사장님", "010-9999-9999", "ADMIN"));

        // 2) 데모 손님의 샘플 주문 2건 (메뉴가 있을 때만)
        List<MenuEntity> menus = menuRepository.findAllByOrderByIdAsc();
        if (menus.size() >= 2) {
            // 포장 주문: LA갈비 1 + 잠봉 1
            List<OrderItemEntity> takeoutItems = new ArrayList<>();
            takeoutItems.add(item(menus.get(0), 1));
            takeoutItems.add(item(menus.get(1), 1));
            seedOrder(demo, "TAKEOUT", null, "준비중", takeoutItems);

            // 배달 주문(명지에코펠리스): LA갈비 2
            List<OrderItemEntity> deliveryItems = new ArrayList<>();
            deliveryItems.add(item(menus.get(0), 2));
            seedOrder(demo, "DELIVERY", "명지에코펠리스 305호", "배달중", deliveryItems);
        }

        // 3) 단체주문 문의 1건 (사장님이 협의중으로 확인한 상태)
        GroupOrderEntity group = new GroupOrderEntity(demo.getId(),
                LocalDateTime.now().plusDays(3).withHour(12).withMinute(0).withSecond(0).withNano(0),
                20, "회사 워크샵 점심용으로 샌드위치 20개 준비 가능할까요?", "010-1111-1111");
        groupOrderRepository.save(group);

        // 4) 고객의 소리 2건 — 하나는 답변완료, 하나는 접수 상태
        InquiryEntity answered = inquiryRepository.save(new InquiryEntity(demo.getId(),
                "배달 시간 문의", "명지에코펠리스로 배달 오는 데 보통 얼마나 걸리나요?", null));
        answered.markAnswered();
        inquiryRepository.save(answered);
        inquiryReplyRepository.save(new InquiryReplyEntity(answered.getId(),
                "안녕하세요! 명지에코펠리스 건물 내 배달은 보통 15~20분 정도 걸립니다. 감사합니다."));

        inquiryRepository.save(new InquiryEntity(demo.getId(),
                "메뉴 추천 부탁드려요", "매운맛을 좋아하는데 추천 메뉴가 있을까요?", null));
    }

    private UserEntity newUser(String email, String rawPassword, String name, String phone, String role) {
        UserEntity user = new UserEntity(email, passwordEncoder.encode(rawPassword), name, phone);
        user.assignRole(role);
        return user;
    }

    private OrderItemEntity item(MenuEntity menu, int quantity) {
        return new OrderItemEntity(menu.getId(), menu.getName(), menu.getPrice(), quantity, "");
    }

    private void seedOrder(UserEntity demo, String fulfillmentType, String deliveryAddress,
                           String status, List<OrderItemEntity> items) {
        int total = items.stream().mapToInt(OrderItemEntity::getLineTotal).sum();
        OrderEntity order = new OrderEntity(demo.getId(), total, 0, fulfillmentType,
                null, deliveryAddress, 0, null, status, items);
        order = orderRepository.save(order);
        order.assignOrderNo(order.getCreatedAt().format(ORDER_NO_DATE)
                + "-" + String.format("%04d", order.getId()));
        orderRepository.save(order);
    }
}
