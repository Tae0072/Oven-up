package com.ovenup.server.user;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.user.dto.ChangePasswordRequest;
import com.ovenup.server.user.dto.MyProfile;
import com.ovenup.server.user.dto.UpdateProfileRequest;

/**
 * 회원 정보 수정 처리. (05_API §2.5)
 * - 프로필(이름·연락처) 수정
 * - 비밀번호 변경(현재 비밀번호 확인 후 교체)
 */
@Service
public class UserService {

    private static final int MIN_PASSWORD_LENGTH = 8;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    private UserEntity requireUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
    }

    @Transactional
    public MyProfile updateProfile(Long userId, UpdateProfileRequest request) {
        if (request.name() == null || request.name().isBlank()) {
            throw ApiException.badRequest("INVALID_INPUT", "이름을 입력해 주세요.");
        }
        UserEntity user = requireUser(userId);
        user.updateProfile(request.name().trim(), request.phone() == null ? "" : request.phone().trim());
        userRepository.save(user);
        return new MyProfile(user.getId(), user.getEmail(), user.getName(),
                user.getPhone(), user.getRole(), user.getPointBalance());
    }

    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        UserEntity user = requireUser(userId);
        if (request.currentPassword() == null
                || !passwordEncoder.matches(request.currentPassword(), user.getPassword())) {
            throw ApiException.badRequest("PASSWORD_MISMATCH", "현재 비밀번호가 올바르지 않습니다.");
        }
        if (request.newPassword() == null || request.newPassword().length() < MIN_PASSWORD_LENGTH) {
            throw ApiException.badRequest("INVALID_INPUT", "새 비밀번호는 8자 이상이어야 합니다.");
        }
        user.changePassword(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }
}
