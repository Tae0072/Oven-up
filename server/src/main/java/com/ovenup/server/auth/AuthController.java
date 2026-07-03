package com.ovenup.server.auth;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.dto.LoginRequest;
import com.ovenup.server.auth.dto.LoginResponse;
import com.ovenup.server.auth.dto.SignupRequest;
import com.ovenup.server.common.ApiResponse;

/**
 * 인증 API (05_API §2)
 * - POST /api/auth/signup : 회원가입
 * - POST /api/auth/login  : 로그인(토큰 발급)
 */
@RestController
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/api/auth/signup")
    public ResponseEntity<ApiResponse<Map<String, Object>>> signup(@RequestBody SignupRequest request) {
        long userId = authService.signup(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(Map.of("userId", userId)));
    }

    @PostMapping("/api/auth/login")
    public ApiResponse<LoginResponse> login(@RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }
}
