import 'package:flutter/material.dart';

import '../data/menu_repository.dart';
import '../state/auth_store.dart';
import 'login_page.dart';
import 'main_shell.dart';

/// S0. 로딩(스플래시) 화면.
/// 앱을 켜면 처음 보이는 로고 애니메이션 화면. 잠깐 보여준 뒤,
/// 로그인 상태면 홈(MainShell), 아니면 로그인 화면으로 자동 이동한다.
class SplashPage extends StatefulWidget {
  final MenuRepository repository;

  const SplashPage({super.key, required this.repository});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    // 로고 애니메이션을 잠깐 보여준 뒤 다음 화면으로 이동한다.
    Future<void>.delayed(const Duration(milliseconds: 1900), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final Widget next = AuthStore.instance.isLoggedIn
        ? MainShell(repository: widget.repository)
        : LoginPage(repository: widget.repository, isGate: true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFB5651D); // 오븐업 브랜드색(구운 빵색)
    return Scaffold(
      backgroundColor: brand,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bakery_dining, size: 52, color: brand),
                ),
                const SizedBox(height: 20),
                const Text(
                  '5VEN UP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '오븐업 · 샌드위치',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
