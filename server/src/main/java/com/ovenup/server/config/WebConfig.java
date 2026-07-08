package com.ovenup.server.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CORS 설정.
 * 우리 서비스 출처(운영 웹 + 로컬 개발)에서만 /api/** 호출을 허용한다.
 * 앱(안드로이드/iOS)은 브라우저가 아니라 CORS 제한을 받지 않는다.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns(
                        "https://ven-up.web.app", // 운영 웹 (Firebase Hosting)
                        "https://ven-up.firebaseapp.com", // Firebase 보조 도메인
                        "http://localhost:[*]", // 로컬 개발 (flutter run -d chrome 등)
                        "http://127.0.0.1:[*]")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS");
    }
}
