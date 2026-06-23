import { useState, useEffect } from "react";
import { supabase } from "@/shared/lib/supabaseClient";
import dayjs from "dayjs";
import { App } from "antd";

export interface LedgerRow {
  is_opening_balance: boolean;
  transaction_date: string;
  doc_id: string;
  doc_type: string;
  description: string;
  cor_account_code: string;
  debit: number;
  credit: number;
  running_balance: number;
}

export const useGeneralLedgerLogic = () => {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<LedgerRow[]>([]);
  const [accounts, setAccounts] = useState<any[]>([]);

  // Filters
  const [selectedAccount, setSelectedAccount] = useState<string | null>(null);
  const [bookType, setBookType] = useState<"INTERNAL" | "TAX">("INTERNAL");
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().startOf("month"),
    dayjs().endOf("month"),
  ]);

  // Fetch chart of accounts for dropdown
  useEffect(() => {
    const fetchAccounts = async () => {
      try {
        const { data: accData, error } = await supabase
          .from("chart_of_accounts")
          .select("id, account_code, name, type, balance_type")
          .order("account_code", { ascending: true });

        if (error) throw error;
        setAccounts(accData || []);
      } catch (err: any) {
        console.error("Error fetching accounts:", err);
      }
    };
    fetchAccounts();
  }, []);

  // Fetch Ledger Data
  const fetchLedger = async () => {
    if (!selectedAccount) {
      setData([]);
      return;
    }
    
    try {
      setLoading(true);
      const startDate = dateRange[0].format("YYYY-MM-DD");
      const endDate = dateRange[1].format("YYYY-MM-DD");

      // @ts-ignore
      const { data: ledgerData, error } = await supabase.rpc("get_general_ledger", {
        p_account_id: selectedAccount,
        p_start_date: startDate,
        p_end_date: endDate,
        p_book: bookType,
      });

      if (error) throw error;
      setData((ledgerData as any) || []);
    } catch (err: any) {
      console.error("Failed to fetch ledger:", err);
      message.error("Lỗi khi tải dữ liệu sổ cái: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLedger();
  }, [selectedAccount, bookType, dateRange]);

  return {
    loading,
    data,
    accounts,
    selectedAccount,
    setSelectedAccount,
    bookType,
    setBookType,
    dateRange,
    setDateRange,
    fetchLedger,
  };
};
