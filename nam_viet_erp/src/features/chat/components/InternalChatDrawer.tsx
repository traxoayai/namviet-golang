import React, { useEffect, useState } from "react";
import { Drawer, Typography, Input, Button, Avatar, Space } from "antd";
import { SendOutlined, LeftOutlined, UserOutlined, TeamOutlined } from "@ant-design/icons";
import { useInternalChatStore, InternalConversation } from "../stores/useInternalChatStore";
import { supabase } from "@/shared/lib/supabaseClient";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { MessageList } from "./MessageList";
import { PlusOutlined } from "@ant-design/icons";

const { Text } = Typography;

export const InternalChatDrawer: React.FC = () => {
  const { user } = useAuthStore();
  const isOpen = useInternalChatStore((s) => s.isOpen);
  const setIsOpen = useInternalChatStore((s) => s.setIsOpen);
  const conversations = useInternalChatStore((s) => s.conversations);
  const setConversations = useInternalChatStore((s) => s.setConversations);
  const activeConversationId = useInternalChatStore((s) => s.activeConversationId);
  const setActiveConversation = useInternalChatStore((s) => s.setActiveConversation);
  const addMessage = useInternalChatStore((s) => s.addMessage);
  const setMessages = useInternalChatStore((s) => s.setMessages);

  const [messageInput, setMessageInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [isCreating, setIsCreating] = useState(false);

  // 1. Fetch Danh sách cuộc hội thoại
  useEffect(() => {
    if (!isOpen || !user) return;

    const fetchConversations = async () => {
      // Vì RLS đã được thiết lập, ta lấy danh sách qua bảng trung gian internal_participants hoặc query trực tiếp
      const { data } = await (supabase as any)
        .from("internal_conversations")
        .select(`
          id, type, name, created_at, created_by,
          internal_participants!inner(user_id)
        `)
        .eq("internal_participants.user_id", user.id)
        .order("created_at", { ascending: false });

      if (data) {
        setConversations(data as unknown as InternalConversation[]);
      }
    };

    fetchConversations();
  }, [isOpen, user, setConversations]);

  // 2. Fetch Tin nhắn của phòng active
  useEffect(() => {
    if (!activeConversationId) return;

    const fetchMessages = async () => {
      const { data } = await (supabase as any)
        .from("internal_messages")
        .select("*")
        .eq("conversation_id", activeConversationId)
        .order("created_at", { ascending: true })
        .limit(100);

      if (data) {
        setMessages(activeConversationId, data);
      }
    };

    fetchMessages();
  }, [activeConversationId, setMessages]);

  // 3. Subscribe Kênh Realtime cho TẤT CẢ các phòng chat của mình
  useEffect(() => {
    if (!user) return;

    const channel = supabase.channel("public:internal_messages")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "internal_messages",
        },
        (payload) => {
          // Chỉ addMessage. Context sẽ lo việc phát âm thanh.
          addMessage(payload.new as any);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, addMessage]);

  const handleSend = async () => {
    if (!messageInput.trim() || !activeConversationId || !user) return;
    setLoading(true);

    try {
      await (supabase as any).from("internal_messages").insert({
        conversation_id: activeConversationId,
        sender_id: user.id,
        content: messageInput.trim(),
      });
      setMessageInput("");
    } catch (error) {
      console.error("Lỗi gửi tin nhắn", error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateGroup = async () => {
    if (!user) return;
    setIsCreating(true);
    try {
      const groupName = prompt("Nhập tên phòng chat mới:", "Nhóm Chat");
      if (!groupName) return;

      const { data: convData, error: convErr } = await (supabase as any)
        .from("internal_conversations")
        .insert({
          type: "group",
          name: groupName,
          created_by: user.id
        })
        .select()
        .single();

      if (convErr) throw convErr;

      if (convData) {
        await (supabase as any).from("internal_participants").insert({
          conversation_id: convData.id,
          user_id: user.id,
          last_read_at: new Date().toISOString()
        });
        
        // Refresh conversations
        const { data } = await (supabase as any)
          .from("internal_conversations")
          .select(`
            id, type, name, created_at, created_by,
            internal_participants!inner(user_id)
          `)
          .eq("internal_participants.user_id", user.id)
          .order("created_at", { ascending: false });

        if (data) {
          setConversations(data as unknown as InternalConversation[]);
          setActiveConversation(convData.id);
        }
      }
    } catch (error) {
      console.error("Lỗi tạo phòng chat", error);
    } finally {
      setIsCreating(false);
    }
  };

  const activeConversation = conversations.find(c => c.id === activeConversationId);

  return (
    <Drawer
      title={<span className="text-xl font-bold text-gray-800">Trò chuyện Nội bộ</span>}
      placement="right"
      onClose={() => setIsOpen(false)}
      open={isOpen}
      width={900}
      styles={{ body: { padding: 0, display: "flex", flexDirection: "row", background: "#f2f7fc" } }}
      closeIcon={<LeftOutlined />}
    >
      {/* Cột Trái: Khu vực hiển thị nội dung chat (Active Chat Area) */}
      <div className="flex-1 flex flex-col h-full bg-white border-r border-gray-200">
        {activeConversationId ? (
          <div className="flex flex-col h-full">
            {/* Header phòng chat */}
            <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-white shadow-[0_2px_10px_rgba(0,0,0,0.02)] z-10">
              <Space>
                <Avatar 
                  size="large" 
                  icon={activeConversation?.type === 'group' ? <TeamOutlined /> : <UserOutlined />} 
                  className="bg-blue-100 text-blue-600" 
                />
                <div>
                  <Text strong className="text-lg block leading-tight">{activeConversation?.name || "Tin nhắn"}</Text>
                  <Text type="secondary" className="text-xs text-blue-500">Đang hoạt động</Text>
                </div>
              </Space>
            </div>
            
            {/* Nội dung chat */}
            <div className="flex-1 overflow-hidden bg-slate-50 relative">
              <MessageList conversationId={activeConversationId} />
            </div>

            {/* Input chat */}
            <div className="p-4 border-t border-gray-100 bg-white">
              <div className="flex items-center gap-2 bg-gray-50 rounded-full border border-gray-200 p-1 px-4 shadow-inner focus-within:bg-white focus-within:border-blue-400 transition-all">
                <Input
                  variant="borderless"
                  placeholder="Nhập nội dung... (hỗ trợ tag /PO-xxx)"
                  value={messageInput}
                  onChange={(e) => setMessageInput(e.target.value)}
                  onPressEnter={handleSend}
                  disabled={loading}
                  className="flex-1 bg-transparent py-2"
                />
                <Button 
                  type="primary" 
                  shape="circle" 
                  icon={<SendOutlined />} 
                  onClick={handleSend}
                  loading={loading}
                  disabled={!messageInput.trim()}
                  className="bg-blue-600 hover:bg-blue-700 shadow-md border-0"
                />
              </div>
            </div>
          </div>
        ) : (
          <div className="h-full flex items-center justify-center flex-col text-gray-400 bg-slate-50">
            <div className="text-7xl mb-6 opacity-20">💬</div>
            <p className="text-lg font-medium text-gray-500">Chọn một cuộc trò chuyện để bắt đầu</p>
            <p className="text-sm text-gray-400 mt-2">Hoặc tạo một nhóm chat mới từ danh sách bên phải</p>
          </div>
        )}
      </div>

      {/* Cột Phải: Danh sách hội thoại (Conversation List) */}
      <div className="w-[320px] h-full flex flex-col bg-[#f2f7fc]">
        <div className="p-4 flex items-center justify-between border-b border-gray-200/50">
          <Text strong className="text-gray-600 uppercase tracking-wider text-xs">Danh sách trò chuyện</Text>
          <Button 
            type="primary" 
            size="small" 
            icon={<PlusOutlined />} 
            onClick={handleCreateGroup}
            loading={isCreating}
            className="bg-blue-600 shadow-sm rounded-md border-0"
          >
            Tạo
          </Button>
        </div>

        <div className="flex-1 overflow-y-auto px-3 py-4 space-y-2">
          {conversations.length === 0 ? (
            <div className="text-center py-8 text-gray-400">
              Chưa có hội thoại nào
            </div>
          ) : (
            conversations.map((item) => {
              const isActive = activeConversationId === item.id;
              return (
                <div 
                  key={item.id}
                  onClick={() => setActiveConversation(item.id)}
                  className={`cursor-pointer p-3 rounded-xl transition-all duration-200 ${
                    isActive 
                      ? "bg-white shadow-[0_4px_12px_rgba(0,0,0,0.05)] border-l-4 border-blue-600" 
                      : "hover:bg-white/60 hover:shadow-sm border-l-4 border-transparent"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Avatar 
                      icon={item.type === 'group' ? <TeamOutlined /> : <UserOutlined />} 
                      className={`transition-colors ${isActive ? "bg-blue-600 text-white" : "bg-blue-100 text-blue-600"}`} 
                    />
                    <div className="flex-1 min-w-0">
                      <Text strong className={`block truncate ${isActive ? "text-blue-700" : "text-gray-800"}`}>
                        {item.name || "Phòng chat"}
                      </Text>
                      <Text className="text-xs text-gray-400 truncate block">Bấm để trò chuyện</Text>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </Drawer>
  );
};
