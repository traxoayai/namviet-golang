import { create } from "zustand";
import { supabase } from "@/shared/lib/supabaseClient";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";

export interface InternalMessage {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  created_at: string;
  attachments?: string[] | null;
}

export interface InternalConversation {
  id: string;
  type: "direct" | "group";
  name: string | null;
  created_at: string;
  created_by: string;
}

interface InternalChatState {
  isOpen: boolean;
  activeConversationId: string | null;
  conversations: InternalConversation[];
  messages: Record<string, InternalMessage[]>; // Key is conversation_id
  
  setIsOpen: (isOpen: boolean) => void;
  setActiveConversation: (id: string | null) => void;
  setConversations: (conversations: InternalConversation[]) => void;
  addMessage: (message: InternalMessage) => void;
  setMessages: (conversationId: string, messages: InternalMessage[]) => void;
  
  // Hành động gọi DB
  updateHeartbeat: (conversationId: string) => Promise<void>;
}

export const useInternalChatStore = create<InternalChatState>((set, get) => ({
  isOpen: false,
  activeConversationId: null,
  conversations: [],
  messages: {},

  setIsOpen: (isOpen) => set({ isOpen }),
  
  setActiveConversation: (id) => {
    set({ activeConversationId: id });
    if (id) {
      get().updateHeartbeat(id);
    }
  },
  
  setConversations: (conversations) => set({ conversations }),
  
  addMessage: (message) => set((state) => {
    const prev = state.messages[message.conversation_id] || [];
    // Ngăn chặn trùng lặp tin nhắn khi render
    if (prev.find(m => m.id === message.id)) return state;
    
    return {
      messages: {
        ...state.messages,
        [message.conversation_id]: [...prev, message]
      }
    };
  }),
  
  setMessages: (conversationId, messages) => set((state) => ({
    messages: {
      ...state.messages,
      [conversationId]: messages
    }
  })),

  updateHeartbeat: async (conversationId: string) => {
    const user = useAuthStore.getState().user;
    if (!user || !conversationId) return;

    try {
      await (supabase as any)
        .from("internal_participants")
        .update({ last_read_at: new Date().toISOString() })
        .eq("conversation_id", conversationId)
        .eq("user_id", user.id);
    } catch (error) {
      console.error("Failed to update heartbeat:", error);
    }
  }
}));
