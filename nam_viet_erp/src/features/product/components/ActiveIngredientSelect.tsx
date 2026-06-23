import React, { useEffect } from "react";
import { Select } from "antd";
import { useActiveIngredientStore } from "@/features/inventory/stores/useActiveIngredientStore";

interface ActiveIngredientSelectProps {
  value?: number | string;
  onChange?: (value: number | string, option: any) => void;
  style?: React.CSSProperties;
  placeholder?: string;
}

export const ActiveIngredientSelect: React.FC<ActiveIngredientSelectProps> = ({
  value,
  onChange,
  style,
  placeholder = "Chọn hoạt chất...",
}) => {
  const { ingredients, loading, fetchIngredients } = useActiveIngredientStore();

  useEffect(() => {
    if (ingredients.length === 0) {
      fetchIngredients();
    } else if (value && !ingredients.some((item) => item.id === value)) {
      fetchIngredients();
    }
  }, [fetchIngredients, ingredients.length, value]);

  return (
    <Select
      showSearch
      value={value}
      placeholder={placeholder}
      style={style}
      onChange={onChange}
      loading={loading}
      filterOption={(input, option) =>
        (option?.label ?? "").toString().toLowerCase().includes(input.toLowerCase())
      }
      options={ingredients.map((item) => ({
        value: item.id,
        label: item.name,
      }))}
    />
  );
};
