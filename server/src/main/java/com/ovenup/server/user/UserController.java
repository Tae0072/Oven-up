package com.ovenup.server.user;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.user.dto.ChangePasswordRequest;
import com.ovenup.server.user.dto.DeleteAccountRequest;
import com.ovenup.server.user.dto.MyProfile;
import com.ovenup.server.user.dto.NotifySettingRequest;
import com.ovenup.server.user.dto.UpdateProfileRequest;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 회원 정보 API (05_API §2.4~2.5)
 * - GET   /api/users/me          : 내 정보 (로그인 필요)
 * - PATCH /api/users/me          : 프로필(이름·연락처) 수정
 * - PATCH /api/users/me/password : 비밀번호 변경
 */
@RestController
public class UserController {

    private final UserRepository userRepository;
    private final UserService userService;

    public UserController(UserRepository userRepository, UserService userService) {
        this.userRepository = userRepository;
        this.userService = userService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    @GetMapping("/api/users/me")
    public ApiResponse<MyProfile> me(HttpServletRequest request) {
        Long userId = requireUserId(request);
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        return ApiResponse.ok(new MyProfile(
                user.getId(), user.getEmail(), user.getLoginId(), user.getName(), user.getNickname(),
                user.getPhone(), user.getAddress(), user.getRole(),
                user.getPointBalance(), user.isNotifyEnabled()));
    }

    @PatchMapping("/api/users/me")
    public ApiResponse<MyProfile> updateProfile(HttpServletRequest request,
                                                @RequestBody UpdateProfileRequest body) {
        Long userId = requireUserId(request);
        return ApiResponse.ok(userService.updateProfile(userId, body));
    }

    // ── 주소 목록 (배민식 주소 관리) ──

    @org.springframework.web.bind.annotation.GetMapping("/api/users/me/addresses")
    public ApiResponse<java.util.List<UserService.AddressView>> listAddresses(HttpServletRequest request) {
        return ApiResponse.ok(userService.listAddresses(requireUserId(request)));
    }

    @org.springframework.web.bind.annotation.PostMapping("/api/users/me/addresses")
    public ApiResponse<java.util.List<UserService.AddressView>> addAddress(
            HttpServletRequest request, @RequestBody java.util.Map<String, String> body) {
        return ApiResponse.ok(userService.addAddress(requireUserId(request), body.get("address")));
    }

    @PatchMapping("/api/users/me/addresses/{addressId}/select")
    public ApiResponse<java.util.List<UserService.AddressView>> selectAddress(
            HttpServletRequest request, @org.springframework.web.bind.annotation.PathVariable long addressId) {
        return ApiResponse.ok(userService.selectAddress(requireUserId(request), addressId));
    }

    @org.springframework.web.bind.annotation.DeleteMapping("/api/users/me/addresses/{addressId}")
    public ApiResponse<java.util.List<UserService.AddressView>> deleteAddress(
            HttpServletRequest request, @org.springframework.web.bind.annotation.PathVariable long addressId) {
        return ApiResponse.ok(userService.deleteAddress(requireUserId(request), addressId));
    }

    @PatchMapping("/api/users/me/password")
    public ApiResponse<Void> changePassword(HttpServletRequest request,
                                            @RequestBody ChangePasswordRequest body) {
        Long userId = requireUserId(request);
        userService.changePassword(userId, body);
        return ApiResponse.ok(null);
    }

    @PatchMapping("/api/users/me/notify")
    public ApiResponse<MyProfile> setNotify(HttpServletRequest request,
                                            @RequestBody NotifySettingRequest body) {
        Long userId = requireUserId(request);
        return ApiResponse.ok(userService.setNotifyEnabled(userId, body.enabled()));
    }

    @DeleteMapping("/api/users/me")
    public ApiResponse<Void> deleteAccount(HttpServletRequest request,
                                           @RequestBody DeleteAccountRequest body) {
        Long userId = requireUserId(request);
        userService.deleteAccount(userId, body.currentPassword());
        return ApiResponse.ok(null);
    }
}
