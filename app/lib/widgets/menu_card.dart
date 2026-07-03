import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../utils/format.dart';

/// 메뉴 목록에서 메뉴 하나를 보여주는 카드.
/// 사진(임시 이모지) + 이름 + BEST 배지 + 빵 종류 + 가격 + [담기] 버튼.
class MenuCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;

  const MenuCard({super.key, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 임시 썸네일 (사진 대신 이모지)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF5ECE2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 12),
            // 이름 / 빵 / 가격
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.isBest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB5651D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.bread,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(item.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onAdd, child: const Text('담기')),
          ],
        ),
      ),
    );
  }
}
