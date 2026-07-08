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
    private final UserAddressRepository addressRepository;
    private final com.ovenup.server.building.BuildingPolicy buildingPolicy;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public UserService(UserRepository userRepository, UserAddressRepository addressRepository,
                       com.ovenup.server.building.BuildingPolicy buildingPolicy) {
        this.userRepository = userRepository;
        this.addressRepository = addressRepository;
        this.buildingPolicy = buildingPolicy;
    }

    /** 건물 전용 앱: 건물 밖 주소는 등록·수정 모두 거절한다. */
    private void requireBuildingAddress(String address) {
        if (!buildingPolicy.isAddressAllowed(address)) {
            throw ApiException.badRequest("ADDRESS_NOT_ALLOWED",
                    "이 앱은 " + buildingPolicy.name() + " 전용이에요. 건물 내 주소(층/호수)만 등록할 수 있어요.");
        }
    }

    /** 주소 목록 한 건 응답 */
    public record AddressView(long id, String address, boolean selected) {
    }

    /** 주소 목록. 목록이 비어 있는데 회원 주소가 있으면(과거 가입자) 목록으로 옮겨준다. */
    @Transactional
    public java.util.List<AddressView> listAddresses(Long userId) {
        UserEntity user = requireUser(userId);
        java.util.List<UserAddressEntity> list = addressRepository.findByUserIdOrderByIdDesc(userId);
        if (list.isEmpty() && user.getAddress() != null && !user.getAddress().isBlank()) {
            addressRepository.save(new UserAddressEntity(userId, user.getAddress().trim()));
            list = addressRepository.findByUserIdOrderByIdDesc(userId);
        }
        String current = user.getAddress() == null ? "" : user.getAddress();
        return list.stream()
                .map(a -> new AddressView(a.getId(), a.getAddress(), a.getAddress().equals(current)))
                .toList();
    }

    /** 주소 추가(+바로 선택). 같은 주소가 이미 있으면 선택만 바꾼다. */
    @Transactional
    public java.util.List<AddressView> addAddress(Long userId, String address) {
        if (address == null || address.isBlank()) {
            throw ApiException.badRequest("INVALID_INPUT", "주소를 입력해 주세요.");
        }
        requireBuildingAddress(address);
        UserEntity user = requireUser(userId);
        String trimmed = address.trim();
        if (!addressRepository.existsByUserIdAndAddress(userId, trimmed)) {
            addressRepository.save(new UserAddressEntity(userId, trimmed));
        }
        user.setAddress(trimmed);
        userRepository.save(user);
        return listAddresses(userId);
    }

    /** 목록에서 주소 선택 → 현재 주소로 설정 */
    @Transactional
    public java.util.List<AddressView> selectAddress(Long userId, long addressId) {
        UserEntity user = requireUser(userId);
        UserAddressEntity target = addressRepository.findById(addressId)
                .filter(a -> a.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("ADDRESS_NOT_FOUND", "주소를 찾을 수 없어요."));
        requireBuildingAddress(target.getAddress()); // 과거에 남은 건물 밖 주소는 선택도 불가
        user.setAddress(target.getAddress());
        userRepository.save(user);
        return listAddresses(userId);
    }

    /** 주소 삭제. 현재 선택된 주소를 지우면 남은 주소 중 최신 것을 선택(없으면 빈 값). */
    @Transactional
    public java.util.List<AddressView> deleteAddress(Long userId, long addressId) {
        UserEntity user = requireUser(userId);
        UserAddressEntity target = addressRepository.findById(addressId)
                .filter(a -> a.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("ADDRESS_NOT_FOUND", "주소를 찾을 수 없어요."));
        boolean wasSelected = target.getAddress().equals(user.getAddress());
        addressRepository.delete(target);
        if (wasSelected) {
            java.util.List<UserAddressEntity> rest = addressRepository.findByUserIdOrderByIdDesc(userId);
            user.setAddress(rest.isEmpty() ? "" : rest.get(0).getAddress());
            userRepository.save(user);
        }
        return listAddresses(userId);
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
        // 주소 설정 (소셜 온보딩 2단계 / 회원정보 수정) — 건물 내 주소만 허용
        if (hasAddress) {
            requireBuildingAddress(request.address());
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
