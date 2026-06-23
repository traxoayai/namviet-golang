
import { useNavigate } from "react-router-dom";
import {
  Settings,
  Store,
  Navigation,
  Users,
  Coins,
  Wallet,
  FileText,
  Link as LinkIcon,
  Share2,
  Facebook,
  Landmark,
  RefreshCw,
  Award,
  Bot,
  LayoutTemplate,
  Smartphone,
  Palette,
  Package,
  FlaskConical,
  Database
} from "lucide-react";

export default function SystemSettingsHub() {
  const navigate = useNavigate();

  return (
    <main className="flex-1 overflow-y-auto p-4 lg:p-6 custom-scrollbar">
      <div className="mb-6">
        <h2 className="text-2xl font-black text-slate-800 dark:text-white tracking-tight">
          Cấu hình Hệ thống (Master Data)
        </h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Quản lý các thông tin lõi, kết nối ngoại vi và thiết lập giao diện cho toàn bộ hệ thống.
        </p>
      </div>

      <div className="space-y-8">
        
        {/* KHỐI 1: THIẾT LẬP THÔNG TIN */}
        <section>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Settings size={18} />
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">Thiết lập thông tin</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card title="Thông tin cửa hàng" desc="Liên hệ, địa chỉ..." icon={Store} color="blue" link="/settings/business/general" navigate={navigate} />
            <Card title="Quản lý chi nhánh" desc="Danh sách chi nhánh" icon={Navigation} color="blue" link="/settings/business/operations" navigate={navigate} />
            <Card title="Phân quyền nhân viên" desc="Tài khoản, vai trò" icon={Users} color="blue" link="/settings/users-roles" navigate={navigate} />
            <Card title="Chính sách giá" desc="Bảng giá, chiết khấu" icon={Coins} color="blue" link="/settings/business/sales" navigate={navigate} />
            <Card title="Thanh toán" desc="VNPay, Timo, MoMo..." icon={Wallet} color="blue" link="/settings/business/finance/banks" navigate={navigate} />
            <Card title="Mẫu in" desc="Hóa đơn, phiếu thu" icon={FileText} color="blue" link="/settings/templates" navigate={navigate} />
          </div>
        </section>

        {/* KHỐI 2: CẤU HÌNH SẢN PHẨM & DATA */}
        <section>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <Package size={18} />
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">Cấu hình Sản phẩm</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card title="Danh mục Hoạt chất" desc="Quản lý hoạt chất Y tế" icon={FlaskConical} color="blue" link="/settings/active-ingredients" navigate={navigate} />
            <Card title="Master Data" desc="Nhập/Xuất kho ngoại vi" icon={Database} color="blue" link="/settings/data/master" navigate={navigate} />
          </div>
        </section>

        {/* KHỐI 3: KẾT NỐI NGOẠI VI */}
        <section>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <LinkIcon size={18} />
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">Kết nối đơn vị ngoài</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card title="Vận chuyển" desc="GHTK, Viettel Post..." icon={Share2} color="emerald" link="#" navigate={navigate} />
            <Card title="Facebook" desc="Kết nối Page, tài khoản" icon={Facebook} color="emerald" link="#" navigate={navigate} />
            <Card title="Zalo OA" desc="Kết nối Zalo ZNS" icon={Share2} color="emerald" link="#" navigate={navigate} />
            <Card title="TMĐT & TikTok" desc="Shopee, TikTok Shop" icon={Store} color="emerald" link="#" navigate={navigate} />
          </div>
        </section>

        {/* KHỐI 4: TÀI CHÍNH */}
        <section>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Landmark size={18} />
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">Tài chính</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card title="Ngân hàng" desc="Tài khoản nhận, Quỹ" icon={Landmark} color="amber" link="/settings/business/finance/banks" navigate={navigate} />
            <Card title="Loại Thu/Chi" desc="Danh mục thu chi" icon={FileText} color="amber" link="/settings/business/finance/categories" navigate={navigate} />
            <Card title="Tài Khoản/Quỹ Tiền" desc="Quản lý nguồn quỹ" icon={FileText} color="amber" link="/settings/business/finance/accounts" navigate={navigate} />
            <Card title="Giao dịch lặp lại" desc="Thu chi định kỳ" icon={RefreshCw} color="amber" link="/settings/business/finance/recurring" navigate={navigate} />
          </div>
        </section>

        {/* KHỐI 5: NHÂN SỰ */}
        <section>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <Users size={18} />
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">Nhân sự</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card title="Loại Hợp đồng" desc="Thử việc, dài hạn..." icon={FileText} color="purple" link="/settings/business/hr" navigate={navigate} />
            <Card title="Quy tắc KPI" desc="Thưởng phạt KPI" icon={Award} color="purple" link="/settings/business/hr" navigate={navigate} />
            <Card title="Chính sách lương" desc="Lương cứng, phụ cấp" icon={Coins} color="purple" link="/settings/business/hr" navigate={navigate} />
          </div>
        </section>

        {/* KHỐI 6: AI & CÔNG NGHỆ */}
        <section>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-primary-50 dark:bg-primary-900/30 text-primary flex items-center justify-center">
              <Bot size={18} />
            </div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">AI & Công nghệ</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card title="Cấu hình Chatbot" desc="Dạy Bot, tích hợp Web" icon={Bot} color="orange" link="#" navigate={navigate} />
            <Card title="Theme Website" desc="Giao diện Web B2B/B2C" icon={LayoutTemplate} color="orange" link="#" navigate={navigate} />
            <Card title="Theme Mobile App" desc="Giao diện App Khách" icon={Smartphone} color="orange" link="#" navigate={navigate} />
            <Card title="Cấu hình Chung" desc="Logo, màu sắc" icon={Palette} color="orange" link="#" navigate={navigate} />
          </div>
        </section>

      </div>
    </main>
  );
}

// Sub-component cho các Card
function Card({ 
  title, 
  desc, 
  icon: Icon, 
  color, 
  link, 
  navigate 
}: { 
  title: string, 
  desc: string, 
  icon: any, 
  color: 'blue' | 'emerald' | 'amber' | 'purple' | 'orange',
  link: string,
  navigate: (path: string) => void
}) {
  
  const colorMap = {
    blue: 'text-blue-500 bg-blue-50 group-hover:bg-blue-500 group-hover:text-white dark:bg-blue-900/20',
    emerald: 'text-emerald-500 bg-emerald-50 group-hover:bg-emerald-500 group-hover:text-white dark:bg-emerald-900/20',
    amber: 'text-amber-500 bg-amber-50 group-hover:bg-amber-500 group-hover:text-white dark:bg-amber-900/20',
    purple: 'text-purple-500 bg-purple-50 group-hover:bg-purple-500 group-hover:text-white dark:bg-purple-900/20',
    orange: 'text-primary bg-primary-50 group-hover:bg-primary group-hover:text-white dark:bg-primary-900/20',
  };

  return (
    <button 
      onClick={() => {
        if (link && link !== "#") {
          navigate(link);
        }
      }}
      className="flex items-center gap-4 p-4 bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl hover:shadow-lg hover:border-slate-200 dark:hover:border-slate-600 transition-all text-left group active:scale-95"
    >
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 transition-colors ${colorMap[color]}`}>
        <Icon size={24} />
      </div>
      <div>
        <h4 className="font-bold text-slate-800 dark:text-white text-sm line-clamp-1">{title}</h4>
        <p className="text-xs text-slate-500 font-medium mt-0.5 line-clamp-1">{desc}</p>
      </div>
    </button>
  );
}
