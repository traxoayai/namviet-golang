/**
 * src/shared/utils/printUtils.ts
 * Nâng cấp kiến trúc in ấn: Sử dụng Hidden Iframe thay vì window.open
 * Giúp trải nghiệm in mượt mà, không chớp màn hình, không bị Popup Blocker chặn.
 */

export const printHTML = (htmlContent: string) => {
  const printWindow = openPrintWindow();
  if (!printWindow) {
    alert("Không thể khởi tạo tiến trình in.");
    return;
  }
  renderAndPrint(printWindow, htmlContent);
};

/**
 * Mở cửa sổ in (Thực chất là tạo một Iframe tàng hình nhúng vào trang)
 * Vẫn giữ nguyên tên hàm để tương thích ngược với các file React cũ.
 */
export const openPrintWindow = (): Window | null => {
  // Tạo iframe tàng hình
  const iframe = document.createElement("iframe");
  // Đặt ID ngẫu nhiên để dễ quản lý nếu gọi in liên tục
  iframe.id = `print-iframe-${Date.now()}`;
  iframe.style.position = "fixed";
  iframe.style.right = "-9999px";
  iframe.style.bottom = "-9999px";
  iframe.style.width = "0px";
  iframe.style.height = "0px";
  iframe.style.border = "none";

  // Nhúng vào body
  document.body.appendChild(iframe);

  const printWindow = iframe.contentWindow;
  if (!printWindow) return null;

  return printWindow;
};

/**
 * Đổ dữ liệu vào Iframe và kích hoạt lệnh in một cách an toàn
 */
export const renderAndPrint = (printWindow: Window, htmlContent: string) => {
  // 1. Ghi mã HTML vào iframe
  printWindow.document.open();
  printWindow.document.write(htmlContent);
  printWindow.document.close();

  // Lấy ra thẻ iframe gốc từ đối tượng Window để lát dọn rác
  const frameElement = printWindow.frameElement as HTMLIFrameElement;

  // Hàm thực thi in và dọn dẹp
  const executePrint = () => {
    printWindow.focus();
    printWindow.print();

    // DỌN RÁC: Xóa iframe sau khi in để giải phóng RAM cho trình duyệt
    setTimeout(() => {
      if (frameElement && document.body.contains(frameElement)) {
        document.body.removeChild(frameElement);
      }
    }, 1000);
  };

  // 2. Kích hoạt in thông minh (Chờ tải xong ảnh, QR Code)
  const images = printWindow.document.getElementsByTagName("img");

  if (images.length > 0) {
    let imagesLoaded = 0;
    for (let i = 0; i < images.length; i++) {
      // Khi ảnh tải thành công
      images[i].onload = () => {
        imagesLoaded++;
        if (imagesLoaded === images.length) executePrint();
      };
      // Khi ảnh lỗi (mất mạng) -> Bỏ qua và vẫn ép in
      images[i].onerror = () => {
        imagesLoaded++;
        if (imagesLoaded === images.length) executePrint();
      };
    }
  } else {
    // Nếu hóa đơn không có ảnh, in ngay lập tức
    setTimeout(executePrint, 50);
  }
};
