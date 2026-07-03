package com.ovenup.server.inquiry;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface InquiryReplyRepository extends JpaRepository<InquiryReplyEntity, Long> {

    Optional<InquiryReplyEntity> findByInquiryId(Long inquiryId);
}
