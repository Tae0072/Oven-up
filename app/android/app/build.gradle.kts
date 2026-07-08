plugins {
    id("com.android.application")
    // Firebase(FCM) 설정 주입 — android/app/google-services.json 필요 (레포에 커밋하지 않음)
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ovenup.oven_up_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications가 요구 (최신 자바 API를 구형 안드로이드에서 쓰게 해줌)
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        // 네이버 로그인 키를 문자열 리소스로 주입(resValue)하기 위해 필요 (최신 AGP는 기본 비활성)
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ovenup.oven_up_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ==== 소셜 로그인 키 주입 (환경변수로만, 커밋 금지) ====
        // 카카오 커스텀 스킴(kakao{네이티브앱키}://oauth)용 — 키 없으면 빈 값(개발 mock 모드)
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = System.getenv("KAKAO_NATIVE_APP_KEY") ?: ""
        // 네이버 SDK가 읽는 문자열 리소스 — 키 없으면 빈 값
        resValue("string", "naver_client_id", System.getenv("NAVER_CLIENT_ID") ?: "")
        resValue("string", "naver_client_secret", System.getenv("NAVER_CLIENT_SECRET") ?: "")
        resValue("string", "naver_client_name", "오븐업")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // R8 missing class(okhttp/conscrypt) 이슈로 코드 축소 비활성 (매장 태블릿용이라 용량 무관)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // core library desugaring 런타임 (위 compileOptions와 세트)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
