package com.ovenup.server.user;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.user.dto.MyProfile;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 회원 정보 API (05_API §2.4)
 * - GET /api/users/me : 내 정보 (로그인 필요)
 */
@RestController
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/api/users/me")
    public ApiResponse<MyProfile> me(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        Long userId = (Long) attr;
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        return ApiResponse.ok(new MyProfile(
                user.getId(), user.getEmail(), user.getName(),
                user.getPhone(), user.getRole(), user.getPointBalance()));
    }
}
