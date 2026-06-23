document.addEventListener("DOMContentLoaded", async () => {
  const successMsg = document.getElementById("successMessage");
  const warningLongRun = document.getElementById("warningLongRun");
  const mainForm = document.getElementById("mainForm");
  const btnSync = document.getElementById("btnSync");
  const errorMsg = document.getElementById("errorMessage");

  // Input fields
  const f_dd = document.getElementById("f_dd"),
    f_mm = document.getElementById("f_mm"),
    f_yyyy = document.getElementById("f_yyyy");
  const t_dd = document.getElementById("t_dd"),
    t_mm = document.getElementById("t_mm"),
    t_yyyy = document.getElementById("t_yyyy");

  // --- TRẢI NGHIỆM TỰ ĐỘNG CHUYỂN Ô KHI GÕ (AUTO-JUMP) ---
  const inputs = document.querySelectorAll(".auto-jump");
  inputs.forEach((input, index) => {
    input.addEventListener("input", function () {
      if (this.value.length === this.maxLength && index < inputs.length - 1) {
        inputs[index + 1].focus();
      }
    });
  }); // Đã đóng vòng lặp chuẩn xác tại đây

  // --- HIỂN THỊ CẢNH BÁO NẾU > 31 NGÀY ---
  function checkDateRange() {
    try {
      const fromStr = `${f_yyyy.value}-${f_mm.value.padStart(2, "0")}-${f_dd.value.padStart(2, "0")}`;
      const toStr = `${t_yyyy.value}-${t_mm.value.padStart(2, "0")}-${t_dd.value.padStart(2, "0")}`;
      const diffDays =
        (new Date(toStr) - new Date(fromStr)) / (1000 * 60 * 60 * 24);

      if (diffDays > 31) {
        warningLongRun.style.display = "block";
      } else {
        warningLongRun.style.display = "none";
      }
    } catch (e) {}
  }
  document
    .querySelectorAll('input[type="text"]')
    .forEach((el) => el.addEventListener("keyup", checkDateRange));

  // Hàm tiện ích parse ngày vào các ô
  function setInputsFromDate(dStart, dEnd) {
    f_dd.value = String(dStart.getDate()).padStart(2, "0");
    f_mm.value = String(dStart.getMonth() + 1).padStart(2, "0");
    f_yyyy.value = dStart.getFullYear();

    t_dd.value = String(dEnd.getDate()).padStart(2, "0");
    t_mm.value = String(dEnd.getMonth() + 1).padStart(2, "0");
    t_yyyy.value = dEnd.getFullYear();
    checkDateRange();
  }

  // --- LOGIC CHỌN NHANH ---
  document.getElementById("btnYesterday").addEventListener("click", () => {
    let d = new Date();
    d.setDate(d.getDate() - 1);
    setInputsFromDate(d, d);
  });
  document.getElementById("btnLast30Days").addEventListener("click", () => {
    let dEnd = new Date();
    let dStart = new Date();
    dStart.setDate(dStart.getDate() - 30);
    setInputsFromDate(dStart, dEnd);
  });
  document.getElementById("btnThisYear").addEventListener("click", () => {
    let dEnd = new Date();
    let dStart = new Date(dEnd.getFullYear(), 0, 1);
    setInputsFromDate(dStart, dEnd);
  });

  // Khởi tạo mặc định: 30 ngày qua
  let defaultEnd = new Date();
  let defaultStart = new Date();
  defaultStart.setDate(defaultStart.getDate() - 30);
  setInputsFromDate(defaultStart, defaultEnd);

  // --- KIỂM TRA MÔI TRƯỜNG TCT ---
  let [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab || !tab.url.startsWith("https://hoadondientu.gdt.gov.vn")) {
    errorMsg.style.display = "block";
    errorMsg.innerHTML =
      "❌ Vui lòng mở tab <b>Tổng Cục Thuế</b> (hoadondientu.gdt.gov.vn) và đăng nhập.";
    return;
  }
  mainForm.style.display = "block";

  // --- XỬ LÝ LÕI KHI BẤM THỰC THI (CHỈ PHÁT LỆNH RỒI TỰ TẮT) ---
  btnSync.addEventListener("click", async () => {
    const invoiceType = document.getElementById("invoiceType").value;
    const syncMode = document.querySelector(
      'input[name="syncMode"]:checked',
    ).value;

    const fromDateStr = `${f_yyyy.value}-${f_mm.value.padStart(2, "0")}-${f_dd.value.padStart(2, "0")}`;
    const toDateStr = `${t_yyyy.value}-${t_mm.value.padStart(2, "0")}-${t_dd.value.padStart(2, "0")}`;

    if (
      isNaN(new Date(fromDateStr).getTime()) ||
      isNaN(new Date(toDateStr).getTime())
    ) {
      alert("Định dạng ngày không hợp lệ. Vui lòng kiểm tra lại!");
      return;
    }

    // Phát lệnh kích hoạt UI Nổi sang content.js của tab Thuế
    chrome.tabs.sendMessage(tab.id, {
      action: "START_FLOATING_SYNC",
      config: { fromDateStr, toDateStr, invoiceType, syncMode },
    });

    // Bấm xong tự sát PopUp ngay lập tức
    window.close();
  });
});
