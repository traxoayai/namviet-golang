chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "CRAWLER_UI_UPDATE") {
    injectOrUpdateFloatingUI(request.state);
  } else if (request.action === "CRAWLER_UI_REMOVE") {
    const existingUI = document.getElementById("nv-crawler-widget");
    if (existingUI) existingUI.remove();
  }
});

// Giữ Service Worker luôn tỉnh táo khi đang có tab mở
setInterval(() => {
  chrome.runtime.sendMessage({ action: "PING" }).catch(() => {});
}, 15000);

function injectOrUpdateFloatingUI(state) {
  let ui = document.getElementById("nv-crawler-widget");
  
  if (!ui) {
    ui = document.createElement("div");
    ui.id = "nv-crawler-widget";
    ui.style.cssText = `
      position: fixed; top: 30px; right: 30px; width: 340px;
      background: #fff; box-shadow: 0 8px 24px rgba(0,0,0,0.2);
      border-radius: 8px; border: 2px solid #1677ff; z-index: 2147483647;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      padding: 15px; color: #333; transition: all 0.3s ease;
    `;
    
    ui.innerHTML = `
      <div style="display:flex; align-items: center; border-bottom: 1px solid #f0f0f0; padding-bottom: 10px; margin-bottom: 15px;">
        <div style="width:30px; height:30px; background:#1677ff; color:#fff; display:flex; align-items:center; justify-content:center; font-weight:bold; border-radius:4px; margin-right:10px;">NV</div>
        <strong style="color: #1677ff; font-size: 15px; text-transform: uppercase;">Tiến Trình Cào Dữ Liệu</strong>
      </div>
      <div id="nv-crawler-status" style="font-size: 13px; font-weight: bold; margin-bottom: 8px; color: #0958d9;">Đang khởi động...</div>
      <div id="nv-crawler-detail" style="font-size: 13px; color: #555; margin-bottom: 15px; min-height: 20px;"></div>
      <div style="display: flex; justify-content: space-between; font-size: 12px; font-weight: bold; margin-bottom: 5px;">
        <span>Tiến độ:</span>
        <span id="nv-crawler-progress-text">0/0</span>
      </div>
      <div style="background: #f0f0f0; border-radius: 4px; height: 10px; overflow: hidden; margin-bottom: 15px;">
        <div id="nv-crawler-progress-bar" style="width: 0%; height: 100%; background: #52c41a; transition: width 0.3s;"></div>
      </div>
      <button id="nv-crawler-close" style="width: 100%; padding: 8px; background: #ff4d4f; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;">DỪNG LẠI / ẨN</button>
    `;
    document.body.appendChild(ui);

    document.getElementById("nv-crawler-close").addEventListener("click", () => {
      chrome.runtime.sendMessage({ action: "STOP_CRAWL" });
      ui.remove();
    });
  }

  // Cập nhật trạng thái
  document.getElementById("nv-crawler-status").innerText = state.mainStatus || "Đang xử lý...";
  document.getElementById("nv-crawler-detail").innerText = state.detailStatus || "";
  
  if (state.total > 0) {
    document.getElementById("nv-crawler-progress-text").innerText = \`\${state.current} / \${state.total}\`;
    const percent = (state.current / state.total) * 100;
    document.getElementById("nv-crawler-progress-bar").style.width = \`\${percent}%\`;
  }
}
