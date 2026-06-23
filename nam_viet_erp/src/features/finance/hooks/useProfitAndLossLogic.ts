import { useState, useEffect } from "react";
import dayjs from "dayjs";
import { supabase } from "@/shared/lib/supabaseClient";
import { App } from "antd";

export interface ProfitAndLossRow {
  item_code: string;
  item_name: string;
  current_period_amount: number;
  previous_period_amount: number;
}

export const useProfitAndLossLogic = () => {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<ProfitAndLossRow[]>([]);
  const [bookType, setBookType] = useState<"INTERNAL" | "TAX">("INTERNAL");
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().startOf("month"),
    dayjs().endOf("month"),
  ]);
  const { message } = App.useApp();

  const fetchProfitAndLoss = async () => {
    if (!dateRange || !dateRange[0] || !dateRange[1]) return;
    setLoading(true);
    try {
      // @ts-ignore
      const { data: pnlData, error } = await supabase.rpc("get_profit_and_loss", {
        p_start_date: dateRange[0].format("YYYY-MM-DD"),
        p_end_date: dateRange[1].format("YYYY-MM-DD"),
        p_book: bookType,
      });

      if (error) throw error;
      setData((pnlData as any) || []);
    } catch (err: any) {
      console.error(err);
      message.error("Lỗi khi tải Báo cáo KQKD: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfitAndLoss();
  }, [bookType, dateRange]);

  return {
    loading,
    data,
    bookType,
    setBookType,
    dateRange,
    setDateRange,
    fetchProfitAndLoss,
  };
};
