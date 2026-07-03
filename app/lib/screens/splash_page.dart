import 'package:flutter/material.dart';

import '../data/menu_repository.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';
import 'main_shell.dart';

/// S0. 로딩(스플래시) 화면 — 프레시 그린 배경 위에 오븐업 손그림 로고.
/// 로고 카드가 살짝 커지며 떠오르고, 로고와 문구가 순서대로 나타나는 애니메이션.
/// 잠깐 보여준 뒤 로그인 상태면 홈(MainShell), 아니면 로그인 화면으로 이동한다.
class SplashPage extends StatefulWidget {
  final MenuRepository repository;

  const SplashPage({super.key, required this.repository});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardFade;
  late final Animation<double> _cardScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _cardFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _cardScale = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack)));
    _logoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.8, curve: Curves.easeIn));
    _textFade = CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn));
    _textSlide = Tween<double>(begin: 16, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _controller.forward();

    // 애니메이션을 잠깐 보여준 뒤 다음 화면으로 이동한다.
    Future<void>.delayed(const Duration(milliseconds: 2100), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final Widget next = AuthStore.instance.isLoggedIn
        ? MainShell(repository: widget.repository)
        : LoginPage(repository: widget.repository, isGate: true);
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로고 카드 (떠오르며 커짐)
              FadeTransition(
                opacity: _cardFade,
                child: ScaleTransition(
                  scale: _cardScale,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.bakery_dining, size: 90, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              // 문구 (아래에서 떠오르며 나타남)
              FadeTransition(
                opacity: _textFade,
                child: AnimatedBuilder(
                  animation: _textSlide,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '오븐업 · 수제 샌드위치',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '매일 아침 굽는 신선한 한 끼',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
