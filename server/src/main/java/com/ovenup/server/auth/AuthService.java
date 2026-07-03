package com.ovenup.server.auth;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.auth.dto.LoginRequest;
import com.ovenup.server.auth.dto.LoginResponse;
import com.ovenup.server.auth.dto.SignupRequest;
import com.ovenup.server.auth.dto.UserSummary;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

/**
 * 회원가입/로그인 처리. (05_API §2.1~2.2, 03_기능_명세서 §1)
 * - 비밀번호는 BCrypt로 해시해 저장(평문 저장 금지).
 * - 로그인 성공 시 JWT 토큰 발급.
 */
@Service
public class AuthService {

    private static final int MIN_PASSWORD_LENGTH = 8;

    private final UserRepository userRepository;
    private final JwtProvider jwtProvider;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public AuthService(UserRepository userRepository, JwtProvider jwtProvider) {
        this.userRepository = userRepository;
        this.jwtProvider = jwtProvider;
    }

    @Transactional
    public long signup(SignupRequest request) {
        if (request.email() == null || request.email().isBlank()) {
            throw ApiException.badRequest("INVALID_INPUT", "이메일을 입력해 주세요.");
        }
        if (request.password() == null || request.password().length() < MIN_PASSWORD_LENGTH) {
            throw ApiException.badRequest("INVALID_INPUT", "비밀번호는 8자 이상이어야 합니다.");
        }
        if (userRepository.existsByEmail(request.email())) {
            throw ApiException.conflict("EMAIL_DUPLICATED", "이미 사용 중인 이메일입니다.");
        }
        String hashed = passwordEncoder.encode(request.password());
        UserEntity saved = userRepository.save(
                new UserEntity(request.email(), hashed, request.name(), request.phone()));
        return saved.getId();
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        UserEntity user = userRepository.findByEmail(
                request.email() == null ? "" : request.email()).orElse(null);
        if (user == null || !passwordEncoder.matches(request.password(), user.getPassword())) {
            throw ApiException.unauthorized("LOGIN_FAILED", "이메일 또는 비밀번호가 올바르지 않습니다.");
        }
        String token = jwtProvider.createToken(user.getId(), user.getRole());
        return new LoginResponse(token, new UserSummary(user.getId(), user.getName(), user.getRole()));
    }
}
