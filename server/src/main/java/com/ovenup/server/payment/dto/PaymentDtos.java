package com.ovenup.server.payment.dto;

/** 결제 요청/응답 DTO (05_API §5). */
public final class PaymentDtos {

    private PaymentDtos() {
    }

    /**
     * 결제 요청 (POST /api/orders/{id}/pay).
     * @param method     결제 수단 (CARD/KAKAOPAY/NAVERPAY/TOSSPAY/SAMSUNGPAY)
     * @param paymentRef 결제창이 돌려준 결제 식별자(PortOne paymentId). mock 결제에선 비어도 됨.
     */
    public record PayRequest(String method, String paymentRef) {
    }

    /** 결제 응답 */
    public record PaymentDone(long orderId, String orderNo, String status, String paymentMethod) {
    }
}
