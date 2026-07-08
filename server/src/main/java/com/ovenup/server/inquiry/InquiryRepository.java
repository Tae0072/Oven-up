package com.ovenup.server.inquiry;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface InquiryRepository extends JpaRepository<InquiryEntity, Long> {

    List<InquiryEntity> findByUserIdOrderByIdDesc(Long userId);

    List<InquiryEntity> findAllByOrderByIdDesc();
}
