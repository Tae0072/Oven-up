import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'order_history_page.dart';

/// S8. 주문 완료 화면 (02_화면_정의서 S8).
/// 결제 성공 안내 + 주문번호 + 주문 내역/홈 이동.
class OrderCompletePage extends StatelessWidget {
  final String orderNo;

  const OrderCompletePage({super.key, required this.orderNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 결제 완료 후에는 뒤로 못 가게(주문서/결제 화면으로 되돌아가지 않도록) 앱바 없이 구성
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 88, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text(
                '주문이 완료됐어요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '주문번호  $orderNo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              Text(
                '준비가 시작되면 알려드릴게요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: () {
                  // 홈(첫 화면)으로 돌아간 뒤 주문 내역 열기
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const OrderHistoryPage()),
                  );
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('주문 내역 보기'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('홈으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
