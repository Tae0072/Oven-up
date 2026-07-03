package com.ovenup.server.cart;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.cart.dto.CartDtos.AddCartItemRequest;
import com.ovenup.server.cart.dto.CartDtos.CartView;
import com.ovenup.server.cart.dto.CartDtos.UpdateQuantityRequest;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 서버 장바구니 API (05_API §3.3~3.5). 모두 로그인 필요.
 * - GET    /api/cart                 : 내 장바구니
 * - POST   /api/cart/items           : 담기
 * - PATCH  /api/cart/items/{id}      : 수량 변경(0이면 삭제)
 * - DELETE /api/cart/items/{id}      : 항목 삭제
 * - DELETE /api/cart                 : 전체 비우기
 */
@RestController
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    @GetMapping("/api/cart")
    public ApiResponse<CartView> myCart(HttpServletRequest request) {
        return ApiResponse.ok(cartService.getCart(requireUserId(request)));
    }

    @PostMapping("/api/cart/items")
    public ResponseEntity<ApiResponse<Map<String, Object>>> add(HttpServletRequest request,
                                                                @RequestBody AddCartItemRequest body) {
        long cartItemId = cartService.addItem(requireUserId(request), body);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(Map.of("cartItemId", cartItemId)));
    }

    @PatchMapping("/api/cart/items/{id}")
    public ApiResponse<CartView> updateQuantity(HttpServletRequest request, @PathVariable long id,
                                                @RequestBody UpdateQuantityRequest body) {
        Long userId = requireUserId(request);
        cartService.updateQuantity(userId, id, body.quantity());
        return ApiResponse.ok(cartService.getCart(userId));
    }

    @DeleteMapping("/api/cart/items/{id}")
    public ApiResponse<CartView> removeItem(HttpServletRequest request, @PathVariable long id) {
        Long userId = requireUserId(request);
        cartService.removeItem(userId, id);
        return ApiResponse.ok(cartService.getCart(userId));
    }

    @DeleteMapping("/api/cart")
    public ApiResponse<CartView> clear(HttpServletRequest request) {
        Long userId = requireUserId(request);
        cartService.clear(userId);
        return ApiResponse.ok(cartService.getCart(userId));
    }
}
