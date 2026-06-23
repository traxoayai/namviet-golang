console.log("NAM_VIET_ERP_EXTENSION_VERSION_4_LOADED");
(function () {
  // Setup an interval to watch for jwt in case of Single Page App navigation
  setInterval(() => {
    const jwt = sessionStorage.getItem("jwt");
    if (!jwt) {
      return; // Not logged in yet
    }

    // Check if floating button already exists
    if (document.getElementById("nv-erp-btn")) return;

    // Create floating button
    const btn = document.createElement("button");
    btn.id = "nv-erp-btn";
    btn.innerText = "XAC NHAN MA KET NOI";
    btn.style.position = "fixed";
    btn.style.bottom = "20px";
    btn.style.right = "20px";
    btn.style.zIndex = "999999";
    btn.style.padding = "15px 25px";
    btn.style.backgroundColor = "#ff4d4f";
    btn.style.color = "white";
    btn.style.border = "none";
    btn.style.borderRadius = "8px";
    btn.style.fontSize = "16px";
    btn.style.fontWeight = "bold";
    btn.style.cursor = "pointer";
    btn.style.boxShadow = "0 4px 12px rgba(0,0,0,0.15)";
    
    btn.onmouseover = () => btn.style.backgroundColor = "#ff7875";
    btn.onmouseout = () => btn.style.backgroundColor = "#ff4d4f";

    btn.onclick = async () => {
      btn.innerText = "Dang gui...";
      btn.disabled = true;

      const backendUrl = "https://backend-api-1051286041700.asia-southeast1.run.app";

      try {
        const res = await fetch(`${backendUrl}/api/v1/finance/invoices/gdt-token`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ token: jwt })
        });

        if (!res.ok) {
          throw new Error("Failed to send token");
        }

        btn.innerText = "Thanh cong! Dang dong...";
        btn.style.backgroundColor = "#52c41a";
        
        setTimeout(() => {
          window.close(); // Close the popup window
        }, 1500);

      } catch (err) {
        btn.innerText = "Loi ket noi Backend! Thu lai.";
        btn.style.backgroundColor = "#ff4d4f";
        btn.disabled = false;
        console.error(err);
      }
    };

    document.body.appendChild(btn);
  }, 1000); // Check every 1 second
})();
