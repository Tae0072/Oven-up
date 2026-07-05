package com.ovenup.server.payment;

/**
 * 결제 검증기 (05_API §5, 03_기능 §5).
 * 결제 대행사(PortOne 등)에 "이 결제가 실제로 완료됐고 금액이 맞는지" 확인하는 역할.
 *
 * 구현이 두 가지다:
 * - {@link MockPaymentVerifier} : 개발용(app.payment.mock=true, 기본). 실제 결제 없이 성공 처리.
 * - {@link RealPaymentVerifier} : 실제 PortOne 연동(app.payment.mock=false).
 */
public interface PaymentVerifier {

    /**
     * @param method         결제 수단 (CARD/KAKAOPAY/NAVERPAY/TOSSPAY/SAMSUNGPAY)
     * @param paymentRef      결제창이 돌려준 결제 식별자(PortOne paymentId 등). mock에선 비어도 됨.
     * @param expectedAmount  서버가 계산한 결제 금액(원). 실제 결제금액과 비교용.
     * @return 검증 결과(성공 여부 + 실제 결제금액)
     */
    PaymentResult verify(String method, String paymentRef, int expectedAmount);
}
