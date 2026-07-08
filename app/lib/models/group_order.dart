import '../utils/format.dart';

/// 단체 주문 문의 한 건 (05_API §6). 협의형 — 상태: 접수/협의중/확정/취소.
class GroupOrder {
  final int groupOrderId;
  final DateTime? desiredAt;
  final int headcount;
  final String detail;
  final String contact;
  final String status;
  final String? adminMemo; // 사장님 답변/메모 (없으면 null)
  final DateTime? createdAt;

  const GroupOrder({
    required this.groupOrderId,
    required this.headcount,
    required this.detail,
    required this.contact,
    required this.status,
    this.desiredAt,
    this.adminMemo,
    this.createdAt,
  });

  factory GroupOrder.fromJson(Map<String, dynamic> json) => GroupOrder(
        groupOrderId: (json['groupOrderId'] as num).toInt(),
        headcount: (json['headcount'] as num?)?.toInt() ?? 0,
        detail: (json['detail'] as String?) ?? '',
        contact: (json['contact'] as String?) ?? '',
        status: (json['status'] as String?) ?? '',
        desiredAt: parseServerDateTime(json['desiredAt']),
        adminMemo: json['adminMemo'] as String?,
        createdAt: parseServerDateTime(json['createdAt']),
      );
}
