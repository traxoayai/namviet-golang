import { create } from "zustand";
import { ActiveIngredient, ActiveIngredientFilter } from "../types/activeIngredient";
import { activeIngredientService } from "../api/activeIngredientService";

interface ActiveIngredientState {
  ingredients: ActiveIngredient[];
  loading: boolean;
  error: string | null;
  fetchIngredients: (filter?: ActiveIngredientFilter) => Promise<void>;
  createIngredient: (data: Partial<ActiveIngredient>) => Promise<void>;
  updateIngredient: (id: number, data: Partial<ActiveIngredient>) => Promise<void>;
  deleteIngredient: (id: number) => Promise<void>;
}

export const useActiveIngredientStore = create<ActiveIngredientState>((set) => ({
  ingredients: [],
  loading: false,
  error: null,

  fetchIngredients: async (filter) => {
    set({ loading: true, error: null });
    try {
      const data = await activeIngredientService.getIngredients(filter);
      set({ ingredients: data });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  createIngredient: async (data) => {
    try {
      const newItem = await activeIngredientService.createIngredient(data);
      set((state) => ({ ingredients: [...state.ingredients, newItem] }));
    } catch (error: any) {
      throw error;
    }
  },

  updateIngredient: async (id, data) => {
    try {
      const updatedItem = await activeIngredientService.updateIngredient(id, data);
      set((state) => ({
        ingredients: state.ingredients.map((item) =>
          item.id === id ? updatedItem : item
        ),
      }));
    } catch (error: any) {
      throw error;
    }
  },

  deleteIngredient: async (id) => {
    try {
      await activeIngredientService.deleteIngredient(id);
      set((state) => ({
        ingredients: state.ingredients.filter((item) => item.id !== id),
      }));
    } catch (error: any) {
      throw error;
    }
  },
}));
