import '../models/menu_item.dart';

/// 5VEN UP 실제 대표 메뉴 7종 (고객 소개서 기준).
/// ⚠️ 지금은 화면 확인용 "가짜 데이터"입니다. 로드맵 3단계에서 서버(GET /api/menus)로 교체합니다.
const List<MenuItem> sampleMenus = <MenuItem>[
  MenuItem(id: 1, name: 'LA갈비 바게트 샌드위치', bread: '바게트', price: 12900, emoji: '🥖', isBest: true),
  MenuItem(id: 2, name: '잠봉 루꼴라 샌드위치', bread: '치아바타', price: 12000, emoji: '🥪'),
  MenuItem(id: 3, name: '차지키 연어 샌드위치', bread: '바게트', price: 11000, emoji: '🐟'),
  MenuItem(id: 4, name: '풀드포크 샌드위치', bread: '샤워도우', price: 11000, emoji: '🥓'),
  MenuItem(id: 5, name: '머쉬룸 치즈 샌드위치', bread: '샤워도우', price: 9500, emoji: '🍄'),
  MenuItem(id: 6, name: '크랜베리 치킨 샌드위치', bread: '치아바타', price: 8500, emoji: '🍗'),
  MenuItem(id: 7, name: '당근라페 샌드위치', bread: '치아바타', price: 8500, emoji: '🥕'),
];
