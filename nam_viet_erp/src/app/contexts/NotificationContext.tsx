// src/app/contexts/NotificationContext.tsx
import { notification } from "antd";
import React, { createContext, useEffect, useRef } from "react";

import { supabase } from "@/shared/lib/supabaseClient"; // Đảm bảo đường dẫn đúng alias @
import {
  useNotificationStore,
  AppNotification,
} from "@/features/settings/stores/useNotificationStore";
import { useInternalChatStore } from "@/features/chat/stores/useInternalChatStore";

export const NotificationContext = createContext({});

export const NotificationProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const addNotification = useNotificationStore(
    (state) => state.addNotification
  );
  const setNotifications = useNotificationStore(
    (state) => state.setNotifications
  );
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const lastSoundTimeRef = useRef<number>(0);

  useEffect(() => {
    // file âm thanh thông báo.
    audioRef.current = new Audio("/sounds/notification.mp3");

    if ("Notification" in window && Notification.permission !== "granted") {
      Notification.requestPermission();
    }
  }, []);

  const handleNewNotification = (payload: AppNotification) => {
    // 1. Cập nhật Store
    addNotification(payload);

    const isChat = payload.category === "chat_message";
    const activeConversationId = useInternalChatStore.getState().activeConversationId;

    // Nếu là chat và đang ở đúng phòng chat đó -> Không Toast, Không Âm thanh
    if (isChat && activeConversationId === payload.reference_id) {
      return;
    }

    // 2. Phát âm thanh (Có Debounce 3s cho tin nhắn chat)
    const now = Date.now();
    if (audioRef.current) {
      if (!isChat || (now - lastSoundTimeRef.current > 3000)) {
        audioRef.current
          .play()
          .catch((e) => console.log("Audio autoplay blocked:", e));
        lastSoundTimeRef.current = now;
      }
    }

    // Nếu là tin nhắn group chat thông thường (không tag), có thể chặn Toast ở đây tùy vào yêu cầu.
    // Tạm thời vẫn hiện Toast cho direct chat / nhóm. 

    // 3. Hiển thị Toast (Ant Design)
    const type = payload.type || "info";
    notification[type]({
      message: payload.title,
      description: payload.message,
      placement: "topRight",
      duration: 4,
    });

    // 4. Desktop Notification
    if (
      document.visibilityState === "hidden" &&
      Notification.permission === "granted"
    ) {
      const desktopNoti = new Notification(payload.title, {
        body: payload.message,
        icon: "/vite.svg",
      });
      desktopNoti.onclick = () => {
        window.focus();
        // Có thể navigate dựa trên category ở đây nếu cần, tạm thời focus lại web
        desktopNoti.close();
      };
    }
  };

  useEffect(() => {
    const subscribeToNotifications = async () => {
      // Logic lấy User hiện tại vẫn dùng auth.getUser() là chuẩn xác nhất
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;

      // 1. Lấy 50 thông báo gần nhất khi khởi tạo
      const { data: recentNotis } = await supabase
        .from("notifications")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .limit(50);
        
      if (recentNotis) {
        setNotifications(recentNotis as AppNotification[]);
      }

      // 2. Subscribe Realtime

      const channel = supabase
        .channel("realtime-notifications")
        .on(
          "postgres_changes",
          {
            event: "INSERT",
            schema: "public",
            table: "notifications",
            filter: `user_id=eq.${user.id}`,
          },
          (payload) => {
            // Ép kiểu dữ liệu trả về từ Realtime cho khớp với Interface
            const newNoti = payload.new as AppNotification;
            handleNewNotification(newNoti);
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(channel);
      };
    };

    subscribeToNotifications();
  }, []);

  return (
    <NotificationContext.Provider value={{}}>
      {children}
    </NotificationContext.Provider>
  );
};
