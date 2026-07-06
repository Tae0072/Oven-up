package com.ovenup.server.auth;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * 휴대폰 본인인증(PASS식) 결과 검증 — PortOne V2 본인인증 API.
 * 앱이 인증창을 마치고 보낸 identityVerificationId 로 PortOne 서버에 조회해
 * "인증 완료(VERIFIED)"인지 확인하고, 통신사가 확인해 준 이름·전화번호를 돌려준다.
 *
 * 준비물(환경변수): PORTONE_API_SECRET (결제 검증과 동일한 키 사용)
 */
@Component
public class IdentityVerifier {

    /** 검증 결과. verified=true면 name/phone 사용 가능. */
    public record Result(boolean verified, String name, String phone, String message) {
        static Result fail(String message) {
            return new Result(false, "", "", message);
        }
    }

    private final String apiSecret;
    private final RestClient client;

    public IdentityVerifier(@Value("${PORTONE_API_SECRET:}") String apiSecret) {
        this.apiSecret = apiSecret;
        this.client = RestClient.builder().baseUrl("https://api.portone.io").build();
    }

    @SuppressWarnings("unchecked")
    public Result verify(String identityVerificationId) {
        if (apiSecret == null || apiSecret.isBlank()) {
            return Result.fail("본인인증 설정(PORTONE_API_SECRET)이 없습니다.");
        }
        if (identityVerificationId == null || identityVerificationId.isBlank()) {
            return Result.fail("본인인증 정보가 없습니다.");
        }
        try {
            Map<String, Object> body = client.get()
                    .uri("/identity-verifications/{id}", identityVerificationId)
                    .header("Authorization", "PortOne " + apiSecret)
                    .retrieve()
                    .body(Map.class);
            if (body == null) {
                return Result.fail("본인인증 정보를 불러오지 못했습니다.");
            }
            String status = String.valueOf(body.get("status"));
            if (!"VERIFIED".equalsIgnoreCase(status)) {
                return Result.fail("본인인증이 완료되지 않았습니다(status=" + status + ").");
            }
            String name = "";
            String phone = "";
            if (body.get("verifiedCustomer") instanceof Map<?, ?> customer) {
                Object n = customer.get("name");
                Object p = customer.get("phoneNumber");
                name = n == null ? "" : String.valueOf(n);
                phone = p == null ? "" : String.valueOf(p);
            }
            return new Result(true, name, phone, null);
        } catch (Exception e) {
            return Result.fail("본인인증 확인 중 오류: " + e.getMessage());
        }
    }
}
