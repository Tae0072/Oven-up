package com.ovenup.server.inquiry;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ovenup.server.common.ApiException;
import com.ovenup.server.inquiry.dto.InquiryDtos.CreateInquiryRequest;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquiryCreated;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquiryDetail;
import com.ovenup.server.inquiry.dto.InquiryDtos.InquirySummary;
import com.ovenup.server.inquiry.dto.InquiryDtos.ReplyView;

/** 고객의 소리 처리 (05_API §7). 본인 글만 조회 가능. */
@Service
public class InquiryService {

    private final InquiryRepository inquiryRepository;
    private final InquiryReplyRepository inquiryReplyRepository;

    public InquiryService(InquiryRepository inquiryRepository, InquiryReplyRepository inquiryReplyRepository) {
        this.inquiryRepository = inquiryRepository;
        this.inquiryReplyRepository = inquiryReplyRepository;
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
}
