import { useEffect } from "react";
import { App } from "antd";
import { getToken, onMessage } from "firebase/messaging";
import { messaging } from "@/shared/lib/firebaseClient";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import axiosClient from "@/shared/utils/axiosClient";

export const useFCM = () => {
  const { message, notification } = App.useApp();
  const { user } = useAuthStore();

  useEffect(() => {
    // Only request token if user is logged in
    if (!user) return;

    const setupFCM = async () => {
      try {
        const permission = await Notification.requestPermission();
        if (permission === 'granted') {
          const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY || 'BDeOprBzYOuFmLH-1Hh1yk3HJrb66K8yaxUi5sgye132FliqJzFLGPv-Np6Nwbjnzxsk08bXmooQXUeT7Jly-xk';
          const token = await getToken(messaging, { vapidKey });
          
          if (token) {
            console.log("🔥 [FCM] Lấy Token thành công!");
            
            // Send token to backend via axios
            try {
              await axiosClient.post("/api/v1/notifications/fcm-token", {
                token: token,
                user_agent: navigator.userAgent
              });
              console.log("Đã gửi FCM token lên backend.");
              message.success("Đã kết nối máy chủ Thông báo (FCM) thành công!", 3);
            } catch (err) {
              console.error("Lỗi gửi FCM token:", err);
            }
          } else {
            console.log("Không có quyền tạo token FCM.");
          }
        } else if (permission === 'denied') {
          message.warning("Vui lòng bấm vào ổ khóa trên thanh địa chỉ để mở quyền Thông báo để nhận được cập nhật theo thời gian thực!");
        }
      } catch (error) {
        console.error("❌ [ERROR] Lỗi khởi tạo FCM:", error);
      }
    };

    setupFCM();

    // Listen to foreground messages
    const unsubscribe = onMessage(messaging, (payload) => {
      console.log('[FCM] Nhận tin nhắn Foreground: ', payload);
      notification.info({
        message: payload.notification?.title || 'Thông báo mới',
        description: payload.notification?.body || 'Bạn có thông báo mới',
        placement: 'bottomRight',
        duration: 5,
        onClick: () => {
           const anyPayload = payload as any;
           const targetUrl = anyPayload.data?.click_action || anyPayload.fcmOptions?.link || anyPayload.notification?.click_action || '/';
           window.location.href = targetUrl;
        }
      });
    });

    return () => {
      unsubscribe();
    };
  }, [user, message, notification]);
};
