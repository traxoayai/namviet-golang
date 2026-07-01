import React, { useState, useEffect } from "react";
import { Layout, Grid } from "antd";
import { Outlet, useLocation } from "react-router-dom";
import { MenuBar } from "./MenuBar";
import { HeaderBar } from "./HeaderBar";
import { MobileBottomNav } from "./MobileBottomNav";
import { GlobalSearchModal } from "../components/GlobalSearchModal";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { useHandoffNotifications } from "@/features/chatbot/hooks/useHandoffNotifications";
import { useAutoLogout } from "@/shared/hooks/useAutoLogout";
import { InternalChatDrawer } from "@/features/chat/components/InternalChatDrawer";

const { Content } = Layout;
const { useBreakpoint } = Grid;

const MainLayout: React.FC = () => {
  useAutoLogout(); // Bật tính năng tự động đăng xuất nếu không hoạt động
  const screens = useBreakpoint();
  const [collapsed, setCollapsed] = useState(false);
  const location = useLocation();
  const { permissions } = useAuthStore();

  // Notification Push Handoff cho Chatbot
  const canHandleChatbot = permissions.includes("crm.chatbot.handle") || permissions.includes("admin-all");
  useHandoffNotifications(canHandleChatbot);

  // Trên thiết bị mobile, luôn collapse sidebar để ẩn đi hoàn toàn hoặc mặc định tuỳ UI
  useEffect(() => {
    if (!screens.md) {
      setCollapsed(true);
    }
  }, [screens.md, location.pathname]);

  return (
    <Layout className="min-h-screen" style={{ backgroundColor: "#f2f7fc" }}>
      {/* 1. Global Search Modal (Cmd+K) */}
      <GlobalSearchModal />

      {/* 2. Desktop Sidebar (Ẩn trên màn hình nhỏ) */}
      {screens.md && (
        <MenuBar collapsed={collapsed} onCollapse={(val) => setCollapsed(val)} />
      )}

      {/* 3. Main Content Area */}
      <Layout
        style={{
          marginLeft: screens.md ? (collapsed ? 55 : 250) : 0,
          transition: "margin-left 0.2s ease",
          background: "transparent",
        }}
      >
        {/* 3.1. Desktop Header (Chỉ hiện trên Tablet/Desktop) */}
        {screens.md && <HeaderBar />}

        {/* 3.2. Main Outlet Content */}
        <Content className="p-1 md:p-2 pb-20 md:pb-2 relative z-0">
          <Outlet />
        </Content>
      </Layout>

      {/* 4. Mobile Bottom Navigation (Chỉ hiện trên Mobile) */}
      {!screens.md && <MobileBottomNav />}

      {/* 5. Internal Chat Drawer */}
      <InternalChatDrawer />
    </Layout>
  );
};

export default MainLayout;
