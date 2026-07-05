package com.ovenup.server.payment;

/**
 * 결제 검증 결과.
 * @param success     결제가 실제로 완료됐는지
 * @param paidAmount  실제 결제된 금액(원). 서버 계산 금액과 비교해 조작을 막는다.
 * @param message     실패 사유 등 부가 메시지(성공 시 null 가능)
 */
public record PaymentResult(boolean success, int paidAmount, String message) {

    public static PaymentResult ok(int paidAmount) {
        return new PaymentResult(true, paidAmount, null);
    }

    public static PaymentResult fail(String message) {
        return new PaymentResult(false, 0, message);
    }
}
