document.addEventListener("DOMContentLoaded", () => {
  const btnStart = document.getElementById("btnStart");
  const btnStop = document.getElementById("btnStop");
  const supabaseUrlInput = document.getElementById("supabaseUrl");
  const supabaseKeyInput = document.getElementById("supabaseKey");
  const statusText = document.getElementById("statusText");
  const progressText = document.getElementById("progressText");
  const progressBar = document.getElementById("progressBar");
  const logContainer = document.getElementById("logContainer");
  const csvFileInput = document.getElementById("csvFile");
  const fileInfo = document.getElementById("fileInfo");
  let uploadedProducts = [];

  const DEFAULT_URL = "https://iudkexocalqdhxuyjacu.supabase.co";
  const DEFAULT_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1ZGtleG9jYWxxZGh4dXlqYWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNDA5NzIsImV4cCI6MjA3NzcxNjk3Mn0.TryofMnEhsBsgiUv29mOtn7yuR55FZCYrM8Xv1wmtQg";

  // Load saved config or use default
  chrome.storage.local.get(["supabaseUrl", "supabaseKey"], (res) => {
    supabaseUrlInput.value = res.supabaseUrl || DEFAULT_URL;
    supabaseKeyInput.value = res.supabaseKey || DEFAULT_KEY;
  });

  function logMsg(msg) {
    const div = document.createElement("div");
    div.className = "log-entry";
    div.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
    logContainer.appendChild(div);
    logContainer.scrollTop = logContainer.scrollHeight;
  }

  // CSV Parser
  csvFileInput.addEventListener("change", (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    const reader = new FileReader();
    reader.onload = (event) => {
      const text = event.target.result;
      const lines = text.split(/\r\n|\n|\r/).map(l => l.trim()).filter(l => l);
      
      if (lines.length < 2) {
        alert("File CSV không có dữ liệu hợp lệ. Vui lòng đảm bảo file có ít nhất 2 dòng (tiêu đề và dữ liệu).");
        return;
      }
      
      let firstLine = lines[0];
      if (firstLine.charCodeAt(0) === 0xFEFF) {
        firstLine = firstLine.substring(1);
      }
      const headers = firstLine.toLowerCase().replace(/[\s"']/g, '').split(',');
      const skuIdx = headers.findIndex(h => h.includes('sku'));
      const nameIdx = headers.findIndex(h => h.includes('name'));
      
      if (skuIdx === -1 || nameIdx === -1) {
        alert("File CSV phải có cột 'sku' và 'name'. Tiêu đề hiện tại: " + lines[0]);
        return;
      }
      
      uploadedProducts = [];
      for (let i = 1; i < lines.length; i++) {
        // Regex bóc tách CSV chuẩn hơn
        let row = lines[i];
        let cols = [];
        let insideQuote = false;
        let currentWord = '';
        for (let j = 0; j < row.length; j++) {
            let char = row[j];
            if (char === '"') {
                insideQuote = !insideQuote;
            } else if (char === ',' && !insideQuote) {
                cols.push(currentWord);
                currentWord = '';
            } else {
                currentWord += char;
            }
        }
        cols.push(currentWord); // push the last col

        if (cols.length > Math.max(skuIdx, nameIdx) && cols[skuIdx].trim() && cols[nameIdx].trim()) {
          uploadedProducts.push({
            sku: cols[skuIdx].replace(/^"|"$/g, '').trim(),
            name: cols[nameIdx].replace(/^"|"$/g, '').trim(),
            note: cols.length > headers.indexOf('note') && headers.indexOf('note') > -1 ? cols[headers.indexOf('note')].replace(/^"|"$/g, '').trim() : ""
          });
        }
      }
      
      if (uploadedProducts.length > 0) {
        fileInfo.textContent = `Đã nạp ${uploadedProducts.length} sản phẩm.`;
        fileInfo.style.color = "green";
        btnStart.disabled = false;
      } else {
        fileInfo.textContent = `Không tìm thấy sản phẩm hợp lệ.`;
        fileInfo.style.color = "red";
        btnStart.disabled = true;
      }
    };
    reader.readAsText(file);
  });

  btnStart.addEventListener("click", () => {
    const url = supabaseUrlInput.value.trim();
    const key = supabaseKeyInput.value.trim();
    if (!url || !key) {
      alert("Vui lòng nhập Supabase URL và Key");
      return;
    }
    if (uploadedProducts.length === 0) {
      alert("Vui lòng upload file CSV chứa sản phẩm trước khi cào dữ liệu.");
      return;
    }
    chrome.storage.local.set({ supabaseUrl: url, supabaseKey: key });

    btnStart.style.display = "none";
    btnStop.style.display = "block";
    statusText.textContent = "Đang khởi động...";
    logContainer.innerHTML = "";
    logMsg("Bắt đầu tiến trình cào dữ liệu từ file CSV...");

    chrome.runtime.sendMessage({ action: "START_CRAWL", url, key, products: uploadedProducts });
  });

  btnStop.addEventListener("click", () => {
    btnStart.style.display = "block";
    btnStop.style.display = "none";
    chrome.runtime.sendMessage({ action: "STOP_CRAWL" });
    logMsg("Đã yêu cầu dừng tiến trình.");
  });

  // Listen to background progress
  chrome.runtime.onMessage.addListener((msg) => {
    if (msg.action === "LOG") {
      logMsg(msg.text);
    } else if (msg.action === "PROGRESS") {
      progressText.textContent = `${msg.current}/${msg.total}`;
      progressBar.style.width = `${(msg.current / msg.total) * 100}%`;
      statusText.textContent = `Đang xử lý ID: ${msg.productId}`;
    } else if (msg.action === "DONE" || msg.action === "STOPPED") {
      btnStart.style.display = "block";
      btnStop.style.display = "none";
      statusText.textContent = msg.action === "DONE" ? "Hoàn thành!" : "Đã dừng.";
      logMsg("Tiến trình kết thúc.");
    }
  });

  // Check state on open
  chrome.runtime.sendMessage({ action: "GET_STATE" }, (state) => {
    if (state && state.isRunning) {
      btnStart.style.display = "none";
      btnStop.style.display = "block";
      statusText.textContent = "Đang chạy...";
      if (state.total) {
        progressText.textContent = `${state.current}/${state.total}`;
        progressBar.style.width = `${(state.current / state.total) * 100}%`;
      }
    }
  });
});
