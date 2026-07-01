import React, { useMemo } from "react";
import { Layout, Button, Avatar, Dropdown, MenuProps, Breadcrumb } from "antd";
import { Search, Settings, LogOut, User as UserIcon } from "lucide-react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { NotificationBell } from "@/features/notifications/components/NotificationBell";
import { useInternalChatStore } from "@/features/chat/stores/useInternalChatStore";
import { MessageOutlined } from "@ant-design/icons";
import { MENU_DATA } from "@/config/menu.config";

const { Header } = Layout;

export const HeaderBar: React.FC = () => {
  const { user, profile, logout } = useAuthStore();
  const setIsChatOpen = useInternalChatStore(state => state.setIsOpen);
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
  };

  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.altKey && e.key.toLowerCase() === "c") {
        e.preventDefault();
        setIsChatOpen(true);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [setIsChatOpen]);

  const userMenuItems: MenuProps["items"] = [
    {
      key: "profile",
      label: "Cập nhật Hồ sơ",
      icon: <UserIcon size={16} />,
      onClick: () => navigate("/onboarding/update-profile"),
    },
    {
      key: "password",
      label: "Đổi Mật khẩu",
      icon: <Settings size={16} />,
      onClick: () => navigate("/onboarding/update-password"),
    },
    { type: "divider" },
    {
      key: "logout",
      icon: <LogOut size={16} />,
      label: "Đăng xuất",
      onClick: handleLogout,
      danger: true,
    },
  ];

  // Helper to generate Breadcrumbs from MENU_DATA
  const breadcrumbs = useMemo(() => {
    const paths = location.pathname.split("/").filter(Boolean);
    const result: { title: string }[] = [{ title: "Trang chủ" }];
    
    // Rất cơ bản: Dựa vào URL để tìm item trong MENU_DATA. 
    // Có thể cải tiến bằng hàm đệ quy tìm chính xác tên route nếu cần thiết.
    let currentLevel = MENU_DATA;
    let currentPath = "";

    for (const segment of paths) {
      currentPath += `/${segment}`;
      const foundItem = currentLevel.find((item) => item.href === currentPath || item.id === segment);
      if (foundItem) {
        result.push({ title: foundItem.name });
        currentLevel = foundItem.children || [];
      } else {
        // Fallback nếu không tìm thấy trong menu (e.g. trang chi tiết)
        // result.push({ title: segment });
      }
    }
    return result;
  }, [location.pathname]);

  return (
    <Header
      style={{
        background: "#ffffff",
        padding: "0 24px",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        borderBottom: "1px solid #d9d9d9",
        height: 60,
        position: "sticky",
        top: 0,
        zIndex: 9,
      }}
    >
      <div className="flex items-center">
        <Breadcrumb items={breadcrumbs} className="hidden lg:block text-sm font-medium text-gray-600" />
      </div>

      <div className="flex items-center gap-4">
        {/* Nút giả lập mở Global Search Modal (Hoặc người dùng có thể ấn Cmd+K) */}
        <Button
          type="default"
          icon={<Search size={16} />}
          onClick={() => {
            // Kích hoạt sự kiện Cmd+K
            window.dispatchEvent(
              new KeyboardEvent("keydown", {
                key: "k",
                ctrlKey: true,
              })
            );
          }}
          className="hidden md:flex items-center text-gray-500 rounded-full border-gray-200"
        >
          Tìm kiếm (Ctrl+K)
        </Button>

        <Button 
          type="text" 
          shape="circle" 
          onClick={() => setIsChatOpen(true)}
          title="Nội bộ (Alt + C)"
        >
          <MessageOutlined style={{ fontSize: 20 }} />
        </Button>

        <NotificationBell />

        <Dropdown menu={{ items: userMenuItems }} placement="bottomRight" arrow>
          <div className="flex items-center gap-2 cursor-pointer p-1 pr-2 rounded-full hover:bg-gray-50 border border-transparent hover:border-gray-200 transition-all">
            <Avatar src={profile?.avatar_url} icon={<UserIcon size={16} />} />
            <div className="hidden md:flex flex-col items-start leading-tight">
              <span className="text-sm font-semibold text-gray-800">
                {profile?.full_name || user?.email?.split("@")[0] || "User"}
              </span>
              <span className="text-xs text-gray-500">
                {(profile as any)?.role || "Nhân viên"}
              </span>
            </div>
          </div>
        </Dropdown>
      </div>
    </Header>
  );
};
