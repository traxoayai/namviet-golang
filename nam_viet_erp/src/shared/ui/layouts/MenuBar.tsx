import React, { useMemo, useCallback } from "react";
import { Layout, Menu, type MenuProps } from "antd";
import { Link, useLocation } from "react-router-dom";
import { ChevronLeft, ChevronRight } from "lucide-react";
import Logo from "@/assets/logo.png";
import { MENU_DATA, MenuConfigItem } from "@/config/menu.config";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { LucideIcon } from "@/shared/ui/components/LucideIcon";

const { Sider } = Layout;

type MenuItem = Required<MenuProps>["items"][number];

interface MenuBarProps {
  collapsed: boolean;
  onCollapse: (collapsed: boolean) => void;
}

export const MenuBar: React.FC<MenuBarProps> = ({ collapsed, onCollapse }) => {
  const location = useLocation();
  const { permissions } = useAuthStore();

  const convertToAntdMenu = useCallback(
    (items: MenuConfigItem[]): MenuItem[] => {
      return items
        .map((item) => {
          // Check permissions
          if (item.requiredPermissions) {
            const hasPerm =
              item.requiredPermissions.some((p) => permissions.includes(p)) ||
              permissions.includes("admin-all");
            if (!hasPerm) return null;
          }

          let children: MenuItem[] | undefined = undefined;
          if (item.children && item.children.length > 0) {
            const mappedChildren = convertToAntdMenu(item.children);
            if (mappedChildren.length === 0) return null; // Ẩn cha nếu con bị ẩn hết do quyền
            children = mappedChildren;
          }

          return {
            key: item.href || item.id,
            icon: item.icon ? <LucideIcon name={item.icon} size={20} color="#4b5563" strokeWidth={1.5} /> : null,
            label: item.href && !children ? <Link to={item.href}>{item.name}</Link> : item.name,
            children,
          } as MenuItem;
        })
        .filter(Boolean) as MenuItem[];
    },
    [permissions]
  );

  const visibleMenuItems = useMemo(() => {
    return convertToAntdMenu(MENU_DATA);
  }, [convertToAntdMenu]);

  return (
    <Sider
      collapsible
      collapsed={collapsed}
      onCollapse={onCollapse}
      width={250}
      collapsedWidth={55}
      style={{
        background: "#ffffff",
        borderRight: "1px solid #d9d9d9",
        boxShadow: "none",
        position: "fixed",
        left: 0,
        top: 0,
        bottom: 0,
        zIndex: 1001,
      }}
      trigger={
        <div className="w-full h-10 flex items-center justify-center bg-gray-50 border-t border-gray-100 text-gray-500 hover:text-blue-600 transition-colors">
          {collapsed ? (
            <ChevronRight size={18} />
          ) : (
            <div className="flex items-center gap-2 text-xs font-semibold">
              <ChevronLeft size={16} /> Thu gọn sidebar
            </div>
          )}
        </div>
      }
    >
      <div
        style={{
          height: 64,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          borderBottom: "none",
          overflow: "hidden",
        }}
      >
        <img
          src={Logo}
          alt="Logo"
          style={{
            height: 32,
            marginRight: collapsed ? 0 : 8,
            transition: "all 0.2s",
          }}
        />
        {!collapsed && (
          <span
            style={{
              fontSize: "16px",
              fontWeight: 700,
              color: "#00b96b",
              whiteSpace: "nowrap",
              opacity: collapsed ? 0 : 1,
              transition: "opacity 0.3s",
            }}
          >
            DƯỢC NAM VIỆT
          </span>
        )}
      </div>

      <div
        className="custom-scrollbar"
        style={{
          height: "calc(100vh - 110px)",
          overflowY: "auto",
          overflowX: "hidden",
        }}
      >
        <Menu
          theme="light"
          defaultSelectedKeys={[location.pathname]}
          mode="inline"
          items={visibleMenuItems}
          style={{ borderRight: 0, background: "transparent" }}
        />
      </div>
    </Sider>
  );
};
