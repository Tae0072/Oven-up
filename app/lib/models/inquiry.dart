import '../utils/format.dart';

/// 고객의 소리 목록 항목 (05_API §7.2)
class InquirySummary {
  final int inquiryId;
  final String title;
  final String status; // 접수 / 답변완료
  final DateTime? createdAt;

  const InquirySummary({
    required this.inquiryId,
    required this.title,
    required this.status,
    this.createdAt,
  });

  factory InquirySummary.fromJson(Map<String, dynamic> json) => InquirySummary(
        inquiryId: (json['inquiryId'] as num).toInt(),
        title: (json['title'] as String?) ?? '',
        status: (json['status'] as String?) ?? '',
        createdAt: parseServerDateTime(json['createdAt']),
      );
}

/// 사장님 답변 (05_API §7.3)
class InquiryReply {
  final String content;
  final DateTime? createdAt;

  const InquiryReply({required this.content, this.createdAt});

  factory InquiryReply.fromJson(Map<String, dynamic> json) => InquiryReply(
        content: (json['content'] as String?) ?? '',
        createdAt: parseServerDateTime(json['createdAt']),
      );
}

/// 고객의 소리 상세 (05_API §7.3). reply는 답변이 없으면 null.
class InquiryDetail {
  final int inquiryId;
  final String title;
  final String content;
  final String? imageUrl;
  final String status;
  final DateTime? createdAt;
  final InquiryReply? reply;

  const InquiryDetail({
    required this.inquiryId,
    required this.title,
    required this.content,
    required this.status,
    this.imageUrl,
    this.createdAt,
    this.reply,
  });

  factory InquiryDetail.fromJson(Map<String, dynamic> json) => InquiryDetail(
        inquiryId: (json['inquiryId'] as num).toInt(),
        title: (json['title'] as String?) ?? '',
        content: (json['content'] as String?) ?? '',
        imageUrl: json['imageUrl'] as String?,
        status: (json['status'] as String?) ?? '',
        createdAt: parseServerDateTime(json['createdAt']),
        reply: json['reply'] is Map<String, dynamic>
            ? InquiryReply.fromJson(json['reply'] as Map<String, dynamic>)
            : null,
      );
}
