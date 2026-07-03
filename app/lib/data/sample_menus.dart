import '../models/menu_item.dart';
import '../models/menu_option.dart';

/// 샌드위치 공통 추가 옵션 (가짜 데이터).
const List<MenuOption> _commonOptions = <MenuOption>[
  MenuOption(id: 101, name: '치즈 추가', extraPrice: 1000),
  MenuOption(id: 102, name: '베이컨 추가', extraPrice: 1500),
  MenuOption(id: 103, name: '아보카도 추가', extraPrice: 2000),
  MenuOption(id: 104, name: '매운 소스', extraPrice: 0),
];

/// 5VEN UP 실제 대표 메뉴 7종 (고객 소개서 기준).
/// ⚠️ 지금은 화면 확인용 "가짜 데이터"입니다. 로드맵 3단계에서 서버(GET /api/menus)로 교체합니다.
const List<MenuItem> sampleMenus = <MenuItem>[
  MenuItem(
    id: 1,
    name: 'LA갈비 바게트 샌드위치',
    description: '달콤짭짤한 LA갈비를 바삭한 바게트에 듬뿍. 5VEN UP 대표 메뉴.',
    bread: '바게트',
    price: 12900,
    emoji: '🥖',
    isBest: true,
    options: _commonOptions,
  ),
  MenuItem(
    id: 2,
    name: '잠봉 루꼴라 샌드위치',
    description: '잠봉과 루꼴라의 담백한 조합. 치아바타로 든든하게.',
    bread: '치아바타',
    price: 12000,
    emoji: '🥪',
    options: _commonOptions,
  ),
  MenuItem(
    id: 3,
    name: '차지키 연어 샌드위치',
    description: '훈제 연어와 상큼한 차지키 소스.',
    bread: '바게트',
    price: 11000,
    emoji: '🐟',
    options: _commonOptions,
  ),
  MenuItem(
    id: 4,
    name: '풀드포크 샌드위치',
    description: '오래 익힌 풀드포크를 샤워도우에.',
    bread: '샤워도우',
    price: 11000,
    emoji: '🥓',
    options: _commonOptions,
  ),
  MenuItem(
    id: 5,
    name: '머쉬룸 치즈 샌드위치',
    description: '버섯과 치즈의 고소한 풍미.',
    bread: '샤워도우',
    price: 9500,
    emoji: '🍄',
    options: _commonOptions,
  ),
  MenuItem(
    id: 6,
    name: '크랜베리 치킨 샌드위치',
    description: '크랜베리의 상큼함과 부드러운 치킨.',
    bread: '치아바타',
    price: 8500,
    emoji: '🍗',
    options: _commonOptions,
  ),
  MenuItem(
    id: 7,
    name: '당근라페 샌드위치',
    description: '새콤한 당근라페로 산뜻하게.',
    bread: '치아바타',
    price: 8500,
    emoji: '🥕',
    options: _commonOptions,
  ),
];
