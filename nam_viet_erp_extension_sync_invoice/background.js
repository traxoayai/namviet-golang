chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "FORWARD_TO_ERP") {
    // Tìm tab của Nam Việt ERP đang mở
    chrome.tabs.query(
      {
        url: [
          "http://localhost:*/*",
          "http://127.0.0.1:*/*",
          "https://*.vercel.app/*",
        ],
      },
      (tabs) => {
        if (tabs && tabs.length > 0) {
          tabs.forEach((tab) => {
            chrome.tabs.sendMessage(tab.id, {
              type: "NAMVIET_ERP_SYNC_INVOICE",
              payload: request.payload,
            });
          });
          // Bật thông báo ở góc màn hình Windows/Mac báo xong
          chrome.notifications.create({
            type: "basic",
            iconUrl: "icons/icon128.png",
            title: "Nam Việt ERP",
            message: `Đã đồng bộ thành công ${request.payload.length} hóa đơn sang ERP!`,
          });
        } else {
          chrome.notifications.create({
            type: "basic",
            iconUrl: "icons/icon128.png",
            title: "Lỗi Đồng Bộ",
            message:
              "Lấy xong dữ liệu nhưng không tìm thấy Tab ERP nào đang mở để đẩy vào!",
          });
        }
      },
    );
  }
});
