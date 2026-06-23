let isRunning = false;
let currentConfig = { url: "", key: "" };
let state = { current: 0, total: 0, productId: null, mainStatus: "", detailStatus: "" };

// Keep Service Worker Alive
let keepAliveInterval;
function startKeepAlive() {
  if (keepAliveInterval) clearInterval(keepAliveInterval);
  keepAliveInterval = setInterval(() => {
    chrome.runtime.getPlatformInfo(() => {}); // Wake up
  }, 15000);
}
function stopKeepAlive() {
  if (keepAliveInterval) clearInterval(keepAliveInterval);
}

function broadcastToAllTabs(action, payload) {
  chrome.tabs.query({}, (tabs) => {
    for (let tab of tabs) {
      chrome.tabs.sendMessage(tab.id, { action, ...payload }).catch(() => {});
    }
  });
}

function updateUI(main, detail) {
  if (main) state.mainStatus = main;
  if (detail) state.detailStatus = detail;
  
  // Send to popup if open
  chrome.runtime.sendMessage({ action: "PROGRESS", ...state }).catch(() => {});
  // Send to floating UI on all tabs
  broadcastToAllTabs("CRAWLER_UI_UPDATE", { state });
  
  // Tự động log luôn ra bảng đen
  sendLog(`[${state.productId || 'SYS'}] ${main} - ${detail}`);
}

function sendLog(text) {
  console.log(text);
  chrome.runtime.sendMessage({ action: "LOG", text }).catch(() => {});
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.action === "GET_STATE") {
    sendResponse({ isRunning, ...state });
  } else if (msg.action === "START_CRAWL") {
    currentConfig = { url: msg.url, key: msg.key };
    startCrawl(msg.products);
  } else if (msg.action === "STOP_CRAWL") {
    isRunning = false;
    updateUI("Đã dừng", "Tiến trình bị hủy bởi người dùng");
    setTimeout(() => broadcastToAllTabs("CRAWLER_UI_REMOVE", {}), 3000);
  } else if (msg.action === "PING") {
    sendResponse({ status: "ALIVE" });
  }
});

// Also inject floating UI when user switches tab
chrome.tabs.onActivated.addListener((activeInfo) => {
  if (isRunning) {
    chrome.tabs.sendMessage(activeInfo.tabId, { action: "CRAWLER_UI_UPDATE", state }).catch(() => {});
  }
});

async function supabaseFetch(path, method = "GET", body = null) {
  const options = {
    method,
    headers: {
      "Content-Type": "application/json",
      apikey: currentConfig.key,
      Authorization: `Bearer ${currentConfig.key}`,
    },
  };
  if (body) options.body = JSON.stringify(body);
  
  // Timeout controller (180 seconds for Gemini API)
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), 180000);
  options.signal = controller.signal;

  try {
    const res = await fetch(`${currentConfig.url}${path}`, options);
    clearTimeout(id);
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Supabase Error (${res.status}): ${err}`);
    }
    const text = await res.text();
    if (!text) return {};
    try {
      return JSON.parse(text);
    } catch (e) {
      return text;
    }
  } catch (err) {
    clearTimeout(id);
    throw err;
  }
}

async function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function extractTextFromHtml(html) {
  // Rất thô sơ để bóc text: loại bỏ script, style và thẻ html
  let text = html.replace(/<script[^>]*>([\s\S]*?)<\/script>/gi, ' ');
  text = text.replace(/<style[^>]*>([\s\S]*?)<\/style>/gi, ' ');
  text = text.replace(/<[^>]+>/g, ' ');
  text = text.replace(/\s+/g, ' ').trim();
  // Cắt bớt nếu quá dài (Gemini hỗ trợ token lớn nhưng cắt 150,000 ký tự cho an toàn)
  return text.substring(0, 150000);
}

async function searchProductUrl(productName) {
  // LỚP 1: TÌM TRÊN AN KHANG QUA API (Ưu tiên đặc biệt theo yêu cầu của user)
  try {
    const payload = {
      provinceId: 1027,
      pageSize: 20,
      pageIndex: 0,
      filters: [{ filterId: -1, filterTypeId: 7, sortName: '', attributeCode: '', url: '' }],
      keyword: productName,
      sellerId: -1
    };
    const akRes = await fetch('https://webapi.nhathuocankhang.com/gw/bus-ankhang-tmdt/api/Search/GetProductSearchV2', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      },
      body: JSON.stringify(payload)
    });
    if (akRes.ok) {
      const akData = await akRes.json();
      const firstProduct = akData?.data?.products?.[0];
      if (firstProduct && firstProduct.url) {
        let url = firstProduct.url;
        if (!url.startsWith('/')) url = '/' + url;
        return `https://www.nhathuocankhang.com${url}`;
      }
    }
  } catch (e) { }

  // LỚP 2: TÌM TRÊN GOOGLE
  try {
    const query = `site:nhathuocankhang.com OR site:nhathuoclongchau.com.vn OR site:pharmacity.vn ${productName}`;
    const googleRes = await fetch(
      `https://www.google.com/search?q=${encodeURIComponent(query)}`,
      { headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
    );
    if (googleRes.ok) {
      const html = await googleRes.text();
      const links = [];
      const regex = /href="(https:\/\/(www\.)?(nhathuocankhang\.com|nhathuoclongchau\.com\.vn|pharmacity\.vn)[^"]+)"/gi;
      let match;
      while ((match = regex.exec(html)) !== null) {
        links.push(match[1]);
      }
      if (links.length > 0) {
        const ankhang = links.find(l => l.includes('nhathuocankhang.com'));
        if (ankhang) return ankhang;
        const longchau = links.find(l => l.includes('nhathuoclongchau.com'));
        if (longchau) return longchau;
        return links[0];
      }
    }
  } catch (e) { }

  // LỚP 3: TÌM TRÊN LONG CHÂU (Hệ thống nội bộ ổn định)
  try {
    const lcRes = await fetch(
      `https://nhathuoclongchau.com.vn/tim-kiem?s=${encodeURIComponent(productName)}`,
      { headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
    );
    if (lcRes.ok) {
      const lcHtml = await lcRes.text();
      const searchMatch = lcHtml.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
      if (searchMatch) {
        const searchData = JSON.parse(searchMatch[1]);
        const firstHit = searchData?.props?.pageProps?.initProducts?.products?.[0];
        if (firstHit && firstHit.slug) {
          let targetUrl = firstHit.slug;
          if (!targetUrl.startsWith("/")) targetUrl = "/" + targetUrl;
          return `https://nhathuoclongchau.com.vn${targetUrl}`;
        }
      }
    }
  } catch (e) { }

  return null;
}

