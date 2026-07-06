package com.ovenup.server.user;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * 회원 DB 테이블. 04_데이터구조_ERD user.
 * ('user'는 일부 DB 예약어라 테이블명은 'users' 사용 — orders 와 같은 이유)
 */
@Entity
@Table(name = "users")
public class UserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    /** 로그인 아이디 (자체 회원가입용). 소셜 전용 회원은 null일 수 있다. */
    @Column(unique = true)
    private String loginId;

    /** BCrypt로 해시된 비밀번호 (평문 저장 금지) */
    private String password;

    private String name;

    /** 앱에서 표시할 닉네임. 소셜 첫 로그인 온보딩에서 설정한다. */
    private String nickname;

    private String phone;

    /** 기본 배달 주소 */
    private String address;

    /** 권한: USER(손님) / ADMIN(사장님) */
    private String role;

    private int pointBalance;

    /** 알림 끄기 여부. false=알림 켜짐(기본). (기존 행은 false로 들어와 자동으로 '켜짐') */
    private boolean notifyDisabled;

    private LocalDateTime createdAt;

    protected UserEntity() {
    }

    public UserEntity(String email, String password, String name, String phone) {
        this.email = email;
        this.password = password;
        this.name = name;
        this.phone = phone;
        this.role = "USER";
        this.pointBalance = 0;
        this.createdAt = LocalDateTime.now();
    }

    /** 권한 지정 (예: 관리자 계정 시드에서 ADMIN 부여) */
    public void assignRole(String role) {
        this.role = role;
    }

    /** 자체 회원가입 추가 정보(아이디·주소) 설정 */
    public void setSignupInfo(String loginId, String address) {
        this.loginId = loginId;
        this.address = address;
    }

    /** 프로필(이름·연락처) 수정 */
    public void updateProfile(String name, String phone) {
        if (name != null && !name.isBlank()) {
            this.name = name;
        }
        this.phone = phone;
    }

    /** 닉네임 설정 (소셜 온보딩). 표시 이름도 닉네임으로 맞춘다. */
    public void setNickname(String nickname) {
        this.nickname = nickname;
        this.name = nickname;
    }

    /** 주소 설정 */
    public void setAddress(String address) {
        this.address = address;
    }

    /** 소셜 첫 로그인 온보딩(닉네임→주소)이 아직 필요한가? */
    public boolean needsProfileSetup() {
        return nickname == null || nickname.isBlank()
                || address == null || address.isBlank();
    }

    /** 비밀번호 변경 (해시된 값을 넣어야 함) */
    public void changePassword(String hashedPassword) {
        this.password = hashedPassword;
    }

    /** 알림 켜기/끄기 */
    public void setNotifyEnabled(boolean enabled) {
        this.notifyDisabled = !enabled;
    }

    /** 알림 켜짐 여부 (기본 켜짐) */
    public boolean isNotifyEnabled() {
        return !notifyDisabled;
    }

    /** 적립금 지급 */
    public void addPoints(int amount) {
        if (amount > 0) {
            this.pointBalance += amount;
        }
    }

    /** 적립금 사용(차감). 잔액보다 많이 쓰지 않도록 호출 전에 검증한다. */
    public void usePoints(int amount) {
        if (amount > 0) {
            this.pointBalance -= amount;
            if (this.pointBalance < 0) {
                this.pointBalance = 0;
            }
        }
    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getPassword() {
        return password;
    }

    public String getName() {
        return name;
    }

    public String getPhone() {
        return phone;
    }

    public String getLoginId() {
        return loginId;
    }

    public String getNickname() {
        return nickname;
    }

    public String getAddress() {
        return address;
    }

    public String getRole() {
        return role;
    }

    public int getPointBalance() {
        return pointBalance;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
