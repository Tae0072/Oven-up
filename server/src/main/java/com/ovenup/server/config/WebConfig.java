package com.ovenup.server.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 개발용 CORS 설정.
 * Flutter 웹(다른 포트)에서 이 서버의 /api/** 를 호출할 수 있게 허용한다.
 * ⚠️ 지금은 개발 편의를 위해 모든 출처 허용. 배포 시에는 실제 도메인만 허용하도록 좁힐 것.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS");
    }
}
