import React from "react";
import { ActiveIngredientSelect } from "./ActiveIngredientSelect";
import { useActiveIngredientStore } from "@/features/inventory/stores/useActiveIngredientStore";

interface ActiveIngredientJsonSelectProps {
  value?: string;
  onChange?: (value: string) => void;
  style?: React.CSSProperties;
  placeholder?: string;
}

export const ActiveIngredientJsonSelect: React.FC<ActiveIngredientJsonSelectProps> = ({
  value,
  onChange,
  style,
  placeholder,
}) => {
  const { ingredients } = useActiveIngredientStore();

  let parsedId: number | undefined;
  try {
    if (value) {
      const obj = JSON.parse(value);
      parsedId = obj.id;
    }
  } catch (e) {
    // Legacy support if it was just text or ID
    parsedId = Number(value);
    if (isNaN(parsedId)) parsedId = undefined;
  }

  const handleChange = (id: number | string) => {
    if (!onChange) return;
    const item = ingredients.find((i) => i.id === id);
    if (item) {
      onChange(JSON.stringify({ id: item.id, name: item.name }));
    } else {
      onChange("");
    }
  };

  return (
    <ActiveIngredientSelect
      value={parsedId}
      onChange={handleChange}
      style={style}
      placeholder={placeholder}
    />
  );
};
