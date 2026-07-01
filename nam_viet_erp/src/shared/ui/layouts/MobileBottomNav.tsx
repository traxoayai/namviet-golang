import React, { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { Home, Package, Users, Settings, Search, Download, FileText } from "lucide-react";
import Logo from "@/assets/logo.png";
import { Drawer } from "antd";

export const MobileBottomNav: React.FC = () => {
  const location = useLocation();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [isSpinning, setIsSpinning] = useState(false);

  const handleFabClick = () => {
    setIsSpinning(true);
    setTimeout(() => setIsSpinning(false), 600); // Thời gian xoay 600ms
    setDrawerOpen(true);
  };

  const navItems = [
    { id: "home", icon: Home, label: "Tổng quan", href: "/" },
    { id: "inventory", icon: Package, label: "Kho", href: "/inventory/products" },
    { id: "fab", isFab: true }, // Nút FAB ở giữa
    { id: "crm", icon: Users, label: "Khách", href: "/crm/b2b" },
    { id: "settings", icon: Settings, label: "Cài đặt", href: "/settings" },
  ];

  return (
    <>
      <div 
        className="fixed bottom-0 left-0 right-0 bg-white shadow-[0_-4px_10px_rgba(0,0,0,0.05)] rounded-t-[1.5rem] z-50 md:hidden flex justify-around items-center px-2 pb-safe pt-2 h-16 border-t border-gray-100"
        style={{ paddingBottom: "env(safe-area-inset-bottom)" }}
      >
        {navItems.map((item) => {
          if (item.isFab) {
            return (
              <div key="fab" className="relative -top-6">
                <button
                  onClick={handleFabClick}
                  className="w-14 h-14 bg-white rounded-full shadow-lg border border-gray-100 flex items-center justify-center transform hover:scale-105 active:scale-95 transition-transform"
                >
                  <img 
                    src={Logo} 
                    alt="Logo" 
                    className="w-8 h-8 object-contain transition-transform duration-500 ease-in-out"
                    style={{ transform: isSpinning ? "rotate(360deg)" : "rotate(0deg)" }}
                  />
                </button>
              </div>
            );
          }

          const isActive = location.pathname === item.href;
          const Icon = item.icon!;

          return (
            <Link
              key={item.id}
              to={item.href!}
              className={`flex flex-col items-center justify-center w-16 gap-1 ${
                isActive ? "text-blue-600" : "text-gray-400 hover:text-gray-600"
              }`}
            >
              <Icon size={20} strokeWidth={isActive ? 2 : 1.5} />
              <span className="text-[10px] font-medium">{item.label}</span>
            </Link>
          );
        })}
      </div>

      {/* FAB Drawer - Menu Hành Động Nhanh */}
      <Drawer
        placement="bottom"
        onClose={() => setDrawerOpen(false)}
        open={drawerOpen}
        height="auto"
        closable={false}
        styles={{
          body: { padding: "24px 16px", background: "#f8fafc", borderRadius: "1.5rem 1.5rem 0 0" },
        }}
      >
        <div className="flex flex-col gap-4 text-center">
          <div className="w-12 h-1.5 bg-gray-300 rounded-full mx-auto mb-2 opacity-50" />
          
          <h3 className="text-lg font-semibold text-gray-800">Thao tác nhanh</h3>
          
          <div className="grid grid-cols-3 gap-3">
            <div className="flex flex-col items-center gap-2 cursor-pointer" onClick={() => window.dispatchEvent(new KeyboardEvent("keydown", { key: "k", ctrlKey: true }))}>
              <div className="w-12 h-12 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center">
                <Search size={20} />
              </div>
              <span className="text-xs font-medium text-gray-600">Tìm kiếm</span>
            </div>
            
            <Link to="/b2b/create-order" onClick={() => setDrawerOpen(false)} className="flex flex-col items-center gap-2">
              <div className="w-12 h-12 rounded-full bg-green-100 text-green-600 flex items-center justify-center">
                <Package size={20} />
              </div>
              <span className="text-xs font-medium text-gray-600">Tạo đơn</span>
            </Link>

            <Link to="/inventory/inbound" onClick={() => setDrawerOpen(false)} className="flex flex-col items-center gap-2">
              <div className="w-12 h-12 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center">
                <Download size={20} />
              </div>
              <span className="text-xs font-medium text-gray-600">Nhập kho</span>
            </Link>

            <Link to="/b2b/orders" onClick={() => setDrawerOpen(false)} className="flex flex-col items-center gap-2">
              <div className="w-12 h-12 rounded-full bg-purple-100 text-purple-600 flex items-center justify-center">
                <FileText size={20} />
              </div>
              <span className="text-xs font-medium text-gray-600">DS Bán B2B</span>
            </Link>
          </div>
        </div>
      </Drawer>
    </>
  );
};
