// src/features/booking/api/bookingService.ts
import { safeRpc } from "@/shared/lib/safeRpc";
import type { Json } from "@/shared/types/database.types";

export interface BookingPayload {
  customer_id: number;
  doctor_id?: string; // UUID string
  appointment_time: string; // ISO string
  symptoms: Json[];
  notes?: string;
  description?: string;
  status?: "confirmed" | "pending";
}

export interface CheckInPayload {
  customer_id: number;
  doctor_id?: string; // UUID string
  priority: "normal" | "urgent";
  symptoms: Json[];
  notes?: string;
}

export const bookingService = {
  /**
   * Tạo lịch hẹn mới via RPC
   */
  createBooking: async (payload: BookingPayload) => {
    // Sanitize doctor_id: ensure empty string becomes null
    const doctorId =
      payload.doctor_id && payload.doctor_id.trim() !== ""
        ? payload.doctor_id
        : undefined;

    const { default: axiosClient } = await import("@/shared/utils/axiosClient");
    const { data } = await axiosClient.post("/api/v1/clinic/appointments", {
      patient_id: payload.customer_id,
      doctor_id: doctorId ? Number(doctorId) : 0, // Fallback to 0 if not provided
      appointment_time: payload.appointment_time,
      service_type: "examination",
    });

    return data?.id; // Returns appointment_id
  },

  /**
   * Check-in ngay vào Clinical Queue via RPC
   */
  checkInNow: async (payload: CheckInPayload) => {
    // 1. Tạo cuộc hẹn trước
    const appointmentId = await bookingService.createBooking({
      customer_id: payload.customer_id,
      doctor_id: payload.doctor_id,
      appointment_time: new Date().toISOString(),
      symptoms: payload.symptoms,
      notes: payload.notes,
      status: "confirmed",
    });

    if (!appointmentId) {
      throw new Error("Không thể tạo cuộc hẹn để check-in");
    }

    // 2. Gọi API Check-in
    const { default: axiosClient } = await import("@/shared/utils/axiosClient");
    const { data } = await axiosClient.post(`/api/v1/clinic/appointments/${appointmentId}/check-in`, {
      notes: payload.notes || "",
    });

    return data; // Returns queue information
  },
};
