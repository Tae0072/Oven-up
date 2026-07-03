import 'package:flutter/material.dart';

/// 오븐업 앱 공통 색상 (프레시 그린 컨셉).
/// 브랜드색을 한 곳에서 관리해, 화면들이 같은 톤을 쓰도록 한다.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF17A968); // 프레시 그린 (메인)
  static const Color primaryDark = Color(0xFF0C7D4C); // 진한 그린 (그라데이션)
  static const Color accent = Color(0xFFFFC93C); // 옐로우 (BEST 뱃지 등 포인트)
  static const Color bg = Color(0xFFF4FAF5); // 연한 배경
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF16241C); // 진한 텍스트
  static const Color muted = Color(0xFF8AA596); // 보조 텍스트
}
