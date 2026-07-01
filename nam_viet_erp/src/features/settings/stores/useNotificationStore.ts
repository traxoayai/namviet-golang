import { create } from "zustand";
import { supabase } from "@/shared/lib/supabaseClient";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";

// Cập nhật Interface khớp với bảng 'public.notifications' của CORE
export type NotificationCategory =
  | "expense_approval"
  | "purchase_order"
  | "payment_received"
  | "portal_order"
  | "portal_registration"
  | "task_update"
  | "sales_payment"
  | "chat_message";

export interface AppNotification {
  id: string;
  user_id: string;
  title: string;
  message: string;
  type: "info" | "success" | "warning" | "error";
  is_read: boolean;
  created_at: string;
  reference_id?: string | null;
  category?: NotificationCategory | null;
  metadata?: Record<string, unknown> | null;
}

interface NotificationState {
  notifications: AppNotification[];
  unreadCount: number;
  setNotifications: (notifications: AppNotification[]) => void;
  addNotification: (notification: AppNotification) => void;
  markAsRead: (id: string) => Promise<void>;
  markAllAsRead: () => Promise<void>;
}

export const useNotificationStore = create<NotificationState>((set) => ({
  notifications: [],
  unreadCount: 0,

  setNotifications: (data) =>
    set({
      notifications: data,
      unreadCount: data.filter((n) => !n.is_read).length,
    }),

  addNotification: (newItem) =>
    set((state) => ({
      notifications: [newItem, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    })),

  markAsRead: async (id: string) => {
    const user = useAuthStore.getState().user;
    if (!user) return;

    // Optimistic UI update
    set((state) => {
      const newNotis = state.notifications.map((n) =>
        n.id === id ? { ...n, is_read: true } : n
      );
      return {
        notifications: newNotis,
        unreadCount: newNotis.filter((n) => !n.is_read).length,
      };
    });
    // API Call
    try {
      await supabase
        .from("notifications")
        .update({ is_read: true })
        .eq("id", id)
        .eq("user_id", user.id);
    } catch (error) {
      console.error("Failed to mark notification as read", error);
    }
  },

  markAllAsRead: async () => {
    const user = useAuthStore.getState().user;
    if (!user) return;

    // Optimistic UI update
    set((state) => ({
      notifications: state.notifications.map((n) => ({ ...n, is_read: true })),
      unreadCount: 0,
    }));
    // API Call
    try {
      await supabase
        .from("notifications")
        .update({ is_read: true })
        .eq("user_id", user.id)
        .eq("is_read", false);
    } catch (error) {
      console.error("Failed to mark all notifications as read", error);
    }
  },
}));
