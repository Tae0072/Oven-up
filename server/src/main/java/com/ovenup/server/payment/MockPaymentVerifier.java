package com.ovenup.server.payment;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 개발용 모의 결제 검증기 (app.payment.mock=true, 기본).
 * 실제 결제 대행사 없이 "결제가 성공했고 금액도 맞다"고 처리한다.
 * ⚠️ 실제 배포 전에는 app.payment.mock=false 로 바꿔 RealPaymentVerifier(PortOne)를 쓴다.
 */
@Component
@ConditionalOnProperty(name = "app.payment.mock", havingValue = "true", matchIfMissing = true)
public class MockPaymentVerifier implements PaymentVerifier {

    @Override
    public PaymentResult verify(String method, String paymentRef, int expectedAmount) {
        // 모의 결제: 서버가 계산한 금액 그대로 결제된 것으로 간주.
        return PaymentResult.ok(expectedAmount);
    }
}
