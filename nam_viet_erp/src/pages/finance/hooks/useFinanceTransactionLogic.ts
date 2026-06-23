// src/pages/finance/hooks/useFinanceTransactionLogic.ts
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState, useEffect } from "react";

import { financeService } from "@/features/finance/api/financeService";
import { useFinanceStore } from "@/features/finance/stores/useFinanceStore";

export const useFinanceTransactionLogic = () => {
  const queryClient = useQueryClient();
  const {
    funds,
    page,
    pageSize,
    fetchFunds,
    setFilters,
    filters,
    setPage,
    postTransactionsToGL,
  } = useFinanceStore();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalFlow, setModalFlow] = useState<"in" | "out">("in");

  useEffect(() => {
    fetchFunds();
  }, [fetchFunds]);

  const { data, isLoading: loading, refetch } = useQuery({
    queryKey: ["finance_transactions", page, pageSize, filters],
    queryFn: () =>
      financeService.getTransactions({
        page,
        pageSize,
        ...filters,
      }),
  });

  const transactions = data?.data || [];
  const totalCount = data?.totalCount || 0;

  const openCreateModal = (flow: "in" | "out") => {
    setModalFlow(flow);
    setIsModalOpen(true);
  };

  const totalBalance = funds.reduce(
    (sum, f) => sum + (Number(f.balance) || 0),
    0
  );

  return {
    transactions,
    funds,
    loading,
    totalCount,
    page,
    pageSize,
    setFilters,
    filters,
    setPage,
    fetchTransactions: () => {
      queryClient.invalidateQueries({ queryKey: ["finance_transactions"] });
      refetch();
    },
    isModalOpen,
    setIsModalOpen,
    modalFlow,
    openCreateModal,
    totalBalance,
    postTransactionsToGL,
  };
};
