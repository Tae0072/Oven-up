import 'package:flutter/material.dart';

import 'data/api_menu_repository.dart';
import 'data/menu_repository.dart';
import 'data/social_auth.dart';
import 'screens/splash_page.dart';
import 'state/auth_store.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  // 기기에 저장된 로그인 정보를 먼저 복원한 뒤 앱을 시작한다.
  WidgetsFlutterBinding.ensureInitialized();
  // 카카오/네이버 로그인에서 막 돌아온 경우(주소에 ?code=...) 그 값을 먼저 챙겨둔다.
  SocialAuth.captureRedirectCallback();
  await AuthStore.instance.load();
  runApp(OvenUpApp());
}

/// 오븐업(5VEN UP) 앱의 시작점.
/// 진입 흐름: 로딩(스플래시) → (로그인 안 됨) 로그인 → 홈(하단 내비: 홈·메뉴·마이페이지).
/// 로그인이 유지돼 있으면 로딩 후 바로 홈으로 간다.
/// (테스트에서는 [home]에 특정 화면을, [repository]에 가짜 저장소를 넣어 서버·로그인 없이 확인한다.)
class OvenUpApp extends StatelessWidget {
  final MenuRepository repository;

  /// 테스트에서 진입 화면을 직접 지정할 때 사용(스플래시/로그인 관문을 건너뛴다).
  final Widget? home;

  OvenUpApp({super.key, MenuRepository? repository, this.home})
      : repository = repository ?? ApiMenuRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오븐업 5VEN UP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        useMaterial3: true,
      ),
      home: home ?? SplashPage(repository: repository),
    );
  }
}
