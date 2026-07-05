package com.ovenup.server.inquiry;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.grouporder.GroupOrderService;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.AdminUpdateRequest;
import com.ovenup.server.grouporder.dto.GroupOrderDtos.GroupOrderView;
import com.ovenup.server.inquiry.dto.InquiryDtos.AdminInquiryItem;
import com.ovenup.server.inquiry.dto.InquiryDtos.ReplyRequest;
import com.ovenup.server.inquiry.dto.InquiryDtos.ReplyView;
import com.ovenup.server.user.UserEntity;
import com.ovenup.server.user.UserRepository;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 관리자(사장님) 고객지원 API — 고객의 소리 답변 + 단체주문 관리. ADMIN 권한 필요.
 * - GET   /api/admin/inquiries              : 전체 문의 목록(내용·답변 포함)
 * - POST  /api/admin/inquiries/{id}/reply   : 문의 답변(등록/수정) + 손님 알림
 * - GET   /api/admin/group-orders           : 전체 단체주문 문의
 * - PATCH /api/admin/group-orders/{id}      : 단체주문 상태·메모 갱신 + 손님 알림
 */
@RestController
public class AdminSupportController {

    private final UserRepository userRepository;
    private final InquiryService inquiryService;
    private final GroupOrderService groupOrderService;

    public AdminSupportController(UserRepository userRepository, InquiryService inquiryService,
                                 GroupOrderService groupOrderService) {
        this.userRepository = userRepository;
        this.inquiryService = inquiryService;
        this.groupOrderService = groupOrderService;
    }

    private void requireAdmin(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        UserEntity user = userRepository.findById((Long) attr)
                .orElseThrow(() -> ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다."));
        if (!"ADMIN".equals(user.getRole())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "관리자만 접근할 수 있어요.");
        }
    }

    @GetMapping("/api/admin/inquiries")
    public ApiResponse<List<AdminInquiryItem>> inquiries(HttpServletRequest request) {
        requireAdmin(request);
        return ApiResponse.ok(inquiryService.adminList());
    }

    @PostMapping("/api/admin/inquiries/{id}/reply")
    public ApiResponse<ReplyView> reply(HttpServletRequest request, @PathVariable long id,
                                        @RequestBody ReplyRequest body) {
        requireAdmin(request);
        return ApiResponse.ok(inquiryService.adminReply(id, body.content()));
    }

    @GetMapping("/api/admin/group-orders")
    public ApiResponse<List<GroupOrderView>> groupOrders(HttpServletRequest request) {
        requireAdmin(request);
        return ApiResponse.ok(groupOrderService.adminList());
    }

    @PatchMapping("/api/admin/group-orders/{id}")
    public ApiResponse<GroupOrderView> updateGroupOrder(HttpServletRequest request, @PathVariable long id,
                                                        @RequestBody AdminUpdateRequest body) {
        requireAdmin(request);
        return ApiResponse.ok(groupOrderService.adminUpdate(id, body));
    }
}
