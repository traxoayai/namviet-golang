/**
 * Tiện ích xử lý URL Cloudinary
 * Tự động thêm tham số f_auto (tự động chọn định dạng webp/avif) 
 * và q_auto (tự động nén chất lượng) để tối ưu dung lượng ảnh
 */

export const getOptimizedCloudinaryUrl = (originalUrl: string): string => {
  if (!originalUrl) return '';
  
  // Nếu url không phải từ cloudinary, trả về nguyên bản
  if (!originalUrl.includes('cloudinary.com')) {
    return originalUrl;
  }

  // Nếu url đã có chứa f_auto hoặc q_auto rồi thì không chèn thêm nữa
  if (originalUrl.includes('f_auto') || originalUrl.includes('q_auto')) {
    return originalUrl;
  }

  // Chèn f_auto,q_auto vào sau thư mục 'upload/'
  return originalUrl.replace('upload/', 'upload/f_auto,q_auto/');
};

/**
 * Upload ảnh trực tiếp lên Cloudinary từ client sử dụng Web Crypto API để ký (sign) request.
 */
export const uploadImageToCloudinary = async (file: File): Promise<string> => {
  const envUrl = import.meta.env.VITE_CLOUDINARY_URL || "";
  const regex = /cloudinary:\/\/([^:]+):([^@]+)@(.+)/;
  const match = envUrl.match(regex);

  if (!match) {
    throw new Error("Không tìm thấy cấu hình VITE_CLOUDINARY_URL hợp lệ trong .env");
  }

  const [, apiKey, apiSecret, cloudName] = match;
  const timestamp = Math.round(new Date().getTime() / 1000).toString();

  // Tạo chữ ký (signature) theo chuẩn Cloudinary: sha1(timestamp + apiSecret)
  const signatureString = `timestamp=${timestamp}${apiSecret}`;
  const msgBuffer = new TextEncoder().encode(signatureString);
  const hashBuffer = await crypto.subtle.digest("SHA-1", msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const signature = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

  const formData = new FormData();
  formData.append("file", file);
  formData.append("api_key", apiKey);
  formData.append("timestamp", timestamp);
  formData.append("signature", signature);

  const res = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/image/upload`, {
    method: "POST",
    body: formData,
  });

  if (!res.ok) {
    const errorData = await res.json();
    throw new Error(errorData.error?.message || "Tải ảnh lên Cloudinary thất bại");
  }

  const data = await res.json();
  return getOptimizedCloudinaryUrl(data.secure_url);
};
