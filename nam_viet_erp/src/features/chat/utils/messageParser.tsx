import { Link } from "react-router-dom";

export function parseChatMessage(content: string) {
  if (!content) return null;

  // Regex bắt các pattern như /PO-xxx, /SO-xxx, /PR-xxx
  // Nhóm 1 (match[1]) là toàn bộ mã, ví dụ PO-2606-2AD4
  const regex = /\/([A-Z0-9-]+)/g;
  
  const parts = [];
  let lastIndex = 0;
  let match;

  while ((match = regex.exec(content)) !== null) {
    // Push the text before the match
    if (match.index > lastIndex) {
      parts.push(content.substring(lastIndex, match.index));
    }

    const code = match[1]; // VD: PO-2606-2AD4
    
    // Xây dựng link dựa trên prefix
    let link = null;
    if (code.startsWith("PO-")) {
      link = `/purchasing/master/${code}`;
    } else if (code.startsWith("SO-") || code.startsWith("B2B-")) {
      link = `/sales/b2b-orders/${code}`;
    } else if (code.startsWith("PR-")) {
      link = `/purchasing/requests/${code}`;
    } else if (code.startsWith("INV-")) {
      link = `/finance/invoices/${code}`;
    } else {
      // Mặc định fallback search tổng
      link = `/search?q=${code}`;
    }

    // Push the interactive link
    parts.push(
      <Link 
        key={match.index} 
        to={link} 
        className="text-blue-600 font-medium hover:underline px-1 bg-blue-50 rounded"
      >
        /{code}
      </Link>
    );

    lastIndex = regex.lastIndex;
  }

  // Push the remaining text
  if (lastIndex < content.length) {
    parts.push(content.substring(lastIndex));
  }

  return <>{parts.length > 0 ? parts : content}</>;
}
