package com.ovenup.server.common;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * 모든 API가 공통으로 쓰는 응답 형태.
 * 성공: { "success": true, "data": ... }
 * 실패: { "success": false, "error": { "code": ..., "message": ... } }
 * 참고: 05_API_명세서 §1 공통 응답 형태.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(boolean success, T data, ApiError error) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }

    public static <T> ApiResponse<T> fail(String code, String message) {
        return new ApiResponse<>(false, null, new ApiError(code, message));
    }

    public record ApiError(String code, String message) {
    }
}
