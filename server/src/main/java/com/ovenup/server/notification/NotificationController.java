package com.ovenup.server.notification;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ovenup.server.auth.AuthTokenFilter;
import com.ovenup.server.common.ApiException;
import com.ovenup.server.common.ApiResponse;
import com.ovenup.server.notification.dto.NotificationDtos.NotificationView;
import com.ovenup.server.notification.dto.NotificationDtos.UnreadCount;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 알림 API (05_API §9). 모두 로그인 필요. 본인 알림만.
 * - GET  /api/notifications              : 내 알림 목록
 * - GET  /api/notifications/unread-count : 안 읽은 개수(배지용)
 * - POST /api/notifications/{id}/read    : 한 건 읽음
 * - POST /api/notifications/read-all     : 모두 읽음
 */
@RestController
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    private Long requireUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(AuthTokenFilter.USER_ID_ATTR);
        if (attr == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "로그인이 필요합니다.");
        }
        return (Long) attr;
    }

    /** 기기 토큰 등록 (푸시용). 앱이 FCM 토큰을 받으면 호출한다. */
    @PostMapping("/api/notifications/device-token")
    public ApiResponse<Void> registerDeviceToken(HttpServletRequest request,
                                                 @org.springframework.web.bind.annotation.RequestBody
                                                 com.ovenup.server.notification.dto.DeviceTokenRequest body) {
        notificationService.registerDeviceToken(requireUserId(request), body.token());
        return ApiResponse.ok(null);
    }

    @GetMapping("/api/notifications")
    public ApiResponse<List<NotificationView>> list(HttpServletRequest request) {
        return ApiResponse.ok(notificationService.myList(requireUserId(request)));
    }

    @GetMapping("/api/notifications/unread-count")
    public ApiResponse<UnreadCount> unreadCount(HttpServletRequest request) {
        return ApiResponse.ok(new UnreadCount(notificationService.unreadCount(requireUserId(request))));
    }

    @PostMapping("/api/notifications/{id}/read")
    public ApiResponse<UnreadCount> read(HttpServletRequest request, @PathVariable long id) {
        Long userId = requireUserId(request);
        notificationService.markRead(userId, id);
        return ApiResponse.ok(new UnreadCount(notificationService.unreadCount(userId)));
    }

    @PostMapping("/api/notifications/read-all")
    public ApiResponse<UnreadCount> readAll(HttpServletRequest request) {
        Long userId = requireUserId(request);
        notificationService.markAllRead(userId);
        return ApiResponse.ok(new UnreadCount(0));
    }
}
