package com.ovenup.server.auth;

import java.io.IOException;

import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 모든 요청에서 Authorization: Bearer {토큰} 을 확인해,
 * 유효하면 회원 id를 요청 속성(authUserId)에 담아 둔다.
 * (전체 Spring Security를 쓰지 않는 가벼운 방식 — 보호가 필요한 컨트롤러에서 이 값을 확인한다.)
 */
@Component
public class AuthTokenFilter extends OncePerRequestFilter {

    public static final String USER_ID_ATTR = "authUserId";

    private final JwtProvider jwtProvider;

    public AuthTokenFilter(JwtProvider jwtProvider) {
        this.jwtProvider = jwtProvider;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            Long userId = jwtProvider.parseUserId(token);
            if (userId != null) {
                request.setAttribute(USER_ID_ATTR, userId);
            }
        }
        filterChain.doFilter(request, response);
    }
}
