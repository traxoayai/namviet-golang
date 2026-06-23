import { useState, useEffect } from "react";
import dayjs from "dayjs";
import { supabase } from "@/shared/lib/supabaseClient";
import { App } from "antd";

export interface TrialBalanceRow {
  account_id: string;
  account_code: string;
  account_name: string;
  balance_type: string;
  opening_debit: number;
  opening_credit: number;
  period_debit: number;
  period_credit: number;
  closing_debit: number;
  closing_credit: number;
}

export const useTrialBalanceLogic = () => {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<TrialBalanceRow[]>([]);
  const [bookType, setBookType] = useState<"INTERNAL" | "TAX">("INTERNAL");
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().startOf("month"),
    dayjs().endOf("month"),
  ]);
  const { message } = App.useApp();

  const fetchTrialBalance = async () => {
    if (!dateRange || !dateRange[0] || !dateRange[1]) return;
    setLoading(true);
    try {
      // @ts-ignore
      const { data: tbData, error } = await supabase.rpc("get_trial_balance", {
        p_start_date: dateRange[0].format("YYYY-MM-DD"),
        p_end_date: dateRange[1].format("YYYY-MM-DD"),
        p_book: bookType,
      });

      if (error) throw error;
      setData((tbData as any) || []);
    } catch (err: any) {
      console.error(err);
      message.error("Lỗi khi tải Bảng cân đối số phát sinh: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTrialBalance();
  }, [bookType, dateRange]);

  return {
    loading,
    data,
    bookType,
    setBookType,
    dateRange,
    setDateRange,
    fetchTrialBalance,
  };
};
