# Oven-up (5VEN UP)

샌드위치 카페 **오븐업(5VEN UP)** 주문 앱/웹 코드 레포입니다.
기획·설계 문서는 별도 레포 [Oven-up-repo](https://github.com/Tae0072/Oven-up-repo) 를 참고하세요.

- 브랜치: `main`(안정) / `dev`(개발) / `feature/*`(작업). 모든 작업은 `feature/*` → `dev` PR.

## 폴더 구조

```
Oven-up/
├── server/   # 백엔드 - Spring Boot 3.5.x (Java 21, Gradle)
└── app/      # 프론트엔드 - Flutter (web + android + ios)
```

## 필요한 도구

| 도구 | 버전 | 용도 |
| --- | --- | --- |
| JDK | 21 (Temurin 권장) | 서버(Spring Boot) 실행 |
| Flutter | stable (3.44+) | 앱/웹 화면 |

## 로컬 실행

### 서버 (Spring Boot)

```bash
cd server
./gradlew bootRun        # 윈도우: .\gradlew.bat bootRun
# 실행 후 확인: http://localhost:8080/api/health  →  {"success":true,...}
```

### 앱 (Flutter, 웹으로 실행)

```bash
cd app
flutter pub get
flutter run -d chrome
```

> ⚠️ **경로에 한글이 있으면** 로컬에서 `gradlew build` / `flutter analyze` 가 실패할 수 있습니다
> (윈도우 도구가 한글 경로를 제대로 못 읽는 문제). 서버 실행(`bootRun`)·앱 실행(`flutter run`)·`flutter test` 는 됩니다.
> 빌드/분석 검증은 GitHub CI(PR)가 대신 해줍니다.

## 문서 인덱스 (Oven-up-repo)

01 계획서 · 02 화면정의서 · 03 기능명세서 · 04 ERD · 05 API명세서 · 06 Git/PR규칙 · 07 자동PR세팅 · 08 인수인계
