import { supabase } from "@/shared/lib/supabaseClient";
import { ActiveIngredient, ActiveIngredientFilter } from "../types/activeIngredient";

export const activeIngredientService = {
  async getIngredients(filter?: ActiveIngredientFilter) {
    let query = (supabase as any)
      .from("active_ingredients")
      .select("*")
      .limit(10000)
      .order("name", { ascending: true });

    if (filter?.search) {
      query = query.ilike("name", `%${filter.search}%`);
    }

    if (filter?.status) {
      query = query.eq("status", filter.status);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data as ActiveIngredient[];
  },

  async createIngredient(data: Partial<ActiveIngredient>) {
    const { data: result, error } = await (supabase as any)
      .from("active_ingredients")
      .insert([
        {
          ...data,
          slug: data.name?.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, ''),
        }
      ])
      .select()
      .single();
    if (error) throw error;
    return result as ActiveIngredient;
  },

  async updateIngredient(id: number, data: Partial<ActiveIngredient>) {
    const { data: result, error } = await (supabase as any)
      .from("active_ingredients")
      .update(data)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return result as ActiveIngredient;
  },

  async deleteIngredient(id: number) {
    const { error } = await (supabase as any)
      .from("active_ingredients")
      .delete()
      .eq("id", id);
    if (error) throw error;
  },
};
