package com.ovenup.server.inquiry;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.inquiry.dto.InquiryDtos.CreateInquiryRequest;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquiryCreated;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquiryDetail;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquirySummary;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 고객의 소리 API (05_API §7). 모두 로그인 필요. 본인 글만 조회.
 * - POST /api/inquiries       : 문의 작성 → 201
 * - GET  /api/inquiries       : 내 문의 목록
 * - GET  /api/inquiries/{id}  : 내 문의 상세(사장님 답변 포함)
 */
@RestController
public class InquiryController {

    private final InquiryService inquiryService;

    public InquiryController(InquiryService inquiryService) {
        this.inquiryService = inquiryService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    @PostMapping("/api/inquiries")
    public ResponseEntity<ApiResponse<InquiryCreated>> create(HttpServletRequest request,
                                                              @RequestBody CreateInquiryRequest body) {
        InquiryCreated created = inquiryService.create(requireUserId(request), body);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created));
    }

    @GetMapping("/api/inquiries")
    public ApiResponse<List<InquirySummary>> myInquiries(HttpServletRequest request) {
        return ApiResponse.ok(inquiryService.myInquiries(requireUserId(request)));
    }

    @GetMapping("/api/inquiries/{id}")
    public ApiResponse<InquiryDetail> detail(HttpServletRequest request, @PathVariable long id) {
        return ApiResponse.ok(inquiryService.myInquiryDetail(requireUserId(request), id));
    }
}
