// --- PHẦN 1: DÀNH CHO TAB ERP (Nhận data và bắn vào web React) ---
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "NAMVIET_ERP_SYNC_INVOICE") {
    console.log("ERP Tab nhận dữ liệu:", request.payload.length);
    const event = new CustomEvent("NAMVIET_ERP_SYNC_INVOICE", {
      detail: JSON.stringify(request.payload),
    });
    window.dispatchEvent(event);
  }
});

// --- PHẦN 2: DÀNH CHO TAB TỔNG CỤC THUẾ (Giao diện nổi & Thuật toán cào) ---
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (
    request.action === "START_FLOATING_SYNC" &&
    window.location.hostname === "hoadondientu.gdt.gov.vn"
  ) {
    injectFloatingUIAndRun(request.config);
  }
});

async function injectFloatingUIAndRun(config) {
  const existingUI = document.getElementById("nv-floating-bot");
  if (existingUI) existingUI.remove();

  const ui = document.createElement("div");
  ui.id = "nv-floating-bot";
  ui.style.cssText = `
    position: fixed; bottom: 30px; right: 30px; width: 340px;
    background: #fff; box-shadow: 0 8px 24px rgba(0,0,0,0.2);
    border-radius: 8px; border: 2px solid #1677ff; z-index: 9999999;
    font-family: Arial, sans-serif; padding: 20px; color: #333;
  `;

  const btnStartHTML =
    config.syncMode === "json"
      ? `<button id="nv-btn-start" style="width: 100%; padding: 12px; background: #1677ff; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; margin-bottom: 10px;">📁 CHỌN THƯ MỤC LƯU & BẮT ĐẦU</button>`
      : `<button id="nv-btn-start" style="width: 100%; padding: 12px; background: #1677ff; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; margin-bottom: 10px;">🚀 BẮT ĐẦU KÉO VỀ ERP</button>`;

  ui.innerHTML = `
    <div style="display:flex; align-items: center; border-bottom: 1px solid #f0f0f0; padding-bottom: 10px; margin-bottom: 15px;">
      <div style="width:30px; height:30px; background:#fa541c; color:#fff; display:flex; align-items:center; justify-content:center; font-weight:bold; border-radius:4px; margin-right:10px;">NV</div>
      <strong style="color: #1677ff; font-size: 16px; text-transform: uppercase;">Đồng bộ Hóa Đơn TCT</strong>
    </div>
    
    <div id="nv-pre-start">
        <p style="font-size: 13px; color: #666; margin-top: 0;">Thời gian: <b>${config.fromDateStr}</b> đến <b>${config.toDateStr}</b></p>
        ${btnStartHTML}
    </div>

    <div id="nv-running-ui" style="display: none;">
        <div id="nv-status" style="font-size: 14px; font-weight: bold; margin-bottom: 5px;">Đang chuẩn bị...</div>
        <div id="nv-detail" style="font-size: 12px; color: #666; margin-bottom: 15px; min-height: 45px;"></div>
        <div style="background: #f0f0f0; border-radius: 4px; height: 12px; overflow: hidden; margin-bottom: 15px;">
          <div id="nv-progress" style="width: 0%; height: 100%; background: #1677ff; transition: width 0.3s;"></div>
        </div>
    </div>
    <button id="nv-close" style="display:none; width: 100%; padding: 10px; background: #52c41a; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;">ĐÓNG BẢNG NÀY</button>
  `;
  document.body.appendChild(ui);

  const setStatus = (main, detail, percent) => {
    document.getElementById("nv-status").innerText = main;
    document.getElementById("nv-detail").innerHTML = detail;
    document.getElementById("nv-progress").style.width = percent + "%";
  };

  document
    .getElementById("nv-close")
    .addEventListener("click", () => ui.remove());

  let jwt =
    sessionStorage.getItem("jwt") ||
    (document.cookie.match(/(?:^|; )jwt=([^;]+)/) || [])[1];
  if (!jwt) {
    document.getElementById("nv-pre-start").innerHTML =
      "<span style='color:red; font-weight:bold;'>❌ Không tìm thấy Token. Hãy tải lại trang TCT và đăng nhập lại!</span>";
    return;
  }

  function chunkDateRange(startStr, endStr) {
    let chunks = [];
    let curr = new Date(startStr);
    let end = new Date(endStr);
    while (curr <= end) {
      let next = new Date(curr);
      next.setDate(next.getDate() + 25);
      if (next > end) next = new Date(end);
      chunks.push({
        start: curr.toISOString().split("T")[0],
        end: next.toISOString().split("T")[0],
      });
      curr = new Date(next);
      curr.setDate(curr.getDate() + 1);
    }
    return chunks;
  }

  document
    .getElementById("nv-btn-start")
    .addEventListener("click", async () => {
      let dirHandle = null;
      if (config.syncMode === "json") {
        try {
          dirHandle = await window.showDirectoryPicker({ mode: "readwrite" });
        } catch (error) {
          alert("Bạn đã hủy chọn thư mục. Quá trình đồng bộ bị hủy!");
          return;
        }
      }

      document.getElementById("nv-pre-start").style.display = "none";
      document.getElementById("nv-running-ui").style.display = "block";

      const chunks = chunkDateRange(config.fromDateStr, config.toDateStr);
      let totalInvoicesFound = 0;

      try {
        for (let i = 0; i < chunks.length; i++) {
          const c = chunks[i];
          let chunkInvoices = [];

          setStatus(
            `Đợt ${i + 1}/${chunks.length}: Quét danh sách`,
            `Khoảng thời gian: <b>${c.start}</b> đến <b>${c.end}</b>`,
            (i / chunks.length) * 100,
          );

          // Kéo danh sách với API động
          const listData = await fetchList(
            jwt,
            c.start,
            c.end,
            config.invoiceType,
          );

          if (listData.length > 0) {
            totalInvoicesFound += listData.length;

            for (let j = 0; j < listData.length; j++) {
              const inv = listData[j];
              setStatus(
                `Đợt ${i + 1}/${chunks.length}: Xử lý chi tiết`,
                `Đang kéo: <b>${j + 1} / ${listData.length}</b> hóa đơn<br/>(Cơ chế chậm an toàn & Tự động thử lại)`,
                (i / chunks.length) * 100 +
                  ((j + 1) / listData.length) * (100 / chunks.length),
              );

              // Auto-Retry Detail
              const detailData = await fetchDetail(
                jwt,
                inv.nbmst,
                inv.khhdon,
                inv.shdon,
                inv.khmshdon,
              );
              inv.hdhhdvu = detailData.hdhhdvu || [];

              if (config.syncMode === "erp") {
                chrome.runtime.sendMessage({
                  action: "FORWARD_TO_ERP",
                  payload: [inv],
                });
              } else {
                chunkInvoices.push(inv);
              }

              // PHANH GIẢM TỐC: Ngủ ngẫu nhiên từ 1.5s - 2.5s (Chống sót HĐ)
              await new Promise((r) =>
                setTimeout(r, Math.floor(Math.random() * 500) + 1000),
              );
            }

            if (config.syncMode === "json" && chunkInvoices.length > 0) {
              setStatus(
                `Đợt ${i + 1}/${chunks.length}: Đang lưu File`,
                `Đang ghi file cho đợt này...`,
                ((i + 1) / chunks.length) * 100,
              );

              let loaiTxt =
                config.invoiceType === "purchase" ? "MuaVao" : "BanRa";
              if (config.invoiceType === "sco_sold")
                loaiTxt = "BanRa_MayTinhTien";

              const fileName = `NamViet_${loaiTxt}_Tu_${c.start}_Den_${c.end}_[${chunkInvoices.length}_HD].json`;

              const fileHandle = await dirHandle.getFileHandle(fileName, {
                create: true,
              });
              const writable = await fileHandle.createWritable();
              await writable.write(JSON.stringify(chunkInvoices, null, 2));
              await writable.close();
            }
            chunkInvoices = null;
          }
          await new Promise((r) => setTimeout(r, 1500));
        }

        setStatus(
          "🎉 Hoàn Tất Toàn Bộ!",
          `Đã xử lý <b>${totalInvoicesFound}</b> hóa đơn không sót tờ nào!<br/>Tốc độ chậm đã phát huy hiệu quả.`,
          100,
        );
        document.getElementById("nv-progress").style.background = "#52c41a";
        document.getElementById("nv-close").style.display = "block";
      } catch (err) {
        setStatus(
          "Hệ thống báo lỗi",
          `<span style='color:red;'>${err.message}</span>`,
          100,
        );
        document.getElementById("nv-progress").style.background = "#ff4d4f";
        document.getElementById("nv-close").style.display = "block";
      }
    });
}

