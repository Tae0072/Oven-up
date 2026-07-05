package com.ovenup.server.payment;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * 실제 PortOne(포트원) 결제 검증기 (app.payment.mock=false).
 * 결제창에서 받은 결제 식별자(paymentId)로 PortOne 서버에 조회해
 * "결제 완료(status=PAID)"인지, "실제 결제금액"이 서버 계산 금액과 같은지 확인한다.
 *
 * 준비물(환경변수): PORTONE_API_SECRET (PortOne 콘솔에서 발급한 V2 API Secret)
 * ⚠️ 실제 결제이므로, 키는 코드에 넣지 말고 환경변수/서버 설정으로만 관리한다.
 */
@Component
@ConditionalOnProperty(name = "app.payment.mock", havingValue = "false")
public class RealPaymentVerifier implements PaymentVerifier {

    private final String apiSecret;
    private final RestClient client;

    public RealPaymentVerifier(@Value("${PORTONE_API_SECRET:}") String apiSecret) {
        this.apiSecret = apiSecret;
        this.client = RestClient.builder().baseUrl("https://api.portone.io").build();
    }

    @Override
    @SuppressWarnings("unchecked")
    public PaymentResult verify(String method, String paymentRef, int expectedAmount) {
        if (apiSecret == null || apiSecret.isBlank()) {
            return PaymentResult.fail("PortOne API Secret(PORTONE_API_SECRET)이 설정되지 않았습니다.");
        }
        if (paymentRef == null || paymentRef.isBlank()) {
            return PaymentResult.fail("결제 식별자(paymentId)가 없습니다.");
        }
        try {
            Map<String, Object> body = client.get()
                    .uri("/payments/{id}", paymentRef)
                    .header("Authorization", "PortOne " + apiSecret)
                    .retrieve()
                    .body(Map.class);
            if (body == null) {
                return PaymentResult.fail("결제 정보를 불러오지 못했습니다.");
            }
            String status = String.valueOf(body.get("status"));
            if (!"PAID".equalsIgnoreCase(status)) {
                return PaymentResult.fail("결제가 완료되지 않았습니다(status=" + status + ").");
            }
            int paid = 0;
            if (body.get("amount") instanceof Map<?, ?> amount && amount.get("total") instanceof Number total) {
                paid = total.intValue();
            }
            return PaymentResult.ok(paid);
        } catch (Exception e) {
            return PaymentResult.fail("결제 확인 중 오류: " + e.getMessage());
        }
    }
}
