package com.ovenup.server.auth;

import java.nio.charset.StandardCharsets;
import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

/**
 * 로그인 토큰(JWT)을 만들고 검증한다.
 * - 시크릿은 환경변수 JWT_SECRET 로 주는 걸 권장(32자 이상).
 * - 없으면 개발용으로 서버 시작 시 무작위 키를 만든다(재시작하면 기존 토큰은 무효).
 */
@Component
public class JwtProvider {

    /** 토큰 유효기간: 7일 */
    private static final long VALIDITY_MS = 1000L * 60 * 60 * 24 * 7;

    private final SecretKey key;

    public JwtProvider(@Value("${JWT_SECRET:}") String secret) {
        if (secret == null || secret.isBlank()) {
            this.key = Jwts.SIG.HS256.key().build();
        } else {
            this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        }
    }

    public String createToken(Long userId, String role) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + VALIDITY_MS);
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("role", role)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key)
                .compact();
    }

    /** 토큰이 유효하면 회원 id 반환, 아니면 null */
    public Long parseUserId(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return Long.valueOf(claims.getSubject());
        } catch (Exception e) {
            return null;
        }
    }
}