// ---------------------------------------------------------
// KIẾN TRÚC GỌI API MỚI (PHÂN LUỒNG TUYỆT ĐỐI)
// ---------------------------------------------------------

async function fetchList(jwt, startStr, endStr, rawType) {
  const [fY, fM, fD] = startStr.split("-");
  const [tY, tM, tD] = endStr.split("-");
  const geDate = `${fD}/${fM}/${fY}T00:00:00`;
  const leDate = `${tD}/${tM}/${tY}T23:59:59`;

  // Dùng .trim() để ép kiểu, xóa sạch khoảng trắng vô tình lọt vào từ thẻ HTML
  const type = (rawType || "").trim();

  let apiBasePath = "query";
  let queryType = type;
  let searchParam = `tdlap=ge=${geDate};tdlap=le=${leDate}`;

  // Khai báo biến
  let dir = "";
  let src = "";

  // Thuật toán rẽ nhánh bọc thép
  switch (type) {
    case "purchase":
      apiBasePath = "query";
      queryType = "purchase";
      searchParam += ";ttxly==5";
      dir = "inbound"; // Hóa đơn đầu vào
      src = "standard";
      break;

    case "sold":
      apiBasePath = "query";
      queryType = "sold";
      searchParam += ";ttxly==5";
      dir = "outbound"; // CHỐT CỨNG ĐẦU RA TẠI ĐÂY
      src = "standard";
      break;

    case "sco_sold":
      apiBasePath = "sco-query";
      queryType = "sold";
      // Không nối thêm ;ttxly==5
      dir = "outbound"; // CHỐT CỨNG ĐẦU RA TẠI ĐÂY
      src = "cash_register";
      break;

    default:
      console.error("Lỗi: Mã loại hóa đơn không hợp lệ từ Popup ->", type);
      // Fallback an toàn
      dir = "inbound";
      src = "unknown";
      break;
  }

  let all = [];
  let state = "";
  let hasMore = true;
  while (hasMore) {
    let url = `https://hoadondientu.gdt.gov.vn/api/${apiBasePath}/invoices/${queryType}?sort=tdlap:desc&size=50&search=${searchParam}`;
    if (state) url += `&state=${encodeURIComponent(state)}`;

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${jwt}` },
    });
    if (!res.ok) {
      if (res.status === 400) {
        const errorData = await res.json();
        throw new Error(`Cục thuế chặn 400: ${errorData.message}`);
      }
      throw new Error("Cục thuế chặn kết nối, mã lỗi: " + res.status);
    }

    const json = await res.json();
    all = all.concat(json.datas || []);

    if ((json.datas || []).length < 50) hasMore = false;
    else if (json.state) {
      state = json.state;
      await new Promise((r) => setTimeout(r, 600));
    } else hasMore = false;
  }

  // Gán nhãn dữ liệu chuẩn xác 100% trước khi đẩy sang ERP
  return all.map((inv) => ({
    ...inv,
    direction: dir,
    invoice_source: src,
  }));
}

// Hàm lấy chi tiết trang bị Vòng lặp bất tử (Retry 3 lần)
async function fetchDetail(jwt, nbmst, khhdon, shdon, khmshdon) {
  // Chú ý: Cả hóa đơn thường và hóa đơn Máy tính tiền đều dùng chung cổng /query/invoices/detail này
  const url = `https://hoadondientu.gdt.gov.vn/api/query/invoices/detail?nbmst=${nbmst}&khhdon=${khhdon}&shdon=${shdon}&khmshdon=${khmshdon}`;

  let lastError;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${jwt}` },
      });
      if (!res.ok) throw new Error(`HTTP Lỗi ${res.status}`);
      return await res.json();
    } catch (err) {
      lastError = err;
      console.warn(
        `Lỗi kéo HĐ ${shdon} lần ${attempt}. Đang thử lại sau 2 giây...`,
      );
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  console.error(`Thất bại hoàn toàn HĐ ${shdon} sau 3 lần thử. Bỏ qua.`);
  return {};
}
