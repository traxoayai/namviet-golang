export interface ActiveIngredient {
  id: number;
  name: string;
  name_intl?: string;
  slug?: string;
  atc_code?: string;
  description?: string; // This will store the JSON string of rich text
  status: "active" | "inactive";
  created_at?: string;
  updated_at?: string;
}

export interface ActiveIngredientFilter {
  search?: string;
  status?: "active" | "inactive";
}
