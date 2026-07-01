import { TablePaginationConfig } from "antd";
import { debounce } from "lodash";
import { useState, useEffect, useCallback } from "react";
import { useSearchParams, useLocation } from "react-router-dom";

export interface ListingParams {
  page?: number;
  pageSize?: number;
  search?: string;
  [key: string]: any;
}

interface UseListingLogicProps<T> {
  fetcher: (params: ListingParams) => Promise<{ data: T[]; total: number }>;
  defaultFilters?: Record<string, any>;
}

export function useListingLogic<T>({
  fetcher,
  defaultFilters = {},
}: UseListingLogicProps<T>) {
  const [searchParams, setSearchParams] = useSearchParams();

  // State quản lý dữ liệu
  const [data, setData] = useState<T[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);

  const location = useLocation();
  const storageKey = `listing_filters_${location.pathname}`;

  // State quản lý bộ lọc & phân trang
  const [filters, setFilters] = useState<ListingParams>(() => {
    // 1. Kiểm tra xem có params trên URL không
    const urlHasParams = Array.from(searchParams.keys()).length > 0;
    
    if (urlHasParams) {
      const params: ListingParams = {
        page: Number(searchParams.get("page")) || 1,
        pageSize: Number(searchParams.get("pageSize")) || 10,
        search: searchParams.get("search") || "",
        ...defaultFilters,
      };
      // Merge các filter khác từ URL
      searchParams.forEach((value, key) => {
        if (!["page", "pageSize", "search"].includes(key)) {
          params[key] = value;
        }
      });
      return params;
    }

    // 2. Thử khôi phục từ SessionStorage
    try {
      const saved = sessionStorage.getItem(storageKey);
      if (saved) {
        return JSON.parse(saved);
      }
    } catch (e) {
      console.error("Lỗi parse sessionStorage:", e);
    }

    // 3. Fallback về mặc định
    return {
      page: 1,
      pageSize: 10,
      search: "",
      ...defaultFilters,
    };
  });

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: resData, total: resTotal } = await fetcher(filters);
      setData(resData);
      setTotal(resTotal);
    } catch (error) {
      console.error("Lỗi tải dữ liệu:", error);
    } finally {
      setLoading(false);
    }
  }, [fetcher, filters]);

  // Sync URL và SessionStorage
  useEffect(() => {
    const urlParams: Record<string, string> = {};
    Object.keys(filters).forEach((key) => {
      if (filters[key]) urlParams[key] = String(filters[key]);
    });
    setSearchParams(urlParams, { replace: true });
    sessionStorage.setItem(storageKey, JSON.stringify(filters));
    fetchData();
  }, [filters, fetchData, setSearchParams, storageKey]);

  const handleTableChange = (pagination: TablePaginationConfig) => {
    setFilters((prev) => ({
      ...prev,
      page: pagination.current || 1,
      pageSize: pagination.pageSize || 10,
    }));
  };

  const handleSearch = useCallback(
    debounce((term: string) => {
      setFilters((prev) => ({ ...prev, search: term, page: 1 }));
    }, 500),
    []
  );

  const handleFilterChange = (key: string, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const refresh = () => fetchData();

  return {
    tableProps: {
      dataSource: data,
      loading: loading,
      pagination: {
        current: filters.page,
        pageSize: filters.pageSize,
        total: total,
        showSizeChanger: true,
      },
      onChange: handleTableChange,
    },
    filterProps: {
      initialSearch: filters.search,
      onSearch: handleSearch,
      onFilterChange: handleFilterChange,
      onRefresh: refresh,
    },
    filters, // <--- SENKO FIX: Đã thêm dòng này (Export biến filters)
    setFilters, // [NEW] Expose setFilters for complex filter logic
    refresh,
  };
}
