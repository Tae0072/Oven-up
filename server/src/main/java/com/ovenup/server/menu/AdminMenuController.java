package com.ovenup.server.menu;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.menu.dto.MenuUpsertRequest;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 관리자 메뉴 관리 API (05_API §11, 화면 A3). ADMIN 권한 필요.
 * - GET    /api/admin/menus            : 전체 메뉴(품절 포함)
 * - POST   /api/admin/menus            : 메뉴 등록
 * - PUT    /api/admin/menus/{id}       : 메뉴 수정
 * - PATCH  /api/admin/menus/{id}/soldout : 품절/판매중 토글
 * - DELETE /api/admin/menus/{id}       : 메뉴 삭제
 */
@RestController
public class AdminMenuController {

    private final MenuService menuService;
    private final UserRepository userRepository;

    public AdminMenuController(MenuService menuService, UserRepository userRepository) {
        this.menuService = menuService;
        this.userRepository = userRepository;
    }

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

    @GetMapping("/api/admin/menus")
    public ApiResponse<List<Menu>> list(HttpServletRequest request) {
        requireAdmin(request);
        return ApiResponse.ok(menuService.adminList());
    }

    @PostMapping("/api/admin/menus")
    public ResponseEntity<ApiResponse<Menu>> create(HttpServletRequest request,
                                                    @RequestBody MenuUpsertRequest body) {
        requireAdmin(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(menuService.create(body)));
    }

    @PutMapping("/api/admin/menus/{id}")
    public ApiResponse<Menu> update(HttpServletRequest request, @PathVariable long id,
                                    @RequestBody MenuUpsertRequest body) {
        requireAdmin(request);
        return ApiResponse.ok(menuService.update(id, body));
    }

    @PatchMapping("/api/admin/menus/{id}/soldout")
    public ApiResponse<Menu> setSoldOut(HttpServletRequest request, @PathVariable long id,
                                        @RequestBody Map<String, Boolean> body) {
        requireAdmin(request);
        boolean soldOut = Boolean.TRUE.equals(body.get("soldOut"));
        return ApiResponse.ok(menuService.setSoldOut(id, soldOut));
    }

    @DeleteMapping("/api/admin/menus/{id}")
    public ApiResponse<Map<String, Object>> delete(HttpServletRequest request, @PathVariable long id) {
        requireAdmin(request);
        menuService.delete(id);
        return ApiResponse.ok(Map.of("deleted", true));
    }
}
