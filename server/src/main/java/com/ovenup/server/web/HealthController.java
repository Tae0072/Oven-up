package com.ovenup.server.web;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 서버가 살아있는지 확인하는 아주 간단한 컨트롤러.
 * - GET /            : 사람이 보는 안내 문구
 * - GET /api/health  : 화면(앱)이 확인용으로 부르는 상태 응답 (공통 응답 형태: success/data)
 *
 * 참고 문서: 05_API_명세서 §1 공통 응답 형태.
 */
@RestController
public class HealthController {

    @GetMapping("/")
    public String home() {
        return "Oven-up(5VEN UP) server is running. 상태 확인은 GET /api/health";
    }

    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of(
            "success", true,
            "data", Map.of(
                "status", "UP",
                "service", "oven-up-server"
            )
        );
    }
}
