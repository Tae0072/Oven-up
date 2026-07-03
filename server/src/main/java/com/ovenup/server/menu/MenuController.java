package com.ovenup.server.menu;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.common.ApiResponse;

/**
 * 메뉴 조회 API.
 * - GET /api/menus?category={분류}  : 메뉴 목록 (category 생략 시 전체)
 * - GET /api/menus/{id}             : 메뉴 상세
 * 참고: 05_API_명세서 §3.1~3.2
 */
@RestController
public class MenuController {

    private final MenuService menuService;

    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    @GetMapping("/api/menus")
    public ApiResponse<List<Menu>> list(@RequestParam(required = false) String category) {
        return ApiResponse.ok(menuService.findAll(category));
    }

    @GetMapping("/api/menus/{id}")
    public ResponseEntity<ApiResponse<Menu>> detail(@PathVariable long id) {
        return menuService.findById(id)
                .map(menu -> ResponseEntity.ok(ApiResponse.ok(menu)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(ApiResponse.fail("NOT_FOUND", "메뉴를 찾을 수 없습니다.")));
    }
}
