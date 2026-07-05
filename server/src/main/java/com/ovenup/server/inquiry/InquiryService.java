package com.ovenup.server.inquiry;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.inquiry.dto.InquiryDtos.AdminInquiryItem;
import com.ovenup.server.inquiry.dto.InquiryDtos.CreateInquiryRequest;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquiryCreated;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquiryDetail;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquirySummary;
import com.ovenup.server.inquiry.dto.InquiryDtos.ReplyView;
import com.ovenup.server.notification.NotificationService;

/** 고객의 소리 처리 (05_API §7). 본인 글만 조회 가능. */
@Service
public class InquiryService {

    private final InquiryRepository inquiryRepository;
    private final InquiryReplyRepository inquiryReplyRepository;
    private final NotificationService notificationService;

    public InquiryService(InquiryRepository inquiryRepository, InquiryReplyRepository inquiryReplyRepository,
                          NotificationService notificationService) {
        this.inquiryRepository = inquiryRepository;
        this.inquiryReplyRepository = inquiryReplyRepository;
        this.notificationService = notificationService;
    }

    @Transactional
    public InquiryCreated create(Long userId, CreateInquiryRequest request) {
        String title = request.title() == null ? "" : request.title().trim();
        String content = request.content() == null ? "" : request.content().trim();
        if (title.isEmpty()) {
            throw ApiException.badRequest("INVALID_INPUT", "제목을 입력해 주세요.");
        }
        if (content.isEmpty()) {
            throw ApiException.badRequest("INVALID_INPUT", "내용을 입력해 주세요.");
        }
        InquiryEntity saved = inquiryRepository.save(
                new InquiryEntity(userId, title, content, request.imageUrl()));
        return new InquiryCreated(saved.getId(), saved.getStatus());
    }

    @Transactional(readOnly = true)
    public List<InquirySummary> myInquiries(Long userId) {
        return inquiryRepository.findByUserIdOrderByIdDesc(userId).stream()
                .map(i -> new InquirySummary(i.getId(), i.getTitle(), i.getStatus(), i.getCreatedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public InquiryDetail myInquiryDetail(Long userId, long inquiryId) {
        InquiryEntity inquiry = inquiryRepository.findById(inquiryId)
                .orElseThrow(() -> ApiException.notFound("NOT_FOUND", "문의를 찾을 수 없습니다."));
        if (!inquiry.getUserId().equals(userId)) {
            // 본인 글만 조회 가능: 존재 여부를 숨기기 위해 동일한 404로 응답
            throw ApiException.notFound("NOT_FOUND", "문의를 찾을 수 없습니다.");
        }
        ReplyView reply = inquiryReplyRepository.findByInquiryId(inquiryId)
                .map(r -> new ReplyView(r.getContent(), r.getCreatedAt()))
                .orElse(null);
        return new InquiryDetail(inquiry.getId(), inquiry.getTitle(), inquiry.getContent(),
                inquiry.getImageUrl(), inquiry.getStatus(), inquiry.getCreatedAt(), reply);
    }

    // ===== 관리자(사장님)용 =====

    /** 관리자: 전체 문의 목록(내용·답변 포함, 최신순) */
    @Transactional(readOnly = true)
    public List<AdminInquiryItem> adminList() {
        return inquiryRepository.findAllByOrderByIdDesc().stream()
                .map(i -> {
                    ReplyView reply = inquiryReplyRepository.findByInquiryId(i.getId())
                            .map(r -> new ReplyView(r.getContent(), r.getCreatedAt()))
                            .orElse(null);
                    return new AdminInquiryItem(i.getId(), i.getUserId(), i.getTitle(), i.getContent(),
                            i.getImageUrl(), i.getStatus(), i.getCreatedAt(), reply);
                })
                .toList();
    }

    /** 관리자: 문의에 답변(등록/수정) + 상태 답변완료 + 손님 알림 */
    @Transactional
    public ReplyView adminReply(long inquiryId, String content) {
        String text = content == null ? "" : content.trim();
        if (text.isEmpty()) {
            throw ApiException.badRequest("INVALID_INPUT", "답변 내용을 입력해 주세요.");
        }
        InquiryEntity inquiry = inquiryRepository.findById(inquiryId)
                .orElseThrow(() -> ApiException.notFound("NOT_FOUND", "문의를 찾을 수 없습니다."));

        InquiryReplyEntity reply = inquiryReplyRepository.findByInquiryId(inquiryId).orElse(null);
        if (reply == null) {
            reply = inquiryReplyRepository.save(new InquiryReplyEntity(inquiryId, text));
        } else {
            // 기존 답변 교체(간단히 삭제 후 재생성)
            inquiryReplyRepository.delete(reply);
            reply = inquiryReplyRepository.save(new InquiryReplyEntity(inquiryId, text));
        }
        inquiry.markAnswered();
        inquiryRepository.save(inquiry);

        notificationService.notifyUser(inquiry.getUserId(), "문의 답변 도착",
                "'" + inquiry.getTitle() + "' 문의에 사장님 답변이 등록됐어요.", "INQUIRY_REPLY", inquiry.getId());
        return new ReplyView(reply.getContent(), reply.getCreatedAt());
    }
}
