import { message } from "antd";
import { useState, useEffect } from "react";
import { useQuery, useQueryClient, keepPreviousData } from "@tanstack/react-query";

import { PurchaseOrderMaster, PoLogisticsStat, PurchaseOrderFilters } from "../types/purchase";

import { supabase } from "@/shared/lib/supabaseClient";
import { safeRpc } from "@/shared/lib/safeRpc";
import type { Database } from "@/shared/lib/database.types";

export const usePurchaseOrderMaster = () => {
  const queryClient = useQueryClient();

  // --- LOCAL STATE (Filters & Pagination) ---
  const [pagination, setPagination] = useState({
    page: 1,
    pageSize: 12,
    total: 0,
  });
  const [filters, setFiltersRaw] = useState<PurchaseOrderFilters>({});

  // Wrapper: reset về page 1 mỗi khi filter thay đổi
  const setFilters = (newFilters: typeof filters) => {
    setFiltersRaw(newFilters);
    setPagination((prev) => ({ ...prev, page: 1 }));
  };

  // --- TANSTACK QUERY: FETCH ORDERS ---
  const { 
    data: ordersData, 
    isPending: isOrdersLoading, 
    refetch: refetchOrders 
  } = useQuery({
    queryKey: ["purchaseOrders", filters, pagination.page, pagination.pageSize],
    queryFn: async () => {
      const statusFilter = filters.status || "";

      let p_status: string | null = null;
      let p_status_delivery: string | null = null;
      let p_status_payment: string | null = null;

      if (statusFilter.startsWith("delivery:")) {
        p_status_delivery = statusFilter.replace("delivery:", "");
      } else if (statusFilter.startsWith("payment:")) {
        p_status_payment = statusFilter.replace("payment:", "");
      } else if (statusFilter) {
        p_status = statusFilter;
      }

      const rpcParams: Record<string, unknown> = {
        p_page: pagination.page,
        p_page_size: pagination.pageSize,
        p_search: filters.search || "",
        p_status_delivery: p_status_delivery || "",
        p_status_payment: p_status_payment || "",
      };
      if (p_status) rpcParams.p_status = p_status;
      if (filters.dateRange?.[0]) rpcParams.p_date_from = filters.dateRange[0];
      if (filters.dateRange?.[1]) rpcParams.p_date_to = filters.dateRange[1];

      const { data: rpcData } = await safeRpc(
        "get_purchase_orders_master",
        rpcParams as Database["public"]["Functions"]["get_purchase_orders_master"]["Args"],
      );

      const totalRows = rpcData && rpcData.length > 0 ? rpcData[0].full_count : 0;
      return { 
        orders: (rpcData || []) as PurchaseOrderMaster[], 
        totalRows 
      };
    },
    placeholderData: keepPreviousData, // Giữ data cũ mượt mà trong lúc load trang mới
  });

  // Đồng bộ `totalRows` từ API vào state `pagination` để giao diện phân trang AntD render đúng
  useEffect(() => {
    if (ordersData?.totalRows !== undefined) {
      setPagination((prev) => prev.total === ordersData.totalRows ? prev : { ...prev, total: ordersData.totalRows });
    }
  }, [ordersData?.totalRows]);

  // --- TANSTACK QUERY: FETCH STATS ---
  const { data: statsData } = useQuery({
    queryKey: ["purchaseOrderStats", filters], // Thống kê độc lập với trang (pagination)
    queryFn: async () => {
      const statusFilter = filters.status || "";
      let statsDelivery: string | null = null;
      let statsPayment: string | null = null;
      if (statusFilter.startsWith("delivery:")) {
        statsDelivery = statusFilter.replace("delivery:", "");
      } else if (statusFilter.startsWith("payment:")) {
        statsPayment = statusFilter.replace("payment:", "");
      } else if (statusFilter) {
        statsDelivery = statusFilter;
      }

      const { data } = await safeRpc("get_po_logistics_stats", {
        p_search: filters.search ?? undefined,
        p_status_delivery: statsDelivery ?? undefined,
        p_status_payment: statsPayment ?? undefined,
        p_date_from: filters.dateRange?.[0] ?? undefined,
        p_date_to: filters.dateRange?.[1] ?? undefined,
      });

      return (data || []) as PoLogisticsStat[];
    },
  });

  // --- TƯƠNG THÍCH NGƯỢC (BACKWARD COMPATIBILITY) ---
  // Giao diện (UI) đang gọi fetchOrders theo cách cũ, ta chuyển hướng sang TanStack
  const fetchOrders = async () => { await refetchOrders(); };

  // --- SUPABASE REALTIME (WEBSOCKETS) ---
  // Tự động invalidate Cache ngay khi Database có sự thay đổi
  useEffect(() => {
    const channel = supabase
      .channel("po_master_changes_v2")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "purchase_orders" },
        () => {
          // Báo cho TanStack Query biết Data đã cũ, hãy gọi ngầm API để lấy mới!
          queryClient.invalidateQueries({ queryKey: ["purchaseOrders"] });
          queryClient.invalidateQueries({ queryKey: ["purchaseOrderStats"] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [queryClient]);

  // --- CRUD OPERATORS ---
  const deleteOrder = async (id: number) => {
    try {
      const { error } = await supabase
        .from("purchase_orders")
        .delete()
        .eq("id", id);
      if (error) throw error;
      message.success("Đã xóa đơn hàng");
      // UI refresh: Invalidate cache để tự fetch lại, không cần gọi hàm fetch thủ công
      queryClient.invalidateQueries({ queryKey: ["purchaseOrders"] });
      queryClient.invalidateQueries({ queryKey: ["purchaseOrderStats"] });
    } catch {
      message.error("Không thể xóa đơn hàng");
    }
  };

  const bulkDeleteOrders = async (ids: number[]) => {
    try {
      const { error } = await supabase
        .from("purchase_orders")
        .delete()
        .in("id", ids)
        .in("status", ["DRAFT", "draft"])
        .or("delivery_status.eq.pending,delivery_status.is.null,delivery_status.eq.draft");
      if (error) throw error;
      message.success(`Đã xóa ${ids.length} đơn hàng`);
      queryClient.invalidateQueries({ queryKey: ["purchaseOrders"] });
      queryClient.invalidateQueries({ queryKey: ["purchaseOrderStats"] });
    } catch {
      message.error("Lỗi khi xóa hàng loạt");
    }
  };

  const updateLogistics = async (id: number) => {
    message.info(`TODO: Cập nhật vận chuyển cho ID ${id}`);
  };

  const autoCreate = async () => {
    try {
      message.loading({
        content: "Đang tính toán dự trù...",
        key: "auto_create",
      });
      const { default: axiosClient } = await import("@/shared/utils/axiosClient");
      const response = await axiosClient.post("/api/v1/purchasing/auto-replenish-min-max");
      
      message.success({
        content: `Đã tạo ${response.data.created_po_count} đơn hàng dự trù!`,
        key: "auto_create",
      });
      queryClient.invalidateQueries({ queryKey: ["purchaseOrders"] });
      queryClient.invalidateQueries({ queryKey: ["purchaseOrderStats"] });
      
      return response.data;
    } catch (error) {
      console.error("Auto Replenish Error:", error);
      message.error({ content: "Lỗi tạo đơn tự động", key: "auto_create" });
      return null;
    }
  };

  return {
    orders: ordersData?.orders || [],
    logisticsStats: statsData || [],
    loading: isOrdersLoading, // Chỉ hiển thị spinner lần tải đầu tiên, các lần sau fetch ngầm cực mượt
    pagination,
    setPagination,
    filters,
    setFilters,
    fetchOrders,
    deleteOrder,
    bulkDeleteOrders,
    updateLogistics,
    autoCreate,
  };
};
