import React, { useEffect, useRef } from "react";
import { Avatar } from "antd";
import { UserOutlined } from "@ant-design/icons";
import dayjs from "dayjs";
import { useInternalChatStore } from "../stores/useInternalChatStore";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { parseChatMessage } from "../utils/messageParser";

interface MessageListProps {
  conversationId: string;
}

export const MessageList: React.FC<MessageListProps> = ({ conversationId }) => {
  const { user } = useAuthStore();
  const messages = useInternalChatStore(state => state.messages[conversationId]);
  const updateHeartbeat = useInternalChatStore(state => state.updateHeartbeat);
  
  const endOfMessagesRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom
  useEffect(() => {
    endOfMessagesRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // Bắn nhịp tim (Heartbeat) khi user focus/hover vào ds tin nhắn hoặc khi có tin mới
  useEffect(() => {
    updateHeartbeat(conversationId);
  }, [messages?.length, conversationId, updateHeartbeat]);

  if (!messages || messages.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center text-gray-400 p-4">
        Chưa có tin nhắn nào. Bắt đầu trò chuyện!
      </div>
    );
  }

  return (
    <div 
      className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50"
      onMouseEnter={() => updateHeartbeat(conversationId)}
    >
      {(messages || []).map((msg, idx) => {
        const isMe = msg.sender_id === user?.id;
        const showAvatar = idx === 0 || (messages || [])[idx - 1].sender_id !== msg.sender_id;

        return (
          <div key={msg.id} className={`flex ${isMe ? "justify-end" : "justify-start"}`}>
            {!isMe && (
              <div className="w-8 flex-shrink-0 mr-2">
                {showAvatar && <Avatar icon={<UserOutlined />} size="small" />}
              </div>
            )}
            
            <div className={`max-w-[75%] flex flex-col ${isMe ? "items-end" : "items-start"}`}>
              <div 
                className={`px-4 py-2.5 rounded-2xl shadow-sm ${
                  isMe 
                    ? "bg-gradient-to-r from-blue-600 to-blue-500 text-white rounded-br-sm" 
                    : "bg-white text-gray-800 rounded-bl-sm border border-gray-100 shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
                }`}
                style={{ wordBreak: "break-word" }}
              >
                {parseChatMessage(msg.content)}
              </div>
              <span className="text-[10px] text-gray-400 mt-1 px-1">
                {dayjs(msg.created_at).format("HH:mm")}
              </span>
            </div>
          </div>
        );
      })}
      <div ref={endOfMessagesRef} />
    </div>
  );
};
