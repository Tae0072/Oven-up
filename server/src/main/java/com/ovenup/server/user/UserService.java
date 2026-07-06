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
        boolean hasName = request.name() != null && !request.name().isBlank();
        boolean hasNickname = request.nickname() != null && !request.nickname().isBlank();
        boolean hasAddress = request.address() != null && !request.address().isBlank();
        boolean hasPhone = request.phone() != null;
        if (!hasName && !hasNickname && !hasAddress && !hasPhone) {
            throw ApiException.badRequest("INVALID_INPUT", "수정할 내용을 입력해 주세요.");
        }
        UserEntity user = requireUser(userId);
        // 이름/연락처 수정 (기존 프로필 수정 화면)
        if (hasName || hasPhone) {
            user.updateProfile(hasName ? request.name().trim() : null,
                    hasPhone ? request.phone().trim() : user.getPhone());
        }
        // 닉네임 설정 (소셜 온보딩 1단계)
        if (hasNickname) {
            user.setNickname(request.nickname().trim());
        }
        // 주소 설정 (소셜 온보딩 2단계 / 회원정보 수정)
        if (hasAddress) {
            user.setAddress(request.address().trim());
        }
        userRepository.save(user);
        return toProfile(user);
    }

    @Transactional
    public MyProfile setNotifyEnabled(Long userId, boolean enabled) {
        UserEntity user = requireUser(userId);
        user.setNotifyEnabled(enabled);
        userRepository.save(user);
        return toProfile(user);
    }

    /** 회원 탈퇴: 현재 비밀번호 확인 후 계정 삭제. */
    @Transactional
    public void deleteAccount(Long userId, String currentPassword) {
        UserEntity user = requireUser(userId);
        if (currentPassword == null || !passwordEncoder.matches(currentPassword, user.getPassword())) {
            throw ApiException.badRequest("PASSWORD_MISMATCH", "현재 비밀번호가 올바르지 않습니다.");
        }
        userRepository.delete(user);
    }

    private MyProfile toProfile(UserEntity user) {
        return new MyProfile(user.getId(), user.getEmail(), user.getLoginId(), user.getName(),
                user.getNickname(), user.getPhone(), user.getAddress(), user.getRole(),
                user.getPointBalance(), user.isNotifyEnabled());
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
