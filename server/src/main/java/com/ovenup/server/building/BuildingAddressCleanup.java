package com.ovenup.server.building;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.user.UserAddressEntity;
import com.ovenup.server.user.UserAddressRepository;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

/**
 * 건물 전용 정책 도입 전에 등록된 "건물 밖 주소"를 서버 시작 시 정리한다.
 * - 주소 목록(user_addresses)에서 건물 밖 주소 삭제
 * - 회원의 현재 선택 주소(users.address)가 건물 밖이면 비움 (다음 주문 때 층/호수 재등록)
 * 새로 들어오는 주소는 UserService/AuthService가 이미 막고 있으므로, 이건 과거 데이터 1회성 정리다
 * (멱등이라 매 시작마다 돌아도 안전).
 */
@Component
public class BuildingAddressCleanup implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(BuildingAddressCleanup.class);

    private final UserAddressRepository addressRepository;
    private final UserRepository userRepository;
    private final BuildingPolicy buildingPolicy;

    public BuildingAddressCleanup(UserAddressRepository addressRepository,
                                  UserRepository userRepository,
                                  BuildingPolicy buildingPolicy) {
        this.addressRepository = addressRepository;
        this.userRepository = userRepository;
        this.buildingPolicy = buildingPolicy;
    }

    @Override
    @Transactional
    public void run(String... args) {
        int removed = 0;
        for (UserAddressEntity a : addressRepository.findAll()) {
            if (!buildingPolicy.isAddressAllowed(a.getAddress())) {
                addressRepository.delete(a);
                removed++;
            }
        }
        int cleared = 0;
        for (UserEntity u : userRepository.findAll()) {
            String addr = u.getAddress();
            if (addr != null && !addr.isBlank() && !buildingPolicy.isAddressAllowed(addr)) {
                u.setAddress("");
                userRepository.save(u);
                cleared++;
            }
        }
        if (removed > 0 || cleared > 0) {
            log.info("건물 밖 주소 정리: 주소목록 {}건 삭제, 회원 현재주소 {}건 초기화", removed, cleared);
        }
    }
}
