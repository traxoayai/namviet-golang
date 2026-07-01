import React, { useState, useEffect, useRef } from "react";
import { Modal, Input, List } from "antd";
import { Search, ChevronRight } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { MENU_DATA, MenuConfigItem } from "@/config/menu.config";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";

// Đệ quy để flatten menu thành mảng 1 chiều có path cha
const flattenMenu = (
  items: MenuConfigItem[],
  parentName = ""
): (MenuConfigItem & { fullName: string })[] => {
  let result: (MenuConfigItem & { fullName: string })[] = [];
  items.forEach((item) => {
    const currentName = parentName ? `${parentName} > ${item.name}` : item.name;
    if (item.href) {
      result.push({ ...item, fullName: currentName });
    }
    if (item.children) {
      result = result.concat(flattenMenu(item.children, currentName));
    }
  });
  return result;
};

const ALL_SEARCHABLE_ITEMS = flattenMenu(MENU_DATA);

export const GlobalSearchModal: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const navigate = useNavigate();
  const inputRef = useRef<any>(null);
  
  const { permissions } = useAuthStore();

  // Lọc kết quả tìm kiếm và kiểm tra quyền
  const filteredItems = ALL_SEARCHABLE_ITEMS.filter((item) => {
    // Check permission
    if (item.requiredPermissions) {
      const hasPerm =
        item.requiredPermissions.some((p) => permissions.includes(p)) ||
        permissions.includes("admin-all");
      if (!hasPerm) return false;
    }
    // Check search term
    return item.fullName.toLowerCase().includes(searchTerm.toLowerCase());
  }).slice(0, 10); // Lấy top 10

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Bắt Ctrl+K hoặc Cmd+K
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen(true);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 100);
      setSearchTerm("");
      setActiveIndex(0);
    }
  }, [open]);

  const handleKeyDownList = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setActiveIndex((prev) => Math.min(prev + 1, filteredItems.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActiveIndex((prev) => Math.max(prev - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (filteredItems[activeIndex]) {
        handleSelect(filteredItems[activeIndex].href!);
      }
    }
  };

  const handleSelect = (href: string) => {
    navigate(href);
    setOpen(false);
  };

  return (
    <Modal
      open={open}
      onCancel={() => setOpen(false)}
      footer={null}
      closable={false}
      bodyStyle={{ padding: 0 }}
      width={600}
      style={{ top: 100 }} // Đẩy lên cao một chút
    >
      <div onKeyDown={handleKeyDownList} className="flex flex-col">
        <div className="flex items-center px-4 py-3 border-b border-gray-100">
          <Search className="text-gray-400 mr-3" size={20} />
          <Input
            ref={inputRef}
            placeholder="Tìm kiếm chức năng, báo cáo (Nhấn mũi tên để chọn)..."
            bordered={false}
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setActiveIndex(0);
            }}
            className="flex-1 text-lg placeholder-gray-300"
            style={{ boxShadow: "none", padding: 0 }}
          />
          <div className="text-xs text-gray-400 bg-gray-50 px-2 py-1 rounded">ESC</div>
        </div>
        
        {searchTerm && (
          <List
            className="max-h-96 overflow-y-auto"
            dataSource={filteredItems}
            renderItem={(item, index) => {
              const isActive = index === activeIndex;
              return (
                <List.Item
                  className={`px-4 py-3 cursor-pointer transition-colors ${
                    isActive ? "bg-blue-50 border-l-4 border-blue-500" : "hover:bg-gray-50 border-l-4 border-transparent"
                  }`}
                  onClick={() => handleSelect(item.href!)}
                >
                  <div className="flex items-center justify-between w-full">
                    <span className={`${isActive ? "text-blue-600 font-medium" : "text-gray-700"}`}>
                      {item.fullName}
                    </span>
                    <ChevronRight size={16} className={isActive ? "text-blue-500" : "text-gray-300"} />
                  </div>
                </List.Item>
              );
            }}
            locale={{ emptyText: "Không tìm thấy chức năng phù hợp" }}
          />
        )}
      </div>
    </Modal>
  );
};
