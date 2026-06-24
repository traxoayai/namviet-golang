// src/features/sales-b2b/create/hooks/useCreateOrderB2B.ts
import { message } from "antd";
import dayjs from "dayjs";
import customParseFormat from "dayjs/plugin/customParseFormat";
import { useCallback, useMemo, useState, useEffect } from "react";

import { useShippingPartnerStore } from "@/features/partners/stores/useShippingPartnerStore";
// QUAN TRỌNG: Import Type chuẩn từ shippingPartner để đồng bộ với Store
import { ShippingPartner } from "@/features/partners/types/shippingPartner";
import { useSalesStore } from "@/features/sales/stores/useSalesStore";
import { PromotionRule, AdvancedRule, CartItem } from "@/features/sales/types/b2b_sales";
import { DELIVERY_METHODS } from "@/shared/constants/b2b";
import { isOverCreditLimit } from "@/shared/lib/creditLimitCheck";

dayjs.extend(customParseFormat);

export const useCreateOrderB2B = () => {
  const store = useSalesStore();
  const shippingStore = useShippingPartnerStore();

  // --- 1. LOGIC TÀI CHÍNH (FINANCIALS) ---
  const financials = useMemo(() => {
    const summary = store.getSummary();
    const isOverLimit = store.customer
      ? isOverCreditLimit({
          debtLimit: store.customer.debt_limit,
          currentDebt: store.customer.current_debt,
          orderAmount: summary.totalPayable,
        })
      : false;

    return {
      ...summary,
      // LƯU Ý: summary.totalPayable = finalTotal + oldDebt (đã bao gồm current_debt rồi).
      // KHÔNG cộng current_debt thêm lần nữa — sẽ bị double-count (2 × current_debt + finalTotal).
      newTotalDebt: Number(summary.totalPayable) || 0,
      isOverLimit,
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- Zustand store ref ổn định, không cần trong deps
  }, [store.items, store.shippingFee, store.selectedVoucher, store.customer]);

  // --- 2. LOGIC VẬN CHUYỂN (SMART DELIVERY ESTIMATOR) ---
  const estimatedDeliveryText = useMemo(() => {
    if (store.deliveryMethod === "internal") return "Giao trong giờ hành chính";

    const partner = store.shippingPartner;
    if (!partner) return "Chưa có thông tin";

    const now = dayjs();
    const todayStr = now.format("YYYY-MM-DD");

    // Parse Cut-off time (VD: "16:00:00")
    // Fallback về 16:00 nếu không có dữ liệu
    const cutOffTimeStr = partner.cut_off_time || "16:00:00";
    const cutOff = dayjs(`${todayStr} ${cutOffTimeStr}`, "YYYY-MM-DD HH:mm:ss");

    let baseTime = now;
    // Nếu quá giờ chốt đơn -> Tính từ 8:00 AM sáng mai
    if (now.isAfter(cutOff)) {
      baseTime = now.add(1, "day").hour(8).minute(0).second(0);
    }

    // Cộng thời gian giao hàng (speed_hours) - Fallback 24h nếu thiếu
    const speed = partner.speed_hours || 24;
    const estimatedTime = baseTime.add(speed, "hour");

    const diffHours = estimatedTime.diff(now, "hour");

    if (diffHours < 24 && estimatedTime.isSame(now, "day")) {
      return `Dự kiến giao: ${estimatedTime.format("HH:mm")} Hôm nay`;
    }
    return `Dự kiến giao: ${estimatedTime.format("DD/MM/YYYY")} (khoảng ${Math.ceil(diffHours / 24)} ngày)`;
  }, [store.deliveryMethod, store.shippingPartner]);

  // --- 3. ACTIONS (XỬ LÝ LOGIC UI) ---

  // FIX LỖI TYPE MISMATCH: Mapping từ ListRecord -> Full Partner Object
  const selectShippingPartner = useCallback(
    (partnerId: number) => {
      const listRecord = shippingStore.partners.find((p) => p.id === partnerId);

      if (listRecord) {
        // Tạo object đầy đủ để thỏa mãn interface ShippingPartner
        const fullPartner: ShippingPartner = {
          ...listRecord,
          email: null, // Bổ sung field thiếu
          address: null, // Bổ sung field thiếu
          notes: null, // Bổ sung field thiếu
          // speed_hours và base_fee đã có trong ListRecord (nhờ cập nhật Type ở Bước 2)
          // Nếu ListRecord chưa có, cần fallback tại đây:
          speed_hours: listRecord.speed_hours || 24,
          base_fee: listRecord.base_fee || 0,
        };

        store.setShippingPartner(fullPartner);
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps -- Zustand store ref ổn định, không cần trong deps
    [shippingStore.partners, store.setShippingPartner]
  );

  const validateOrder = useCallback(() => {
    if (!store.customer) {
      message.error("Vui lòng chọn Khách hàng!");
      return false;
    }
    if (store.items.length === 0) {
      message.error("Giỏ hàng đang trống!");
      return false;
    }
    if (store.deliveryMethod !== "internal" && !store.shippingPartner) {
      message.error("Vui lòng chọn Đối tác vận chuyển!");
      return false;
    }
    if (store.deliveryMethod !== "coach" && !store.customer.shipping_address) {
      message.warning(
        "Khách hàng này chưa có địa chỉ giao hàng! Vui lòng kiểm tra lại."
      );
    }
    return true;
  }, [
    store.customer,
    store.items,
    store.deliveryMethod,
    store.shippingPartner,
  ]);

  // --- 4. B2B UPSELL PROMOTION (AUTO-SUGGEST) ---
  const [promoRules, setPromoRules] = useState<PromotionRule[]>([]);

  useEffect(() => {
    // Fetch active rules
    const fetchRules = async () => {
      try {
        const { default: axiosClient } = await import("@/shared/utils/axiosClient");
        const res = await axiosClient.get("/api/v1/promotions/auto-suggest");
        if (res.data) {
          setPromoRules(res.data);
        }
      } catch (err) {
        console.error("Failed to fetch auto-suggest rules", err);
      }
    };
    fetchRules();
  }, []);

  // Intercept updateItem
  const handleUpdateItem = useCallback(
    (key: string, field: keyof CartItem, value: any) => {
      // Đầu tiên, cập nhật item như bình thường bằng cách tính toán mảng mới
      const currentItems = store.items;
      let newItems = currentItems.map((item) => {
        if (item.key !== key) return item;
        const updated = { ...item, [field]: value };
        // Tính lại tổng tiền
        updated.total = updated.quantity * updated.price_wholesale - updated.discount;
        return updated;
      });

      // Kiểm tra Kịch bản Auto-Add Gift
      if (field === "quantity" && promoRules.length > 0) {
        promoRules.forEach((rule) => {
          if (!rule.advanced_rules) return;
          try {
            const advanced = JSON.parse(rule.advanced_rules) as AdvancedRule;
            const cond = advanced.condition;
            const rew = advanced.reward;

            if (cond.type === "buy_quantity") {
              const targetId = cond.target_product_id;
              
              // Tính tổng quantity của target product trong giỏ
              let cartQuantity = 0;
              newItems.forEach((item) => {
                if (item.id === targetId && !item.is_gift) {
                  cartQuantity += item.quantity;
                }
              });

              // Tính toán số lần đạt chuẩn (times)
              let times = 0;
              if (cond.min_quantity && cartQuantity >= cond.min_quantity) {
                times = advanced.is_multiply ? Math.floor(cartQuantity / cond.min_quantity) : 1;
              }

              const giftKey = `gift_${rule.id}_${rew.gift_product_id}`;

              // Map gift info to TARGET ITEM (so UI can show upsell text)
              newItems = newItems.map((item) => {
                if (item.id === targetId && !item.is_gift) {
                  return {
                    ...item,
                    gift_rule_id: rule.id,
                    gift_value: rew.gift_value || 0,
                  };
                }
                return item;
              });

              if (times > 0) {
                // Kiểm tra xem quà tặng đã tồn tại trong giỏ chưa
                const giftIndex = newItems.findIndex((i) => i.key === giftKey);
                const expectedQty = rew.gift_quantity * times;

                if (giftIndex >= 0) {
                  // Cập nhật số lượng quà
                  newItems[giftIndex].quantity = expectedQty;
                  newItems[giftIndex].total = 0; // Giá quà luôn = 0
                } else {
                  // Find main product to mock image if it's buy A get A
                  const mainProduct = newItems.find((i) => i.id === rew.gift_product_id && !i.is_gift);
                  
                  // Thêm quà tặng mới
                  newItems.push({
                    id: rew.gift_product_id,
                    key: giftKey,
                    name: mainProduct ? mainProduct.name : (rew.gift_name || "Quà Tặng"),
                    sku: mainProduct ? `${mainProduct.sku}-GIFT` : "GIFT",
                    price_wholesale: 0,
                    quantity: expectedQty,
                    discount: 0,
                    total: 0,
                    image_url: mainProduct ? mainProduct.image_url : null,
                    lot_number: null,
                    expiry_date: null,
                    wholesale_unit: mainProduct ? mainProduct.wholesale_unit : "Cái",
                    items_per_carton: 1,
                    stock_quantity: 999, // Không quan trọng
                    shelf_location: "",
                    is_gift: true,
                    gift_rule_id: rule.id,
                    gift_value: rew.gift_value || 0,
                  } as CartItem);
                  message.success(`Đã tự động thêm quà: ${rew.gift_name}`);
                }
              } else {
                // Remove gift nếu không đủ điều kiện
                newItems = newItems.filter((i) => i.key !== giftKey);
              }
            }
          } catch (e) {
            console.error("Lỗi parse JSON rules", e);
          }
        });
      }

      store.setItems(newItems);
    },
    [store.items, promoRules, store.setItems]
  );

  return {
    // State Exports
    customer: store.customer,
    items: store.items,
    deliveryMethod: store.deliveryMethod,
    shippingPartnerId: store.shippingPartner?.id,
    shippingFee: store.shippingFee,
    note: store.note,
    selectedVoucher: store.selectedVoucher,

    // Computed Exports
    financials,
    estimatedDeliveryText,
    deliveryMethods: DELIVERY_METHODS,

    // Action Exports
    setCustomer: store.setCustomer,
    setItems: store.setItems, // [NEW]
    addItem: store.addItem,
    updateItem: handleUpdateItem, // [MODIFIED TO INTERCEPT]
    removeItem: store.removeItem,
    setDeliveryMethod: store.setDeliveryMethod,
    selectShippingPartner,
    setNote: store.setNote,
    setVoucher: store.setVoucher,

    // FIX: Dùng action setShippingFee thay vì setState
    setShippingFee: store.setShippingFee,
    setManualDiscount: store.setManualDiscount, // [NEW]

    reset: store.reset,
    validateOrder,
  };
};
