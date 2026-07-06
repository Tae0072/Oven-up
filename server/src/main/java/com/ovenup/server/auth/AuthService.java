package com.ovenup.server.auth;

import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.auth.dto.LoginRequest;
import com.ovenup.server.auth.dto.LoginResponse;
import com.ovenup.server.auth.dto.SignupRequest;
import com.ovenup.server.auth.dto.SocialLoginRequest;
import com.ovenup.server.auth.dto.SocialLoginResponse;
import com.ovenup.server.auth.dto.UserSummary;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.social.SocialAuthCodeExchanger;
import com.ovenup.server.social.SocialProfile;
import com.ovenup.server.social.SocialProfileVerifier;
import com.ovenup.server.user.SocialAccountEntity;
import com.ovenup.server.user.SocialAccountRepository;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

/**
 * 회원가입/로그인/소셜로그인 처리. (05_API §2.1~2.3, 03_기능_명세서 §1)
 */
@Service
public class AuthService {

    private static final int MIN_PASSWORD_LENGTH = 8;
    private static final Set<String> SOCIAL_PROVIDERS = Set.of("kakao", "naver");

    private final UserRepository userRepository;
    private final SocialAccountRepository socialAccountRepository;
    private final JwtProvider jwtProvider;
    private final SocialProfileVerifier socialVerifier;
    private final SocialAuthCodeExchanger socialCodeExchanger;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public AuthService(UserRepository userRepository, SocialAccountRepository socialAccountRepository,
                       JwtProvider jwtProvider, SocialProfileVerifier socialVerifier,
                       SocialAuthCodeExchanger socialCodeExchanger) {
        this.userRepository = userRepository;
        this.socialAccountRepository = socialAccountRepository;
        this.jwtProvider = jwtProvider;
        this.socialVerifier = socialVerifier;
        this.socialCodeExchanger = socialCodeExchanger;
    }

    @Transactional
    public long signup(SignupRequest request) {
        if (request.email() == null || request.email().isBlank()) {
            throw ApiException.badRequest("INVALID_INPUT", "이메일을 입력해 주세요.");
        }
        if (request.password() == null || request.password().length() < MIN_PASSWORD_LENGTH) {
            throw ApiException.badRequest("INVALID_INPUT", "비밀번호는 8자 이상이어야 합니다.");
        }
        // 아이디가 없으면 이메일을 아이디로 쓴다 (하위호환 — 필수 입력은 앱 회원가입 화면이 검증).
        String loginId = (request.loginId() == null || request.loginId().isBlank())
                ? request.email().trim()
                : request.loginId().trim();
        if (userRepository.existsByEmail(request.email())) {
            throw ApiException.conflict("EMAIL_DUPLICATED", "이미 사용 중인 이메일입니다.");
        }
        if (userRepository.existsByLoginId(loginId)) {
            throw ApiException.conflict("LOGIN_ID_DUPLICATED", "이미 사용 중인 아이디입니다.");
        }
        String hashed = passwordEncoder.encode(request.password());
        // 표시 이름: 이름이 없으면 아이디를 쓴다.
        String name = (request.name() == null || request.name().isBlank()) ? loginId : request.name().trim();
        String phone = request.phone() == null ? "" : request.phone().trim();
        UserEntity user = new UserEntity(request.email().trim(), hashed, name, phone);
        user.setSignupInfo(loginId, request.address() == null ? null : request.address().trim());
        UserEntity saved = userRepository.save(user);
        return saved.getId();
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        // 아이디 또는 이메일 어느 쪽으로도 로그인할 수 있다.
        String idOrEmail = request.email() == null ? "" : request.email().trim();
        UserEntity user = userRepository.findByLoginId(idOrEmail)
                .or(() -> userRepository.findByEmail(idOrEmail))
                .orElse(null);
        if (user == null || !passwordEncoder.matches(request.password(), user.getPassword())) {
            throw ApiException.unauthorized("LOGIN_FAILED", "아이디(이메일) 또는 비밀번호가 올바르지 않습니다.");
        }
        String token = jwtProvider.createToken(user.getId(), user.getRole());
        return new LoginResponse(token, new UserSummary(user.getId(), user.getName(), user.getRole()));
    }

    /**
     * 소셜 로그인 (05_API §2.3). provider = kakao | naver.
     * 앱이 준 소셜 토큰을 검증해 사용자 정보를 얻고, 우리 회원과 연결/자동가입한다.
     */
    @Transactional
    public SocialLoginResponse socialLogin(String provider, SocialLoginRequest request) {
        if (provider == null || !SOCIAL_PROVIDERS.contains(provider.toLowerCase())) {
            throw ApiException.badRequest("UNSUPPORTED_PROVIDER", "지원하지 않는 소셜 로그인입니다.");
        }
        // accessToken이 없고 인가 코드(code)가 오면(웹 리다이렉트 로그인), 먼저 코드를 토큰으로 교환한다.
        String accessToken = request.accessToken();
        if ((accessToken == null || accessToken.isBlank())
                && request.code() != null && !request.code().isBlank()) {
            accessToken = socialCodeExchanger.exchange(
                    provider.toLowerCase(), request.code(), request.redirectUri(), request.state());
        }
        SocialProfile profile = socialVerifier.verify(provider, accessToken);

        // 1) 이미 연결된 소셜 계정이면 그 회원으로 로그인
        Optional<SocialAccountEntity> linked =
                socialAccountRepository.findByProviderAndProviderUserId(profile.provider(), profile.providerUserId());
        if (linked.isPresent()) {
            UserEntity user = userRepository.findById(linked.get().getUserId())
                    .orElseThrow(() -> ApiException.unauthorized("USER_NOT_FOUND", "회원을 찾을 수 없습니다."));
            return response(user, false);
        }

        // 2) 같은 이메일의 자체 회원이 있으면 연결(선택)
        UserEntity user;
        boolean isNew;
        if (profile.email() != null && !profile.email().isBlank() && userRepository.existsByEmail(profile.email())) {
            user = userRepository.findByEmail(profile.email()).orElseThrow();
            isNew = false;
        } else {
            // 3) 없으면 새 회원 자동 생성
            String email = (profile.email() != null && !profile.email().isBlank())
                    ? profile.email()
                    : (profile.provider().toLowerCase() + "_" + profile.providerUserId() + "@social.local");
            String randomPassword = passwordEncoder.encode(UUID.randomUUID().toString());
            user = userRepository.save(new UserEntity(email, randomPassword, profile.name(), ""));
            isNew = true;
        }
        socialAccountRepository.save(
                new SocialAccountEntity(user.getId(), profile.provider(), profile.providerUserId()));
        return response(user, isNew);
    }

    private SocialLoginResponse response(UserEntity user, boolean isNew) {
        String token = jwtProvider.createToken(user.getId(), user.getRole());
        return new SocialLoginResponse(token, new UserSummary(user.getId(), user.getName(), user.getRole()),
                isNew, user.needsProfileSetup());
    }
}
