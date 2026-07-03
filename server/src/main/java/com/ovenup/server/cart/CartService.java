package com.ovenup.server.cart;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.cart.dto.CartDtos.AddCartItemRequest;
import com.ovenup.server.cart.dto.CartDtos.CartLineView;
import com.ovenup.server.cart.dto.CartDtos.CartView;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.menu.MenuEntity;
import com.ovenup.server.menu.MenuJpaRepository;
import com.ovenup.server.menu.MenuOptionEntity;

/**
 * 서버 장바구니(회원별) 처리. 05_API §3.3~3.5.
 * 금액은 저장하지 않고, 조회할 때마다 메뉴 DB로 다시 계산한다(조작 방지).
 */
@Service
@Transactional
public class CartService {

    private static final String SANDWICH = "샌드위치";

    private final CartItemRepository cartItemRepository;
    private final MenuJpaRepository menuRepository;

    public CartService(CartItemRepository cartItemRepository, MenuJpaRepository menuRepository) {
        this.cartItemRepository = cartItemRepository;
        this.menuRepository = menuRepository;
    }

    /** 장바구니 각 줄을 메뉴/옵션 가격까지 계산해 반환. (주문 생성에서도 사용) */
    @Transactional(readOnly = true)
    public List<CartLineComputed> computeLines(Long userId) {
        List<CartLineComputed> lines = new ArrayList<>();
        for (CartItemEntity item : cartItemRepository.findByUserIdOrderByIdAsc(userId)) {
            MenuEntity menu = menuRepository.findById(item.getMenuId()).orElse(null);
            if (menu == null) {
                continue; // 삭제된 메뉴는 건너뜀
            }
            List<Long> optionIds = parseOptionIds(item.getOptionIds());
            List<MenuOptionEntity> chosen = menu.getOptions().stream()
                    .filter(o -> optionIds.contains(o.getId()))
                    .toList();
            int optionSum = chosen.stream().mapToInt(MenuOptionEntity::getExtraPrice).sum();
            int unitPrice = menu.getPrice() + optionSum;
            String optionsDesc = chosen.stream().map(MenuOptionEntity::getName).collect(Collectors.joining(", "));
            lines.add(new CartLineComputed(item.getId(), menu.getId(), menu.getName(), unitPrice,
                    item.getQuantity(), optionIds, optionsDesc, SANDWICH.equals(menu.getCategory())));
        }
        return lines;
    }

    @Transactional(readOnly = true)
    public CartView getCart(Long userId) {
        List<CartLineComputed> lines = computeLines(userId);
        List<CartLineView> items = lines.stream()
                .map(l -> new CartLineView(l.cartItemId(), l.menuId(), l.menuName(),
                        l.quantity(), l.optionIds(), l.optionsDesc(), l.lineprice()))
                .toList();
        int total = lines.stream().mapToInt(CartLineComputed::lineprice).sum();
        return new CartView(items, total);
    }

    public long addItem(Long userId, AddCartItemRequest request) {
        if (request.menuId() == null) {
            throw ApiException.badRequest("INVALID_INPUT", "메뉴가 지정되지 않았습니다.");
        }
        if (!menuRepository.existsById(request.menuId())) {
            throw ApiException.badRequest("MENU_NOT_FOUND", "없는 메뉴입니다.");
        }
        int quantity = request.quantity() <= 0 ? 1 : request.quantity();
        String optionIds = (request.optionIds() == null) ? ""
                : request.optionIds().stream().map(String::valueOf).collect(Collectors.joining(","));
        CartItemEntity saved = cartItemRepository.save(
                new CartItemEntity(userId, request.menuId(), quantity, optionIds));
        return saved.getId();
    }

    public void updateQuantity(Long userId, long cartItemId, int quantity) {
        CartItemEntity item = cartItemRepository.findByIdAndUserId(cartItemId, userId)
                .orElseThrow(() -> ApiException.notFound("CART_ITEM_NOT_FOUND", "장바구니 항목을 찾을 수 없습니다."));
        if (quantity <= 0) {
            cartItemRepository.delete(item);
        } else {
            item.setQuantity(quantity);
            cartItemRepository.save(item);
        }
    }

    public void removeItem(Long userId, long cartItemId) {
        CartItemEntity item = cartItemRepository.findByIdAndUserId(cartItemId, userId)
                .orElseThrow(() -> ApiException.notFound("CART_ITEM_NOT_FOUND", "장바구니 항목을 찾을 수 없습니다."));
        cartItemRepository.delete(item);
    }

    public void clear(Long userId) {
        cartItemRepository.deleteByUserId(userId);
    }

    private List<Long> parseOptionIds(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        List<Long> ids = new ArrayList<>();
        for (String part : value.split(",")) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                try {
                    ids.add(Long.valueOf(trimmed));
                } catch (NumberFormatException ignored) {
                    // 잘못된 옵션 id는 무시
                }
            }
        }
        return ids;
    }
}