async function startCrawl(productsQueue) {
  if (isRunning) return;
  isRunning = true;
  startKeepAlive();

  try {
    updateUI("Khởi động", `Đã nhận danh sách ${productsQueue.length} sản phẩm từ CSV...`);
    const products = productsQueue;

    state.total = products.length;
    state.current = 0;
    
    if (products.length === 0) {
      updateUI("Hoàn tất", "Không có sản phẩm nào cần cập nhật.");
      isRunning = false;
      setTimeout(() => broadcastToAllTabs("CRAWLER_UI_REMOVE", {}), 5000);
      return;
    }

    for (const prod of products) {
      if (!isRunning) break;
      state.current++;
      state.productId = prod.sku || prod.name;

      try {
        updateUI(`Đang quét: ${prod.name}`, "Tìm kiếm link nguồn qua DuckDuckGo/Google...");
        
        const targetUrl = await searchProductUrl(prod.name);
        if (!targetUrl) {
           updateUI(`Đang quét: ${prod.name}`, "Không tìm thấy link phù hợp. Bỏ qua.");
           await delay(3000);
           continue;
        }

        updateUI(`Đang quét: ${prod.name}`, `Lấy dữ liệu từ: ${new URL(targetUrl).hostname}...`);
        
        const detailRes = await fetch(targetUrl, {
            headers: {
              "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }
        });
        
        if (!detailRes.ok) {
           throw new Error(`Fetch HTML Failed: ${detailRes.status}`);
        }
        
        const html = await detailRes.text();
        const rawText = extractTextFromHtml(html);

        if (!rawText || rawText.length < 500) {
          updateUI(`Đang quét: ${prod.name}`, "Lỗi: Nội dung text quá ngắn hoặc bị block. Bỏ qua.");
          await delay(3000);
          continue;
        }

        updateUI(`Đang quét: ${prod.name}`, "Đã tải xong nội dung. Đang gửi cho AI phân tích đa nguồn...");

        // Gửi lên Edge Function mới (multisource-enrich-product)
        await supabaseFetch("/functions/v1/multisource-enrich-product", "POST", {
          sku: prod.sku,
          name: prod.name,
          source_url: targetUrl,
          raw_text: rawText
        });

        updateUI(`Đang quét: ${prod.name}`, "✅ Đã nhận dữ liệu từ AI và Cập nhật xong!");

      } catch (err) {
        updateUI(`Lỗi sản phẩm: ${prod.name}`, `❌ ${err.message}`);
      }

      await delay(4000);
    }

    if (isRunning) {
      updateUI("Kết thúc", "Hoàn tất 100% sản phẩm.");
      isRunning = false;
      stopKeepAlive();
      setTimeout(() => broadcastToAllTabs("CRAWLER_UI_REMOVE", {}), 5000);
    }

  } catch (err) {
    updateUI("Lỗi hệ thống", `❌ ${err.message}`);
    isRunning = false;
    stopKeepAlive();
    setTimeout(() => broadcastToAllTabs("CRAWLER_UI_REMOVE", {}), 5000);
  }
}
