Mục lục
Phần 1: Tổng Quan Dự Án và Tầm Nhìn Chiến Lược 3

1. Giới Thiệu Dự Án 3
2. "Nỗi Đau" Cần Giải Quyết 3
3. Tầm Nhìn & Triết Lý Cốt Lõi 3
   Phần 2: Kiến trúc Công nghệ & Nền tảng Kỹ thuật 4
4. Kiến trúc Tổng thể: Serverless & Hướng sự kiện 4
5. Nền tảng Công nghệ (Technology Stack) 4
6. Quy Ước Về Cấu Trúc Mã Nguồn & Phát Triển 5
   Phần 3: Tổng Kết Các Module Chức Năng Đã Xây Dựng 6
7. Nền tảng Giao diện Người dùng (UI Framework) 6
8. Module Quản lý Sản phẩm (/products) - ĐÃ HOÀN THIỆN GIAI ĐOẠN 1 6
9. Module Bán hàng tại quầy (POS) (/pos) 7
10. Module Quản lý Nhà Cung Cấp (/suppliers) 7
11. Module Mua Hàng (/requisitions, /purchase-orders) 8
    Phần 5: Các Module Cần Thiết: 8
    5.1 Bán hàng 8
    a. Menu “Kênh Cửa Hàng”: Sẽ bao gồm các nút con: 8
    Giao diện “Sàn TMĐT” theo thông tin như table dưới đây: 21
    b. Menu “Nghiệp vụ Y Tế”: sẽ bao gồm các nút con: 24
    c. Menu “Bán Buôn B2B” 37
    Mọi thông tin như table dưới đây: 37
    d. Sàn Thương Mại Điện Tử 45
    5.3 Quản lý Kho và Sản Phẩm 45
    a. Danh sách Sản Phẩm: 45
    a. Cấu hình Sản Phẩm nhanh 48
    a. Dự trù Mua Hàng 48
    b. Đơn đã Đặt hàng NCC 48
    c. Chuyển Hàng 50
    d. Kiểm Hàng 53
    e. Cập nhật Giá Vốn: 55
    f. Sản phẩm Gói & Dịch Vụ 56
    5.4 Đối Tác – Nhà Cung Cấp 58
    5.6 Quản lý Marketing 60
    5.6.1 Kiến trúc Toàn diện Module Marketing và Dashboard Marketing 60
    5.6.2 Nút “Quản lý Chiến dịch” 62
    5.6.3 Nút "Trình tạo Phân khúc Khách hàng" 66
    5.6.4 Nút “Thư viện Nội dung & Mẫu” 67
    5.6.5 Nút “"Quản lý Mã Giảm giá & QR Code" 67
    5.6.5 Nút “Quản lý Chatbot AI" 68
    5.7 Quản lý Nhân Sự và Đào Tạo 71
    5.7.1: Nền tảng Quản lý Nhân sự (HRM) 71
    5.7.2 Giao diện "Dashboard Nhân sự" 72
    5.7.3. Giao diện "Quản lý Hồ sơ Nhân viên" 72
    5.7.5 Nút “Quản lý Đào Tạo” và nút “Giao Việc & KPI” 73
    5.7.5 Nút “Quản lý Lương & Chế độ” 75
    5.8 Module “Tài chính & Kế Toán” 77
    5.8.1 Cấu trúc Module và Giao diện Quản lý Thu – Chi 77
    5.8.2 Nút “Quản lý Công Nợ” 79
    5.8.3 Nút “Sổ Quỹ” 81
    5.8.4 Nút “Quản Lý Tài Sản” 83
    5.8.4 Nút “Đối soát Giao Dịch” 85
    5.8.5 Nút “Nghiệp vụ Kế toán” 86
    5.8.6 Quản lý Hóa Đơn VAT 89
    5.9 Quản lý Khách hàng: 90
    6.0 Báo Cáo 92
    C. Báo cáo đầu tiên: Báo cáo Bán hàng 94
    D. Giao diện "Báo cáo Kho" 98
    E. Khuôn mẫu Báo cáo Thông minh" (Intelligent Reporting Template) 99
12. Trang chủ 100
    6.3 Giao diện và Luồng Góp ý, Đề xuất 102
13. Nút “Quản lý Bảng tin Chung” 103
14. Module “Cấu hình hệ thống và Phân quyền” 103
    8.1 Quản lý Người dùng & Phân quyền 103
    8.2 Cấu hình Nghiệp vụ, Quản lý Mẫu và Nhật ký Hệ thống 105

Tài Liệu Mô Tả Web và App (Cài trên điện thoại): Nam Việt ERP
Ngày tổng kết: 27 tháng 08 năm 2025
Phần 1: Tổng Quan Dự Án và Tầm Nhìn

1. Giới Thiệu Dự Án
   Dự án Nam Việt ERP là một sáng kiến chiến lược nhằm xây dựng một Hệ thống Hoạch định Nguồn lực Doanh nghiệp (ERP) toàn diện, được "may đo" riêng cho các quy trình nghiệp vụ của Công ty Dược Nam Việt. Hệ thống được kiến tạo không chỉ để quản lý, mà còn để tối ưu hóa và tự động hóa toàn bộ chuỗi hoạt động của công ty, bao gồm 5 đơn vị kinh doanh cốt lõi: Nhà thuốc DH 1, Nhà thuốc DH 2, Tiêm chủng Potec, Phòng khám Định Hiền, và Kho dược bán sỉ Nam Việt B2B.
2. Vấn Đề ("Nỗi Đau") Cần Giải Quyết
   Dự án được khởi tạo để giải quyết các thách thức và "nỗi đau" cố hữu trong quy trình vận hành hiện tại, bao gồm:
   • Sai lệch tồn kho: Sự chênh lệch lớn giữa số liệu sổ sách và thực tế, dẫn đến thất thoát.
   • Tổn thất do hàng hết hạn: Thiếu một hệ thống theo dõi Lô và Hạn sử dụng hiệu quả.
   • Đọng vốn: Hàng tồn kho luân chuyển chậm, không xác định được sản phẩm bán chậm.
   • Quy trình thủ công, tốn thời gian: Đặc biệt là quy trình nhập hàng, chuyển hàng, và dự trù mua hàng, gây lãng phí nguồn lực nhân sự.
   • Thiếu minh bạch trong chính sách giá: Việc quản lý các chương trình chiết khấu phức tạp từ nhà cung cấp gặp nhiều khó khăn, dẫn đến sai sót trong việc tính giá vốn và theo dõi công nợ trả sau.
   • Hiệu suất vận hành thấp: Quy trình lấy hàng và xếp kệ trong kho chưa được tối ưu.
3. Tầm Nhìn & Triết Lý Cốt Lõi
   Hệ thống Nam Việt ERP được xây dựng để trở thành "trái tim kỹ thuật số", kết nối tất cả các bộ phận, biến dữ liệu thô thành tài sản có giá trị và hỗ trợ ra quyết định thông minh. Triết lý phát triển của dự án dựa trên 3 trụ cột chính:
   • Thiết kế Lấy người dùng làm trung tâm (User-Centered Design): Thay vì các giao diện phức tạp, hệ thống cung cấp các "buồng lái" (cockpits) được tối ưu hóa cho từng vai trò cụ thể (Bác sĩ, Dược sĩ, Kế toán, Giám đốc), chỉ hiển thị thông tin và công cụ cần thiết cho công việc của họ.
   • Tự động hóa Thông minh: Tận dụng sức mạnh của Trí tuệ Nhân tạo (AI - Google Gemini) để tự động hóa các tác vụ lặp đi lặp lại như nhập liệu từ hóa đơn, dự báo nhu cầu mua hàng, và làm giàu dữ liệu sản phẩm.
   • Trí tuệ Kinh doanh Trực tuyến (Live Business Intelligence): Với nền tảng cơ sở dữ liệu thời gian thực, người dùng không tương tác với dữ liệu tĩnh, mà là một trung tâm điều khiển "sống", nơi mọi thông tin về tồn kho, doanh thu, công nợ đều được cập nhật tức thì.
   Phần 2: Kiến trúc Công nghệ & Nền tảng Kỹ thuật
   Phần này mô tả chi tiết "bộ khung" kỹ thuật của hệ thống, lý giải các lựa chọn công nghệ và các quy ước đã được thiết lập trong quá trình phát triển.
4. Kiến trúc Tổng thể: Serverless & Hướng sự kiện
   Hệ thống Nam Việt ERP được xây dựng dựa trên mô hình kiến trúc
   Serverless (Phi máy chủ) và Event-Driven (Hướng sự kiện) trên nền tảng Google Cloud Platform (GCP). Lựa chọn chiến lược này mang lại các lợi ích cốt lõi:
   • Tối ưu chi phí: Loại bỏ chi phí cho các tài nguyên nhàn rỗi, thanh toán theo mức sử dụng thực tế (pay-per-use).
   • Khả năng mở rộng: Hệ thống có thể tự động co giãn để đáp ứng từ vài người dùng đến hàng ngàn người dùng đồng thời mà không cần can thiệp thủ công.
   • Tăng tốc độ phát triển: Giúp đội ngũ phát triển tập trung vào việc xây dựng logic nghiệp vụ thay vì quản lý hạ tầng phức tạp.
   Các dịch vụ GCP chính được lựa chọn bao gồm
   Google Cloud Run cho các microservices chính và Google Cloud Functions cho các tác vụ nhỏ, được kích hoạt bởi sự kiện (ví dụ: cập nhật báo cáo khi có đơn hàng mới).
5. Nền tảng Công nghệ (Technology Stack)
   Bộ công nghệ được lựa chọn để đảm bảo hiệu suất, khả năng bảo trì và trải nghiệm người dùng hiện đại:
   • Frontend (Giao diện người dùng):
   • Thư viện: React.js.
   • Công cụ xây dựng: Vite (Nhanh và hiệu quả).
   • Thư viện UI (Chiến lược): Ant Design (AntD). Lựa chọn này được quyết định dựa trên triết lý ưu tiên các ứng dụng nghiệp vụ (enterprise-grade), cung cấp một bộ component B2B/ERP cực kỳ phong phú, mạnh mẽ, và khả năng tùy biến cao để hiển thị dữ liệu đặc (data-dense).
   • Quản lý trạng thái: Sử dụng các hook sẵn có của React (useContext, useReducer) kết hợp với các công cụ quản lý trạng thái tích hợp của AntD (như Form hooks) để giữ cho hệ thống tinh gọn và hiệu suất cao.

• Backend (Hệ thống xử lý):
o Ngôn ngữ: Node.js sử dụng TypeScript để đảm bảo mã nguồn chặt chẽ và giảm thiểu lỗi.
o Nền tảng triển khai:
 Giai đoạn đầu & AI: Google Apps Script được sử dụng làm API Gateway cho các tác vụ ban đầu và xử lý AI (như làm giàu dữ liệu từ PDF), tận dụng lợi thế của một "Zero-Cost Stack".
 Kiến trúc mục tiêu: Toàn bộ backend sẽ được triển khai trên Google Cloud Run và Google Cloud Functions để đảm bảo khả năng mở rộng ở cấp độ doanh nghiệp.
• Cơ sở dữ liệu (Database) - Nền tảng Supabase:
• Hệ thống: Supabase (PostgreSQL). Chúng ta lựa chọn Supabase làm nền tảng Backend-as-a-Service (BaaS) chiến lược. Lõi của Supabase là cơ sở dữ liệu PostgreSQL (SQL quan hệ), mang lại sự chặt chẽ, toàn vẹn dữ liệu (ACID) và khả năng truy vấn phức tạp, điều này là tối quan trọng cho các nghiệp vụ ERP, tài chính, kế toán và báo cáo đa chiều.
• Hệ sinh thái Tích hợp: Ngoài CSDL Postgres, chúng ta sẽ tận dụng toàn bộ hệ sinh thái của Supabase bao gồm:
 Supabase Auth: Quản lý toàn bộ việc xác thực người dùng và phân quyền (Row Level Security).
 Supabase Storage: Lưu trữ tất cả các file, hình ảnh, tài liệu (PDF, hóa đơn) của hệ thống.
 Supabase Realtime: Cung cấp khả năng cập nhật dữ liệu thời gian thực cho các module quan trọng như Dashboard, Hàng đợi, Tồn kho.
• Mô hình dữ liệu: Sẽ tuân thủ thiết kế quan hệ (relational design) của SQL, với các bảng được chuẩn hóa (normalized tables), khóa chính (primary keys), và khóa ngoại (foreign keys) để đảm bảo sự liên kết và toàn vẹn tuyệt đối giữa các thực thể như Sản phẩm, Đơn hàng, Kho, và Khách hàng.
• Trí tuệ Nhân tạo (AI Engine):
o Nền tảng: Google Gemini API.
o Ứng dụng: Được sử dụng cho các tác vụ thông minh, ví dụ như:
 Tự động trích xuất và làm giàu dữ liệu sản phẩm từ file PDF.
 Dự báo nhu cầu mua hàng dựa trên dữ liệu bán hàng lịch sử.
 Kiểm tra tương tác thuốc.
 Tính số ngày hết thuốc.
• Dịch vụ Thông báo Đẩy (Push Notification Service):
• Nền tảng: Firebase Cloud Messaging (FCM).
• Ứng dụng: Mặc dù hệ sinh thái chính dựa trên Supabase, chúng ta sẽ sử dụng FCM làm dịch vụ chuyên biệt và mạnh mẽ nhất để xử lý toàn bộ các thông báo đẩy (push notifications) theo thời gian thực.
• Vai trò: Gửi các cảnh báo tức thì đến ứng dụng di động và trình duyệt web của người dùng trong các nghiệp vụ quan trọng như:
o Thông báo có đơn hàng mới (cho Quản lý, Kho).
o Cảnh báo hàng tồn kho sắp hết.
o Nhắc lịch hẹn, lịch tiêm chủng cho khách hàng.
o Thông báo phê duyệt (duyệt đơn, duyệt chi...)

3. Quy Ước Về Cấu Trúc Mã Nguồn & Phát Triển
   Để đảm bảo dự án dễ dàng bảo trì và mở rộng, chúng ta đã thống nhất các quy ước sau:
   • Cấu trúc theo Tính năng (Feature-Sliced): Mã nguồn được tổ chức theo từng module nghiệp vụ (ví dụ: /features/products, /features/suppliers). Mỗi module chứa tất cả các thành phần liên quan (giao diện, logic, service).
   • Tư duy Components-First: Các giao diện phức tạp được chia nhỏ thành các component con, mỗi component chỉ đảm nhận một nhiệm vụ duy nhất.
   • Tách biệt Logic và Giao diện (Custom Hooks): Với các component phức tạp, toàn bộ logic xử lý (state, các hàm handle...) được tách ra một file "bộ não" riêng (use...js), giúp cho file giao diện (.jsx) trở nên cực kỳ gọn gàng và dễ đọc.
   • Quản lý phiên bản: Toàn bộ mã nguồn của dự án được quản lý trên GitHub. Mọi thay đổi đều được ghi nhận thông qua các commit với thông điệp rõ ràng.
4. Quy Ước Về Thiết kế Giao diện & Trải nghiệm (UI/UX) - Triết lý "Github-style"
   Để đảm bảo một trải nghiệm người dùng nhất quán, hiệu suất cao và rõ ràng về mặt cấu trúc, chúng ta thống nhất các quy ước thiết kế sau:
   • Thư viện: Hệ thống BẮT BUỘC sử dụng đồng bộ Ant Design (AntD) cho tất cả các component giao diện.
   • Bố cục "Tràn Viền" (Full-bleed Layout): Toàn bộ nội dung chính của các trang nghiệp vụ (danh sách, form, báo cáo) phải được thiết kế để tràn ra sát các cạnh của màn hình (không có lề trắng lớn ở hai bên). Triết lý này giúp tối đa hóa không gian hiển thị dữ liệu, đặc biệt quan trọng cho các màn hình ERP đặc thông tin.
   • Ranh giới Rõ ràng (Github-style): Để tránh sự mờ nhạt của giao diện "toàn trắng", các thành phần giao diện chính (như các khối widget, bảng biểu, khu vực form) BẮT BUỘC phải được phân định bằng các đường border (viền) đậm, rõ nét, với độ dày tối thiểu từ 1.5px trở lên.
   • Độ tương phản cao & Nền Phân biệt:
   o Các thành phần tương tác chính (như nút bấm - Button) KHÔNG được phép dùng nền trắng mặc định. Chúng BẮT BUỘC phải có màu nền riêng biệt (ví dụ: xanh nhạt, xám nhạt) để nổi bật trên giao diện trắng.
   o Tất cả các nút bấm và thành phần tương tác BẮT BUỘC phải có hiệu ứng thay đổi màu sắc (nền hoặc viền) rõ rệt khi được rê chuột (hover).
   o Màu sắc tổng thể phải ưu tiên sự tương phản cao, giúp người dùng dễ dàng định vị thông tin.
   Phần 5: Chi Tiết Các Module Cần Thiết:
   5.1 Bán hàng
    Đặt lịch hẹn: Giao diện dùng cho Lễ Tân hoặc Dược Sĩ khi cần đặt lịch tiêm chủng và lịch khám bệnh của bệnh nhân.
    Bán hàng POS: Giao diện dùng cho Lễ Tân hoặc Dược Sĩ, làm thủ tục thanh toán và lấy Đơn thuốc khi Bệnh nhân (Do bác sĩ kê) hoàn tất khám bệnh.
    Phòng Khám: Giao diện dùng cho Bác Sĩ khám bệnh  Chỉ định dịch vụ thêm (nếu cần thiết)  Chẩn đoán và kê đơn thuốc.
    Tiêm Chủng: Giao diện dùng cho Bác Sĩ khám tổng quát  Đồng ý cho khách hàng tiêm hay không 
    Bán Buôn (B2B): Giao diện dùng cho Nhân viên Kinh Doanh tạo đơn hàng cho các khách hàng là: Nhà thuốc; Phòng khám; etc…
    Sàn Thương mại Điện Tử: Giao diện kết nối sàn thương mại điện tử Shoppee để quản lý các thông tin.
   a. Menu “Kênh Cửa Hàng”: Sẽ bao gồm các nút con:
   • Dashboard Cửa hàng
   • Đặt Lịch Hẹn
   • Bán Hàng POS
   • Danh sách Đơn hàng
   • Sàn TMĐT
   Chi tiết giao diện các nút như sau:
   Giao diện “Dashboard Cửa hàng” theo thông tin như table dưới đây:
   Triết lý Thiết kế & Bố cục Tổng thể
   Trước khi đi vào chi tiết cho từng vai trò, chúng ta sẽ thống nhất 2 triết lý nền tảng cho Dashboard này:
5. Cá Nhân Hóa theo Vai trò: Dashboard này sẽ tự động "biến hình", hiển thị các công cụ và thông tin phù hợp nhất với vai trò của người đang đăng nhập. Một bác sĩ sẽ thấy một giao diện khác hoàn toàn so với một dược sĩ.
6. Bố cục Bento Grids: Để giao diện trở nên hiện đại, sạch sẽ và dễ bao quát, chúng ta sẽ sử dụng mô hình "Bento Grids" . Hãy hình dung Dashboard như một chiếc hộp cơm bento của Nhật, nơi mỗi "món ăn" (widget thông tin) được đặt trong một "ngăn" riêng, được sắp xếp một cách khoa học và đẹp mắt.
   Dựa trên hai triết lý này, Dashboard sẽ được chia thành 2 khu vực chính.
   Khu vực 1: "Quảng trường Chung" - Bảng Tin Nội bộ (Hiển thị cho MỌI VAI TRÒ)
   Đây là khu vực chiếm vị trí trung tâm, là trái tim giao tiếp của công ty, giúp mọi người, dù ở vị trí nào, cũng cảm thấy mình là một phần của tập thể .
   Widget 1: Thông báo & Tin tức Nội bộ (Quan trọng nhất)
   • Hiển thị: Các thông báo mới nhất từ ban giám đốc, chính sách mới, quy định an toàn thuốc...
   • Nội dung: Chào đón nhân viên mới, thông tin về các sự kiện chung của công ty (tiệc cuối năm, du lịch...).
   Widget 2: Lịch trực & Lịch làm việc Tuần
   • Hiển thị: Một lịch trực quan cho cả tuần, trả lời nhanh các câu hỏi:
   o Phòng khám: Bác sĩ nào trực hôm nay?
   o Nhà thuốc: Dược sĩ nào phụ trách ca sáng/chiều/tối?
   o Phòng tiêm: Lịch làm việc của đội ngũ điều dưỡng.
   • Giá trị: Giúp các bộ phận dễ dàng phối hợp. Lễ tân biết chính xác bác sĩ nào đang có mặt để đặt lịch.
   Widget 3: Khen thưởng & Vinh danh (Góc Tỏa Sáng)
   • Hiển thị: Công khai ghi nhận những đóng góp xuất sắc, ví dụ:
   o "Chúc mừng Dược sĩ Lan đã nhận được phản hồi 5 sao từ khách hàng!"
   o "Tuyên dương đội ngũ Marketing đã đạt 200 lượt đặt lịch mới."
   • Giá trị: Tác động cực lớn đến tinh thần làm việc và xây dựng văn hóa tích cực.
   Khu vực 2: "Buồng Lái Cá Nhân" - Không Gian Làm Việc Theo Vai Trò
   Bên dưới "Quảng trường Chung", mỗi nhân viên sẽ thấy một khu vực được "may đo" riêng cho công việc hàng ngày của mình.
   A. Dành cho Lễ tân - "Trung tâm Điều phối Dịch vụ"
   • Widget chính: Bảng điều khiển Lịch hẹn (Dạng cột)
   o Hiển thị: Giao diện làm việc 90% thời gian của Lễ tân. Mỗi cột là một bác sĩ hoặc một phòng chức năng (BS. Minh, BS. Lan, Phòng Siêu Âm...).
   o Mỗi cuộc hẹn là một "khối" được mã hóa màu sắc theo trạng thái:
    Xám: Chưa xác nhận
    Xanh Dương: Đã xác nhận
    Xanh Lá: Đã check-in (Bệnh nhân đã đến)
    Vàng: Đang khám
    Tím: Đã hoàn tất (Chờ thanh toán)
    Đỏ: Hủy/Không đến
   B. Dành cho Dược sĩ - "Buồng lái Tư vấn & Bán hàng – Nâng cao phát triển bản thân"
   • Widget 1: Đơn thuốc mới từ Phòng khám
   o Hiển thị: Một danh sách các đơn thuốc điện tử vừa được bác sĩ kê, đang chờ xử lý. Đây là sự kết nối thông tin trực tiếp, giải quyết triệt để sự đứt gãy thông tin giữa phòng khám và nhà thuốc.
   Widget 2 (Mới): "Nhiệm vụ Chăm sóc Khách hàng Hôm nay"
   • Mục đích: Biến Dược sĩ từ người bán hàng bị động thành một chuyên viên chăm sóc sức khỏe chủ động. Widget này sẽ là "bộ não" nhắc nhở họ cần tương tác với những khách hàng nào trong ngày.
   • Hệ thống tự động gợi ý: Danh sách này không phải do quản lý giao, mà do hệ thống tự động tạo ra dựa trên các quy tắc thông minh:
   o Khách hàng vừa mua một liệu trình thuốc mới (cần gọi hỏi thăm về tác dụng phụ).
   o Khách hàng có bệnh mạn tính sắp hết thuốc (nhắc nhở tái khám hoặc mua liều tiếp theo).
   o Khách hàng vừa mua "Gói 3 mũi tiêm" và sắp đến lịch tiêm mũi tiếp theo.
   • Hiển thị: Một danh sách công việc rõ ràng và có thể hành động ngay.
   o [Gọi điện] Anh Nguyễn Văn A - Hỏi thăm tình hình sử dụng thuốc huyết áp mới mua 3 ngày trước.
   o [Gửi Zalo] Chị Trần Thị Lan - Nhắc lịch tiêm mũi HPV thứ 2 vào tuần tới.
   o [Ghi chú] Cháu B - Đã đến lịch mua lại Vitamin D3 K2.
   Widget 3 (Mới): "Chương trình Bán hàng Trọng tâm"
   • Mục đích: Cung cấp cho Dược sĩ "vũ khí" bán hàng hàng ngày. Thay vì phải nhớ tất cả các chương trình khuyến mại, widget này sẽ làm nổi bật những gì quan trọng nhất cần tập trung trong ngày/tuần.
   • Hiển thị: Dạng các thẻ (card) trực quan, bắt mắt:
   o 🔥 HÔM NAY: Tư vấn "Gói Chăm Sóc Bé Ốm Mùa Tựu Trường" - Giảm 15% cho khách hàng VIP.
   o 💡 GỢI Ý BÁN KÈM: Khi bán Kháng sinh, chủ động tư vấn thêm Men vi sinh để hỗ trợ tiêu hóa.
   o ✨ SẢN PHẨM MỚI: TPCN Bổ não ABC vừa về hàng, tìm hiểu ngay để tư vấn cho khách hàng.
   Widget 4 (Mới): "Góc Đào tạo & Nâng cao Chuyên môn"
   • Mục đích: Thúc đẩy văn hóa học hỏi liên tục, giúp đội ngũ Dược sĩ luôn cập nhật các kiến thức mới nhất.
   • Hiển thị: Một danh sách các bài đào tạo ngắn hoặc các thông tin quan trọng cần đọc, được lấy từ module "Quản lý Nhân sự & Đào tạo".
   o [ĐỌC NGAY - 5 phút] Hướng dẫn sử dụng thuốc X mới.
   o [XEM VIDEO - 10 phút] Kỹ năng xử lý khi khách hàng phàn nàn.
   o [LÀM BÀI TEST] Bài kiểm tra kiến thức sản phẩm tháng 8.

C. Dành cho Bác sĩ & Điều dưỡng - "Trung tâm Chỉ huy Lâm sàng"
• Widget 1: Hàng đợi Bệnh nhân (Patient Queue)
o Hiển thị: Một danh sách cập nhật "sống", cho thấy những bệnh nhân nào đã được Lễ tân check-in và đang ngồi chờ đến lượt mình. Bác sĩ biết chính xác bệnh nhân tiếp theo là ai.
• Widget 2: Hộp thư Kết quả Cận lâm sàng
o Hiển thị: Các kết quả xét nghiệm, siêu âm, X-quang mới nhất vừa được trả về. Hệ thống có thể tự động tô đỏ những kết quả có chỉ số bất thường nguy hiểm, giúp bác sĩ ưu tiên xem xét các trường hợp khẩn cấp.
Giao diện của Widget 2 này như sau:
Giao diện "Hộp Thư Kết Quả" & Quy trình Xử lý
A. "Hộp Thư Kết Quả" (Results Inbox) - Cổng Tiếp Nhận Thông Tin Tập Trung
Triết lý thiết kế: Tất cả các kết quả mới (xét nghiệm, siêu âm...) sẽ không đổ thẳng vào từng hồ sơ bệnh nhân riêng lẻ. Thay vào đó, chúng sẽ được tập trung tại một "Hộp thư Kết quả" chung trên
Dashboard của bác sĩ. Cách làm này đảm bảo mọi kết quả mới đều phải đi qua một điểm kiểm soát duy nhất, không có gì bị "lạc trôi".

1. Hệ thống Thông báo Không Gây Gián đoạn:
   • Trên thanh công cụ chính của ứng dụng, sẽ có một biểu tượng hình chuông (🔔) hoặc hộp thư (📥) kèm theo một con số màu đỏ, báo hiệu số lượng kết quả mới, chưa xem. Ví dụ: 📥 15.
   • Đây là cách thông báo cực kỳ tinh tế, giúp bác sĩ biết có việc cần xử lý nhưng không làm họ mất tập trung khi đang khám cho một bệnh nhân khác.
2. Giao diện "Hộp thư Kết quả" - Sàng lọc Thông minh theo Mức độ Ưu tiên:
   • Khi bác sĩ nhấp vào biểu tượng thông báo, họ sẽ được đưa đến một giao diện giống như một hộp thư email hiện đại.
   • Đây là chức năng cốt lõi và thông minh nhất: Hệ thống sẽ tự động đọc và sắp xếp tất cả các kết quả mới theo mức độ khẩn cấp, đảm bảo bác sĩ luôn nhìn thấy những gì nguy hiểm nhất đầu tiên.
   o 🔴 KHẨN CẤP (Nằm trên cùng, nền đỏ): Các kết quả có giá trị nguy hiểm đến tính mạng (panic values), ví dụ như Kali máu quá cao/thấp, đường huyết quá thấp. Hệ thống được lập trình sẵn các ngưỡng nguy hiểm này.
   o 🟡 BẤT THƯỜNG (Nằm ở giữa, nền vàng): Các kết quả nằm ngoài khoảng tham chiếu bình thường nhưng chưa tới mức nguy cấp.
   o ⚪ BÌNH THƯỜNG (Nằm dưới cùng): Các kết quả trong giới hạn bình thường.
   • Với cách sắp xếp này, bác sĩ chỉ cần liếc mắt là biết ngay phải xem kết quả của bệnh nhân nào trước tiên, tối đa hóa sự an toàn.
   B. Giao diện Xem Kết Quả Chi Tiết - Tùy biến theo Từng Loại
   Khi bác sĩ nhấp vào một kết quả từ Hộp thư, một giao diện chi tiết sẽ hiện ra, được "may đo" riêng cho từng loại kết quả.
3. Đối với Kết quả Xét nghiệm (Máu, nước tiểu...):
   • Hiển thị dạng bảng, có so sánh: Thay vì chỉ hiển thị con số của lần này, hệ thống sẽ tự động đặt nó bên cạnh kết quả của lần xét nghiệm trước đó, giúp bác sĩ thấy ngay sự thay đổi.
   o Tên chỉ số: Glucose
   o Kết quả: 150 mg/dL (Tự động tô màu đỏ vì cao hơn ngưỡng)
   o Khoảng tham chiếu: 70 - 100
   o Kết quả lần trước: 142 (ngày dd/mm/yy)
   • Biểu đồ Xu hướng (Trending): Bên cạnh mỗi chỉ số quan trọng, sẽ có một biểu tượng đồ thị nhỏ
   [ 📈 ]. Khi nhấp vào, một biểu đồ đường (line chart) sẽ hiện ra, trực quan hóa sự thay đổi của chỉ số này qua nhiều lần xét nghiệm, giúp bác sĩ nhận ra xu hướng (đang tốt lên hay xấu đi) thay vì chỉ nhìn vào một con số đơn lẻ.
4. Đối với Kết quả Chẩn đoán Hình ảnh (X-quang, Siêu âm...):
   • Bố cục 2 khung song song:
   o Khung bên trái - Bản tường thuật của Chuyên gia: Hiển thị đầy đủ văn bản kết quả do bác sĩ chẩn đoán hình ảnh đọc. Phần
   KẾT LUẬN sẽ được đóng khung đậm, dễ thấy nhất. Hệ thống cũng có thể tự động tô đậm các từ khóa quan trọng như "tổn thương", "nghi ngờ", "bất thường"...
   o Khung bên phải - Trình xem ảnh (Image Viewer): Hiển thị hình ảnh gốc (X-quang, CT...). Cung cấp các công cụ cơ bản như Zoom, Kéo ảnh, Điều chỉnh độ sáng/tương phản. Điều này cho phép bác sĩ lâm sàng tự mình xem xét hình ảnh cùng lúc với việc đọc bản tường thuật.
   C. Khu Vực Hành Động và Xử Lý - "Con dấu" Trách nhiệm
   Ở cuối mỗi giao diện xem kết quả, sẽ có một khu vực để bác sĩ hành động, hoàn tất quy trình.
   • Diễn giải & Ghi chú của Bác sĩ: Một ô văn bản để bác sĩ ghi lại nhận định của mình. Ghi chú này sẽ được lưu cùng với kết quả.
   • Các nút hành động:
   o [ ✓ ĐÃ XEM & KÝ NHẬN ]: Đây là hành động quan trọng nhất, tương đương với chữ ký của bác sĩ. Nó xác nhận rằng bác sĩ đã xem và chịu trách nhiệm với kết quả này. Kết quả sẽ được chuyển từ trạng thái "Mới" sang "Đã xem".
   o [ Tạo Tác vụ ]: Cho phép tạo nhanh một công việc liên quan, ví dụ: [Dropdown: Gọi điện cho Bệnh nhân, Hẹn tái khám, Gửi hội chẩn...].
   Quy trình này đảm bảo rằng không có kết quả nào bị bỏ sót, các kết quả nguy hiểm được ưu tiên xử lý, và mọi kết quả đều được xử lý một cách có hệ thống, an toàn và được ghi nhận lại đầy đủ trong hồ sơ bệnh án.

Giao diện “Đặt Lịch Hẹn” theo thông tin như table dưới đây:
Đây là module biến Lễ tân từ một người nhập liệu đơn thuần thành một "nhân viên điều phối không lưu" chuyên nghiệp, giúp toàn bộ hoạt động của phòng khám và phòng tiêm trở nên liền mạch, hiệu quả.
Chúng ta sẽ cùng nhau mổ xẻ chi tiết giao diện và quy trình nghiệp vụ cho module này, dựa trên bản thiết kế đã có trong tài liệu của chúng ta.
Module "Đặt Lịch Hẹn" - Trung tâm Điều phối Dịch vụ
Bối cảnh: Nhân viên Lễ tân (hoặc người được cấp quyền) nhấn vào nút Đặt Lịch Hẹn trên menu "Kênh Cửa Hàng".
A. Giao diện Chính - "Bảng Điều Khiển Lịch hẹn" (Appointment Dashboard)
Đây là màn hình mà Lễ tân sẽ nhìn vào 90% thời gian làm việc. Nó được thiết kế để cung cấp một cái nhìn tổng quan, trực quan và sống động, không phải là một danh sách nhàm chán.

1. Bố cục Dạng cột Trực quan:
   • Giao diện được thiết kế dạng các cột song song, mỗi cột tương ứng với một "tài nguyên" có thể đặt lịch của phòng khám.
   o Cột 1: BS. Nguyễn Văn Minh (Khám Tổng quát)
   o Cột 2: BS. Trần Thị Lan (Khám Nhi)
   o Cột 3: Phòng Tiêm Chủng
   o Cột 4: Phòng Siêu Âm
2. Các "Khối Lịch hẹn" (Appointment Blocks) được Mã hóa Màu sắc:
   • Mỗi cuộc hẹn là một "khối" (block) nằm trong cột của bác sĩ/phòng ban tương ứng, đúng vào khung giờ đã đặt.
   • Trên mỗi khối sẽ hiển thị thông tin cốt lõi: Tên Bệnh nhân, Lý do hẹn, Số điện thoại.
   • Quan trọng nhất: Màu sắc của khối sẽ tự động thay đổi theo trạng thái, giúp Lễ tân "liếc mắt" là biết ngay tình hình:
   o Màu Xám (Chưa xác nhận): Lịch hẹn mới được tạo.
   o Màu Xanh Dương (Đã xác nhận): Lễ tân đã gọi điện xác nhận.
   o Màu Xanh Lá (Đã check-in): Bệnh nhân đã đến và đang ở phòng chờ.
   o Màu Vàng (Đang khám): Bệnh nhân đã vào phòng khám.
   o Màu Tím (Đã hoàn tất): Bệnh nhân đã khám xong, đang chờ thanh toán.
   o Màu Đỏ (Hủy/Không đến): Lịch hẹn bị hủy.
3. Các Nút chức năng nhanh:
   • [+ Đặt Lịch Hẹn Mới]: Nút lớn, nổi bật nhất trên giao diện.
   • Thanh tìm kiếm bệnh nhân toàn cục: Cho phép tìm nhanh bệnh nhân theo tên hoặc SĐT.
   • Các bộ lọc: Lọc xem lịch theo Ngày hoặc Tuần.
   B. Luồng Công Việc "Đặt Lịch Hẹn Mới" - Quy trình 4 bước Siêu tốc
   Khi Lễ tân nhấn vào nút
   [+ Đặt Lịch Hẹn Mới] hoặc nhấp vào một khoảng trống trên lịch, một cửa sổ pop-up sẽ hiện ra với quy trình 4 Phần được tối ưu hóa cho tốc độ (hiển thị trên 1 trang).
   • Phần 1: Tìm kiếm Bệnh nhân:
   o Một ô tìm kiếm duy nhất. Lễ tân gõ tên hoặc SĐT, hệ thống sẽ gợi ý các bệnh nhân có sẵn.
   o Nếu không tìm thấy, một nút [+ Tạo Bệnh nhân mới] sẽ xuất hiện.
   • Phần 2: Chọn Dịch vụ:
   o Loại hình: [Dropdown: Khám Bệnh | Tiêm Chủng | Siêu âm...]
   o Bác sĩ/Phòng ban: [Dropdown] - Danh sách này sẽ tự động cập nhật dựa trên loại hình đã chọn ở trên.
   • Phần 3: Chọn Thời gian:
   o Hệ thống hiển thị một lịch nhỏ, tự động tô màu và làm mờ các ngày và giờ mà bác sĩ/phòng ban đó đã kín lịch. Lễ tân chỉ cần nhấp vào một ô giờ còn trống. Điều này chặn hoàn toàn việc đặt lịch trùng.
   • Phần 4: Xác nhận và Ghi chú:
   o Ô ghi chú: (Tùy chọn) Bệnh nhân muốn xin giấy nghỉ ốm.
   o Checkbox: [ ✅ ] Gửi tin nhắn SMS/Zalo xác nhận lịch hẹn cho khách hàng.
   o Nút cuối cùng: [XÁC NHẬN LỊCH HẸN].
   Ngay sau khi nhấn nút này, một "khối lịch hẹn" màu xám mới sẽ ngay lập tức xuất hiện trên Bảng điều khiển chính, sẵn sàng cho các bước tiếp theo trong quy trình chăm sóc bệnh nhân.
   Sau đây là những mảnh ghép cuối cùng, biến màn hình Lịch hẹn từ một công cụ xem lịch đơn thuần thành một "trung tâm điều phối" thực thụ, nơi Lễ tân có thể quản lý trọn vẹn vòng đời của một bệnh nhân tại quầy.
4. Chức năng Quản lý Nhanh Hồ sơ Bệnh nhân
   Đây là giao diện được tối ưu riêng cho Lễ tân khi họ cần xem nhanh thông tin của một bệnh nhân.
   • Kích hoạt: Khi Lễ tân nhấp vào tên của một bệnh nhân trên một "khối lịch hẹn" hoặc từ kết quả tìm kiếm.
   • Triết lý thiết kế: Lễ tân sẽ thấy các thông tin hành chính, lịch sử giao dịch và ghi chú phi y tế. Dữ liệu các lần khám sẽ không được hiển thị chi tiết để đảm bảo sự bảo mật.
   • Giao diện Chi tiết (Dạng Tab):
   o Tab 1: Thông tin Hành chính:
    Hiển thị đầy đủ các thông tin như: Họ tên, Ngày sinh, SĐT, Địa chỉ, Thông tin người thân, Thông tin thẻ bảo hiểm….
    Tất cả các trường này đều có thể được chỉnh sửa nhanh chóng ngay tại đây.
   o Tab 2: Lịch sử Hẹn và Sử dụng dịch vụ:
    Liệt kê toàn bộ các cuộc hẹn và sử dụng dịch vụ trong quá khứ và tương lai của bệnh nhân, giúp Lễ tân dễ dàng tra cứu.
   o Tab 3: Công nợ & Thanh toán:
    Hiển thị lịch sử các hóa đơn, các khoản đã trả và công nợ còn lại (nếu có).
   o Tab 4: Ghi chú Lễ tân:
    Một không gian riêng để ghi lại các thông tin phi y tế, hữu ích cho việc chăm sóc khách hàng. Ví dụ:
   "Bệnh nhân VIP", "Thường xuyên đến trễ, cần gọi điện nhắc trước 30 phút", "Ưu tiên sắp xếp vào buổi chiều".
5. Chức năng Check-in và Xếp hàng đợi
   Đây là hành động "chuyển giao" quan trọng nhất trong ngày, kết nối trực tiếp giữa Lễ tân và đội ngũ y tế.
   • Bối cảnh: Bệnh nhân đã đặt lịch hẹn đến phòng khám.
   • Hành động của Lễ tân:
6. Tìm "khối lịch hẹn" của bệnh nhân trên Bảng điều khiển chính.
7. Nhấp vào khối đó và chọn nút [Check-in].
   • "Phép màu" của hệ thống (Phía sau hậu trường):
8. Tại màn hình Lễ tân: "Khối lịch hẹn" của bệnh nhân ngay lập tức chuyển sang màu Xanh Lá, báo hiệu bệnh nhân đã có mặt.
9. Tại màn hình Bác sĩ/Điều dưỡng: Cùng lúc đó, tên của bệnh nhân này sẽ tự động xuất hiện trong widget "Hàng đợi Bệnh nhân" trên Dashboard của họ.
   • Giá trị: Quy trình này tạo ra một hàng đợi điện tử "sống", được cập nhật theo thời gian thực. Bác sĩ biết chính xác có bao nhiêu người đang chờ và ai là người tiếp theo mà không cần Lễ tân phải thông báo thủ công.
10. Chức năng Thanh toán & Giao tiếp Nội bộ
    Đây là các công cụ cuối cùng để hoàn tất một lượt phục vụ.
    • Thanh toán và In hóa đơn:
    o Bối cảnh: Bác sĩ đã khám xong, "khối lịch hẹn" trên màn hình Lễ tân chuyển sang màu Tím (Đã hoàn tất).
    o Hành động của Lễ tân: Nhấp vào khối lịch và chọn [Thanh toán].
    o Hệ thống kết nối: Hành động này sẽ tự động mở Giao diện "Bán hàng POS", và điều quan trọng là giỏ hàng trên giao diện POS sẽ được tự động điền sẵn toàn bộ các chi phí của lần khám đó (phí khám, phí xét nghiệm, tiền thuốc...). Lễ tân chỉ cần xác nhận và thu tiền.
    • Hệ thống Giao tiếp Nội bộ:
    o Mục đích: Cung cấp một kênh trao đổi nhanh, kín đáo và chuyên nghiệp giữa các bộ phận.
    o Giao diện: Một cửa sổ chat nhỏ, đơn giản được tích hợp ngay trên Dashboard của Lễ tân và các bác sĩ.
    o Ví dụ thực tế: Lễ tân có thể gửi tin nhắn nhanh đến màn hình của BS. Minh:
    "BN tiếp theo đã có mặt. BN này là người nhà của GĐ.".
    Giao diện “Bán Hàng POS” theo thông tin như table dưới đây:
    Phần 1: Không Gian Làm Việc POS và Luồng Bán Lẻ Thông Thường
    A. Không Gian Làm Việc Tổng Thể: Tối Ưu Cho Đa Nhiệm
11. Hệ thống Tab bên trong Ứng dụng:
    • Khi Dược sĩ mở giao diện POS, màn hình sẽ bắt đầu với một tab duy nhất có tên [Đơn hàng 1].
    • Ở cuối thanh tab, luôn có một nút [ + ].
    • Ví dụ thực tế: Dược sĩ đang chuẩn bị một đơn thuốc phức tạp cho khách A ở Đơn hàng 1. Một khách B đến và chỉ muốn mua nhanh một hộp vitamin C. Dược sĩ chỉ cần nhấn nút [ + ], một tab [Đơn hàng 2] trống sẽ hiện ra. Họ phục vụ khách B trong 30 giây, hoàn tất và đóng Đơn hàng 2. Ngay lập tức, màn hình quay trở lại Đơn hàng 1 với đầy đủ thông tin của khách A, không có gì bị gián đoạn hay mất mát.
12. Bố cục 3 Khu vực Kinh điển (Trong mỗi Tab):
    • Bên Trái: Giỏ hàng & Thêm sản phẩm.
    • Bên Phải: Khách hàng & Hàng đợi thanh toán.
    • Phía Dưới: Tổng kết & Các công cụ AI.

---

B. Luồng Bán Lẻ Thông Thường (Ví dụ Cụ thể)
Bối cảnh: Dược sĩ Lan đang ở một tab Đơn hàng trống. Một khách hàng quen, chị Mai (35 tuổi), đến mua thuốc cho con trai là bé An (5 tuổi) đang bị ho.
Bước 1: Xác định Khách hàng & Bệnh nhân (Khu vực bên phải)

1. Dược sĩ Lan vào Tab Thông tin Khách hàng Hiện tại.
2. Trong ô tìm kiếm, cô gõ số điện thoại của chị Mai.
3. Hệ thống hiển thị thông tin: "Chị Nguyễn Thị Mai - 35 tuổi - VIP - 1,250 điểm".
4. Dược sĩ Lan chọn chị Mai. Hệ thống hiển thị một pop-up hỏi: "Thuốc này dùng cho ai?"
   o ( ⚫ ) Chị Nguyễn Thị Mai (35 tuổi)
   o ( ⚪ ) Bé Nguyễn Hoàng An (5 tuổi) - (Lấy từ thông tin người thân đã lưu)
   o ( ⚪ ) Một người khác...
5. Cô chọn "Bé Nguyễn Hoàng An (5 tuổi)". Từ giờ, hệ thống biết rằng mọi tư vấn và hướng dẫn sử dụng phải nhắm đến một bệnh nhân 5 tuổi.
   Bước 2: Thêm Sản phẩm vào Giỏ hàng (Khu vực bên trái)
6. Chị Mai đưa ra một hộp "Siro ho Prospan". Dược sĩ Lan dùng máy quét mã vạch.
7. Hành động thông minh của hệ thống: Ngay lập tức, một dòng mới xuất hiện trong giỏ hàng. Đặc biệt, cột "Hướng dẫn sử dụng" tự động hiển thị: "Trẻ 2-6 tuổi: 2.5ml/lần, 2 lần/ngày" vì hệ thống biết bệnh nhân là bé An 5 tuổi.
8. Chị Mai hỏi mua thêm "Nước muối sinh lý". Dược sĩ Lan gõ "nước muối" vào ô tìm kiếm, chọn đúng sản phẩm, và nó được thêm vào giỏ hàng với hướng dẫn sử dụng tương ứng.
   Bảng Giỏ hàng lúc này: | Tên sản phẩm | SL | Đơn giá | Hướng dẫn sử dụng (Tự động theo tuổi) | Thành tiền | | :--- | :- | :--- | :--- | :--- | | Siro ho Prospan | 1 | 80.000đ | Trẻ 2-6 tuổi: 2.5ml/lần, 2 lần/ngày | 80.000đ | | Nước muối sinh lý Fysoline | 2 | 5.000đ | Vệ sinh mũi 2-3 lần/ngày | 10.000đ |
   Bước 3: Hoàn tất Giao dịch (Khu vực bên dưới)
9. Dược sĩ Lan nhìn vào phần tổng kết: TỔNG CỘNG THANH TOÁN: 90.000đ.
10. Cô nhấn vào nút [In Hướng dẫn Sử dụng].
11. Hành động của hệ thống: Máy in bill khổ K80 ngay lập tức in ra 2 mẩu giấy nhỏ:
    o Mẩu 1: Siro ho Prospan - Trẻ 2-6 tuổi: 2.5ml/lần, 2 lần/ngày
    o Mẩu 2: Nước muối sinh lý Fysoline - Vệ sinh mũi 2-3 lần/ngày
    o Cô dễ dàng dập ghim từng mẩu giấy này vào đúng hộp thuốc tương ứng.
12. Chị Mai thanh toán bằng tiền mặt. Dược sĩ Lan nhấn nút lớn [Tiền mặt].
13. Một pop-up hiện ra để nhập số tiền khách đưa và tính tiền thừa.
14. Cô nhấn [Hoàn tất & In hóa đơn].
15. Hành động cuối cùng của hệ thống:
    o Tồn kho của 2 sản phẩm được trừ đi theo thời gian thực.
    o Điểm tích lũy được cộng vào tài khoản của chị Mai.
    o Giao dịch được ghi nhận.
    o Tab Đơn hàng này được đóng lại, màn hình POS trở về trạng thái sẵn sàng.
    Phần 2: Luồng làm việc Tích hợp & Sức mạnh của các Công cụ Tư vấn AI
    A. Luồng làm việc Tích hợp: Xử lý Bệnh nhân từ Phòng khám chuyển sang
    Bối cảnh: Tại module "Phòng khám", Bác sĩ Minh vừa khám xong cho bệnh nhân Nguyễn Văn Bình. Đơn thuốc của ông Bình gồm 2 loại. Bác sĩ nhấn nút "Hoàn tất Khám".
    Bước 1: Bệnh nhân Xuất hiện trong "Hàng đợi Thanh toán" (Tại màn hình POS)
    • Hành động của hệ thống: Ngay tại khoảnh khắc bác sĩ nhấn nút, một "tín hiệu" được gửi đi. Trên màn hình POS của Dược sĩ Lan, trong khu vực bên phải, Tab Hàng đợi Thanh toán từ Phòng khám sẽ tự động cập nhật và một dòng mới xuất hiện:
    o [10 phút trước] Nguyễn Văn Bình - BS. Minh - Chờ thanh toán
    Bước 2: Tải Đơn hàng Tự động với một cú nhấp chuột
    • Hành động của Dược sĩ: Ông Bình đến quầy. Dược sĩ Lan nhấn vào dòng "Nguyễn Văn Bình" trong hàng đợi.
    • "Phép màu" của hệ thống: Một Tab [Đơn hàng 3] mới được tự động mở ra. Điều đặc biệt là, giỏ hàng trong tab này đã được điền sẵn toàn bộ chi phí từ lượt khám của ông Bình, không cần nhập tay bất cứ thứ gì.
    Bảng Giỏ hàng Tự động lúc này:
    Stt Tên Sản phẩm / Dịch vụ Đơn vị SL Đơn giá Hướng dẫn sử dụng Thành tiền Hành động
    1 Dịch vụ: Phí Khám bệnh - BS. Minh Lần 1 200.000đ - 200.000đ Xóa
    2 Thuốc: Amoxicillin 500mg Viên 20 2.500đ Ngày 2 lần, mỗi lần 1 viên sau ăn 50.000đ Xóa
    3 Thuốc: Paracetamol 650mg Viên 10 1.000đ Uống khi sốt > 38.5°C, cách 4-6h 10.000đ Xóa

B. Các Công cụ Tư vấn AI – Hỗ trợ Dược sĩ
Bây giờ, Dược sĩ Lan sẽ sử dụng các công cụ AI để thực hiện vai trò tư vấn và kiểm soát an toàn ở mức cao nhất.
Bước 3: Xác thực Thuốc & Tư vấn Chuyên sâu với AI

1. Xác thực vật lý: Dược sĩ Lan đến kệ lấy 2 loại thuốc. Để đảm bảo an toàn tuyệt đối, cô dùng máy quét quét mã vạch của từng hộp thuốc. Khi quét, hệ thống sẽ đánh một "tích xanh" vào dòng thuốc tương ứng trong giỏ hàng, xác nhận đã lấy đúng thuốc.
2. Sử dụng AI Kiểm tra Tương tác (Tính năng AI số 1):
   o Sau khi đã xác thực thuốc, cô nhấn vào nút [🔬 Kiểm tra Tương tác & Hạn chế].
   o Một cửa sổ pop-up "Phân tích Tham khảo do AI Cung cấp" hiện ra:
3. Tương tác giữa các thuốc:
   o Không tìm thấy tương tác đáng kể giữa Amoxicillin và Paracetamol.
4. Lưu ý về Thực phẩm & Sinh hoạt:
   o Khi dùng Amoxicillin, nếu có tiền sử rối loạn tiêu hóa, nên uống sau bữa ăn no để giảm khó chịu dạ dày.
   o Hạn chế sử dụng rượu bia trong thời gian dùng thuốc.
   Lưu ý: Thông tin này do AI tạo ra chỉ để tham khảo và không thay thế cho phán đoán chuyên môn của Dược sĩ.
5. Sử dụng AI Tính Ngày dùng thuốc (Tính năng AI số 3):
   o Dược sĩ Lan muốn thiết lập một lịch gọi điện chăm sóc khách hàng. Cô cần biết đơn thuốc này sẽ dùng trong bao lâu.
   o Cô nhìn xuống khu vực thanh toán và nhấn nút [🤖 AI Tính toán].
   o Hệ thống gửi "bài toán" cho Gemini: "Một đơn thuốc gồm: Amoxicillin 500mg, số lượng 20 viên, hướng dẫn 'Ngày 2 lần, mỗi lần 1 viên'. Paracetamol 650mg, số lượng 10 viên, hướng dẫn 'Uống khi sốt'. Hãy tính số ngày dùng hết thuốc chính."
   o Gemini trả lời: AI sẽ tập trung vào thuốc điều trị chính là kháng sinh và tính toán: 20 viên / (2 lần/ngày \* 1 viên/lần) = 10 ngày.
   o Kết quả: Con số 10 được tự động điền vào ô Dự kiến số ngày dùng hết thuốc. Dược sĩ Lan giờ đây có thể tự tin tư vấn cho ông Bình và hệ thống cũng đã có dữ liệu để tự động nhắc lịch chăm sóc sau này.
   Bước 4: Hoàn tất
   • Dược sĩ Lan nhấn [In Hướng dẫn Sử dụng] để lấy các mẩu giấy K80 dập ghim vào thuốc.
   • Cuối cùng, cô hoàn tất thanh toán cho ông Bình như bình thường.
   Giao diện “Danh sách Đơn hàng [Kênh cửa hàng]” theo thông tin như table dưới đây:
   Giao diện "Danh sách Đơn hàng" (Kênh Cửa Hàng)
   Bối cảnh: Người quản lý cửa hàng, Dược sĩ hoặc Lễ tân truy cập từ menu Kênh Cửa Hàng -> Danh sách Đơn hàng.
   A. Giao diện Tổng quan & Công cụ Quản lý
   Đây là trung tâm để xem và thao tác với các giao dịch. Giao diện được phân trang.
6. Công cụ Lọc & Tìm kiếm mạnh mẽ:
   o Tìm kiếm: Theo Mã Đơn Hàng, Tên Khách hàng, SĐT, Tên Sản phẩm đã bán...
   o Bộ lọc chi tiết:
    Ngày tạo: [Chọn khoảng thời gian]
    Trạng thái: [Dropdown: Hoàn tất, Đã hủy, Thanh toán thiếu...]
    Người tạo: [Dropdown chọn nhân viên]
    Kho/Cửa hàng: [Dropdown chọn chi nhánh]
    Phương thức Thanh toán: [Checkbox: Tiền mặt, Thẻ, Chuyển khoản...]
7. Các nút hành động chính:
   o [Nhập từ Excel]: Dành cho việc di dời dữ liệu đơn hàng cũ từ hệ thống khác vào Nam Việt ERP.
   o [Xuất ra Excel]: Công cụ cực kỳ quan trọng, cho phép người quản lý xuất ra toàn bộ danh sách đơn hàng đã lọc để làm báo cáo tùy chỉnh hoặc đối soát chi tiết.
8. Thanh hành động hàng loạt (Bulk Actions):
   o Xuất hiện khi người dùng tick chọn vào một hoặc nhiều đơn hàng, cho phép xử lý nhanh:
    [Nộp tiền cho Kế toán]: Chức năng dành cho cuối ca. Dược sĩ/Thu ngân chọn tất cả các đơn hàng tiền mặt và nhấn nút này để tạo một biên bản bàn giao, xác nhận số tiền mặt đã nộp cho bộ phận kế toán.
    [In hóa đơn hàng loạt]: In lại hóa đơn cho các giao dịch đã chọn.
    [Hủy đơn hàng]: Hủy các giao dịch đã chọn (yêu cầu quyền của quản lý).
   B. Bảng Danh sách Đơn hàng Chi tiết
   Bảng dữ liệu sẽ hiển thị một cái nhìn tổng quan nhưng đầy đủ về mỗi giao dịch.
   [Checkbox] Mã Đơn Hàng Tên Khách hàng Người tạo Kho/Cửa hàng Ngày tạo Tổng Giá trị Trạng thái Vận hành Trạng thái Thanh toán Hành động
   [ ] DH00126 Anh Nguyễn Văn An Dược sĩ Lan Nhà thuốc ĐH 1 30/08/2025 90.000đ ✅ Hoàn tất 🟢 Đã thanh toán [Xem] [In] [Hủy]
   [ ] DH00127 Chị Trần Thị B Lễ tân Mai Phòng khám ĐH 30/08/2025 350.000đ ✅ Hoàn tất 🟠 Thanh toán thiếu [Xem] [In] [Hủy]
   [ ] DH00128 Khách vãng lai Dược sĩ Lan Nhà thuốc ĐH 1 30/08/2025 120.000đ 🔴 Đã hủy - [Xem]
   Giải thích chi tiết các cột Trạng thái:
   • Trạng thái Vận hành:
   o ✅ Hoàn tất: Giao dịch đã diễn ra thành công, hàng đã giao cho khách.
   o 🔴 Đã hủy: Giao dịch đã bị hủy.
   • Trạng thái Thanh toán:
   o 🟢 Đã thanh toán: Khách hàng đã trả đủ tiền.
   o 🟠 Thanh toán thiếu: Khách hàng còn nợ lại một khoản nhỏ.
   o 🔴 Chờ thanh toán: Áp dụng cho các đơn hàng từ phòng khám đã tạo ra chi phí nhưng khách chưa thực hiện thanh toán tại quầy.
   C. Luồng Công Việc "Hủy Đơn hàng" - Đảm bảo An toàn Dữ liệu Kho
   Đây là quy trình nghiệp vụ quan trọng nhất trong giao diện này, đảm bảo việc "sửa sai" không gây ra hỗn loạn cho tồn kho.
   • Bối cảnh: Một giao dịch bị nhập nhầm và cần được hủy.
   • Hành động: Người quản lý tìm đến đơn hàng DH00126, tick chọn và nhấn nút [Hủy đơn hàng].
   • Bước xác thực an toàn: Một cửa sổ pop-up sẽ hiện ra, yêu cầu xác nhận và có thể yêu cầu nhập mật khẩu của cấp quản lý để đảm bảo chỉ người có thẩm quyền mới được thực hiện hành động quan trọng này.
   • "Phép màu" của hệ thống phía sau hậu trường:
9. Trạng thái Vận hành của đơn hàng DH00126 được chuyển thành "🔴 Đã hủy".
10. Quan trọng nhất, hệ thống sẽ tự động tạo ra một giao dịch kho ngược (reverse transaction), cộng trả lại chính xác số lượng sản phẩm của đơn hàng đó vào tồn kho của Nhà thuốc ĐH 1.
11. Nếu khách hàng có tích điểm từ đơn hàng này, số điểm đó cũng sẽ bị trừ đi.
    Giao diện “Sàn TMĐT” theo thông tin như table dưới đây:
    Phần 1: Nền tảng Kiến trúc & Quy trình Kết nối Ban đầu
    Trước khi đi vào giao diện quản lý hàng ngày, điều quan trọng nhất là chúng ta phải xây dựng một nền tảng kết nối thông minh và bền vững.
    A. Kiến trúc "Cổng Tích hợp Chiến lược" (Strategic Integration Gateway)
    Để tránh việc hệ thống của chúng ta trở nên phức tạp và khó bảo trì mỗi khi một sàn TMĐT (Shopee, Lazada...) thay đổi API của họ, chúng ta sẽ áp dụng một kiến trúc thông minh đã được vạch ra: xây dựng một
    "Cổng Tích hợp" chuyên dụng.
    • Phiên dịch công nghệ: Hãy hình dung thế này: Shopee, Lazada, Tiki, mỗi sàn giống như một quốc gia có một kiểu "ổ cắm điện" khác nhau. Thay vì phải chế tạo 3 loại "phích cắm" riêng cho hệ thống ERP của chúng ta, chúng ta sẽ chế tạo một "bộ chuyển đổi du lịch đa năng" (chính là "Cổng Tích hợp"). "Bộ chuyển đổi" này có thể cắm được vào mọi loại ổ cắm.
    • Giá trị chiến lược: Khi trong tương lai người dùng muốn kết nối thêm với TikTok Shop hay một sàn mới nổi nào đó, chúng ta chỉ cần nâng cấp nhẹ "bộ chuyển đổi" này mà không cần phải đụng chạm hay thay đổi lõi của hệ thống ERP. Điều này giúp việc mở rộng kinh doanh trong tương lai trở nên
    nhanh hơn, rẻ hơn và an toàn hơn rất nhiều.
    B. Giao diện và Quy trình Kết nối Kênh Bán hàng (Thao tác một lần)
    Để quản lý các "kết nối" này, chúng ta sẽ có một giao diện cài đặt.
    Giao diện "Quản lý Kênh Bán Hàng TMĐT":
    • Truy cập từ: Kênh Cửa Hàng -> Sàn TMĐT -> Cài đặt Kết nối.
    • Hiển thị: Một danh sách các sàn TMĐT mà hệ thống hỗ trợ.
    Tên Kênh Trạng thái Hành động
    Shopee 🔴 Chưa kết nối [ 🔗 Kết nối ]
    Lazada 🔴 Chưa kết nối [ 🔗 Kết nối ]
    Tiki 🔴 Chưa kết nối [ 🔗 Kết nối ]
    Luồng công việc Kết nối (Ví dụ với Shopee):
12. Bước 1: Người quản trị hệ thống (Admin) nhấn vào nút [ 🔗 Kết nối ] ở dòng Shopee.
13. Bước 2: Hệ thống sẽ chuyển hướng người dùng đến trang đăng nhập của Shopee Open Platform. Đây là một quy trình xác thực an toàn và tiêu chuẩn.
14. Bước 3: Người dùng sẽ đăng nhập bằng tài khoản bán hàng Shopee của Nam Việt và cấp quyền cho ứng dụng Nam Việt ERP truy cập vào các thông tin cần thiết (như quản lý sản phẩm, đơn hàng...).
15. Bước 4: Sau khi cấp quyền thành công, Shopee sẽ tự động chuyển hướng người dùng trở lại hệ thống Nam Việt ERP.
16. Kết quả: Dòng Shopee trong Giao diện "Quản lý Kênh" sẽ tự động cập nhật:
    Tên Kênh Trạng thái Hành động
    Shopee ✅ Đã kết nối (Tên shop: DuocNamViet.Official) [ ⚙️ Cấu hình ] [ Hủy kết nối ]

GIAO DIỆN CHÍNH CỦA PHẦN NÀY:
Giao diện này sẽ được thiết kế với 3 Tab chức năng chính, giúp dễ dàng quản lý mọi khía cạnh: Tổng quan, Quản lý Sản phẩm, và Quản lý Đơn hàng.
Tab 1: "Tổng quan" - Trạm Quan sát Sức khỏe Hệ thống
Đây là màn hình đầu tiên, cung cấp cho người dùng một cái nhìn tổng thể và nhanh chóng về tình trạng của tất cả các kênh bán hàng trực tuyến.

1. Khu vực Trạng thái Kết nối:
   • Mỗi kênh đã kết nối (Shopee, Lazada...) sẽ được hiển thị như một "thẻ" (card) trạng thái riêng biệt.
   SHOPEE ✅ Đã kết nối - Shop: DuocNamViet.Official Đồng bộ lần cuối: 2 phút trước
   LAZADA ✅ Đã kết nối - Shop: Dược Nam Việt Flagship Đồng bộ lần cuối: 3 phút trước
2. Khu vực Nhật ký Đồng bộ hóa Gần đây:
   • Đây là một danh sách cập nhật "sống", cho người dùng thấy chính xác những gì đang diễn ra giữa Nam Việt ERP và các sàn.
   o [10:35] [Shopee] - [Đơn hàng Mới] - Đơn hàng #SHOPEE-123456 đã được nhập thành công vào hệ thống.
   o [10:34] [Lazada] - [Cập nhật Tồn kho] - Tồn kho cho sản phẩm "Vitamin C" đã được cập nhật thành 150.
   o [10:33] [Shopee] - [Lỗi Đồng bộ] - Không thể cập nhật tồn kho cho sản phẩm "XYZ" (Lỗi: SKU không khớp).

Tab 2: "Quản lý Sản phẩm" - Cầu nối Giữa Kho và Sàn
Đây là nơi người dùng quyết định sản phẩm nào sẽ được bán online và đảm bảo dữ liệu luôn nhất quán.
• Mục đích: "Ánh xạ" (map) sản phẩm trong kho của người dùng với sản phẩm đang được niêm yết trên sàn.
• Bảng Quản lý Sản phẩm:
Sản phẩm (Trong ERP) SKU (ERP) Sản phẩm (Trên Shopee) Trạng thái Hành động
Vitamin C 500mg VTC-500 Vitamin C Dược Nam Việt Chính Hãng ✅ Đã liên kết [Xem] [Đồng bộ ngay]
Panadol Extra PAN-EXT (Chưa liên kết) 🟠 Chưa liên kết [🔗 Liên kết Sản phẩm]
Siro ho ABC SIRO-ABC (Chưa có trên sàn) ⚪ Chưa đăng [🚀 Đẩy Sản phẩm Lên Sàn]

• Các Hành động Chính:
o [🔗 Liên kết Sản phẩm]: Khi người dùng có một sản phẩm đã tồn tại trên cả ERP và Shopee, nút này cho phép người dùng "nối" chúng lại với nhau.
o [🚀 Đẩy Sản phẩm Lên Sàn]: Khi người dùng có một sản phẩm mới trong kho và muốn bán nó trên Shopee, nút này sẽ tự động lấy thông tin (tên, mô tả, ảnh, giá, tồn kho) từ Nam Việt ERP để tạo một niêm yết mới trên Shopee.
o [Đồng bộ ngay]: Cho phép người dùng chủ động đẩy các thông tin mới nhất (đặc biệt là giá và tồn kho) của một sản phẩm từ ERP lên sàn ngay lập tức.

Tab 3: "Quản lý Đơn hàng" - Hợp nhất Dòng chảy Giao dịch
Đây là nơi giải quyết bài toán quản lý đơn hàng từ nhiều kênh khác nhau.
• Cơ chế hoạt động: "Cổng Tích hợp" của chúng ta sẽ tự động quét và kéo các đơn hàng mới từ Shopee, Lazada... về hệ thống theo chu kỳ (ví dụ: mỗi 5 phút).
• Bảng Quản lý Đơn hàng TMĐT: Giao diện này sẽ trông rất quen thuộc, tương tự như "Danh sách Đơn hàng" mà chúng ta đã thiết kế, nhưng được bổ sung để nhận diện nguồn gốc đơn hàng.
Mã Đơn Hàng (Sàn) Kênh Bán Tên Khách hàng Ngày tạo Tổng Giá trị Trạng thái (Sàn)
#SHOPEE-123456 SHOPEE Nguyễn Văn An 30/08/2025 150.000đ Chờ lấy hàng
#LAZADA-654321 LAZADA Trần Thị B 30/08/2025 280.000đ Chờ xác nhận

• Tích hợp vào Luồng Vận hành:
o Quan trọng nhất: Khi một đơn hàng mới từ Shopee được kéo về, hệ thống sẽ tự động tạo ra một đơn hàng tương ứng trong Nam Việt ERP và gửi thẳng đến bộ phận Kho.
o Nhân viên kho của người dùng sẽ nhìn thấy đơn hàng Shopee này xuất hiện trong Dashboard của họ, với trạng thái "🔵 Chờ đóng gói", nằm chung một hàng đợi với các đơn hàng B2B khác.
o Toàn bộ quy trình đóng gói, xác thực bằng mã vạch, và giao cho đơn vị vận chuyển sẽ diễn ra y hệt như một đơn hàng B2B.

Tổng kết
Với "Bảng điều khiển Đồng bộ hóa" này, chúng ta có 1 giao diện để làm chủ toàn bộ hoạt động kinh doanh trên các sàn TMĐT. Nó giúp người dùng:
• Tiết kiệm thời gian: Loại bỏ hoàn toàn việc đăng nhập vào nhiều trang quản trị khác nhau.
• Đảm bảo nhất quán: Tồn kho và giá cả luôn được đồng bộ, tránh tình trạng "hủy đơn vì hết hàng".
• Tối ưu hóa Vận hành: Đơn hàng từ mọi kênh đều chảy về một luồng xử lý duy nhất tại kho, giúp tối ưu hóa nhân lực và quy trình.

b. Menu “Nghiệp vụ Y Tế”: sẽ bao gồm các nút con:
• Dashboard Y Tế (Giao diện của phần này chính là giao diện của “Dashboard Cửa hàng”, chỉ khác tên gọi).
• Phòng Khám
• Tiêm Chủng
Chi tiết giao diện các nút như sau:
Giao diện “Dashboard Y Tế” : Như đã mô tả trước đó
Giao diện “Phòng Khám” như table dưới đây:
Phần 1: Nền Tảng - Giao diện Hồ Sơ Bệnh Án Điện Tử (EMR) 360 độ
Đây là giao diện gốc, là "cuốn bách khoa toàn thư" về sức khỏe của một bệnh nhân. Nó phải cung cấp cho bác sĩ một cái nhìn tổng thể, đầy đủ và có hệ thống chỉ trong vài giây.
Bối cảnh: Bác sĩ đăng nhập vào hệ thống. Trên Dashboard Y Tế của mình, họ nhìn vào widget "Hàng đợi Bệnh nhân" và nhấp vào tên của bệnh nhân đang chờ khám. Hành động này sẽ mở ra giao diện Hồ sơ Bệnh án Điện tử (EMR).
Giao diện EMR sẽ được chia thành 3 khu vực chính.
Khu vực 1: Thanh Thông tin Bệnh nhân & Cảnh báo Khẩn cấp (Patient Banner)
Đây là một thanh thông tin nằm ở vị trí trên cùng,
luôn cố định và không bao giờ bị cuộn mất, đảm bảo bác sĩ luôn biết họ đang làm việc trên hồ sơ của ai.
• Thông tin định danh: Họ và Tên, Tuổi (tính chính xác đến ngày), Giới tính, Mã Bệnh nhân.
• KHUNG CẢNH BÁO MÀU ĐỎ: Nằm ở góc trên cùng, dễ thấy nhất, với chữ lớn và biểu tượng cảnh báo. Đây là khu vực không bao giờ được bỏ qua, hiển thị các thông tin sống còn:
o DỊ ỨNG: Sốc phản vệ với Penicillin, Dị ứng Aspirin.
o TÌNH TRẠNG NGUY HIỂM: Bệnh nhân đang dùng thuốc chống đông, Suy thận giai đoạn cuối.
Khu vực 2: Tổng quan Bệnh án (Medical Summary)
Ngay bên dưới thanh thông tin, khu vực này cung cấp một bản tóm tắt "siêu tốc" về tình trạng sức khỏe của bệnh nhân.
• Danh sách Vấn đề (Problem List):
o Liệt kê các chẩn đoán, bệnh mạn tính đang hoạt động của bệnh nhân. Đây là bản tóm tắt sức khỏe quan trọng nhất.

1. Tăng huyết áp (Từ 2015)
2. Đái tháo đường Type 2 (Từ 2018)
   • Danh sách Thuốc đang dùng (Current Medication List):
   o Liệt kê tất cả các loại thuốc bệnh nhân đang sử dụng thường xuyên.
3. Amlodipin 5mg (1 viên/sáng)
4. Metformin 850mg (2 viên/ngày)
   Khu vực 3: Dòng Thời Gian Y Tế (The Medical Timeline)
   Đây là phần thân chính của hồ sơ, hiển thị toàn bộ lịch sử khám chữa bệnh của bệnh nhân theo trình tự thời gian từ mới nhất đến cũ nhất. Mỗi lần tiếp xúc y tế là một "sự kiện" trên dòng thời gian này.
   Ngày Loại Sự kiện Tóm tắt Bác sĩ Chi tiết
   04/08/2025 Khám bệnh Đau họng, ho BS. Minh [Xem]
   15/07/2025 Kết quả XN Công thức máu: Bạch cầu tăng Phòng XN [Xem]
   10/01/2025 Khám Tái khám Tăng huyết áp ổn định BS. Minh [Xem]
   20/12/2024 Nhập viện Viêm phổi BV A [Xem]
   • Chức năng thông minh:
   o Bộ lọc: Bác sĩ có thể lọc dòng thời gian này để chỉ xem một loại sự kiện nhất định (ví dụ: chỉ xem tất cả các "Kết quả XN", hoặc tất cả các "Đơn thuốc" đã kê).
   o Biểu đồ trực quan: Sẽ có một tab riêng để biểu diễn sự thay đổi của các chỉ số quan trọng qua thời gian (ví dụ: biểu đồ đường huyết, biểu đồ huyết áp).
   Với nền tảng thông tin vững chắc và có cấu trúc này, bác sĩ đã có trong tay một cái nhìn 360 độ về bệnh nhân trước khi bắt đầu cuộc đối thoại. Nó giúp họ nắm bắt bối cảnh nhanh chóng và đưa ra những nhận định ban đầu chính xác hơn.
   Giao diện Lần Khám Bệnh.
   Để đảm bảo quy trình làm việc khoa học, an toàn và hiệu quả, giao diện này sẽ được thiết kế như một "buồng lái thông minh", tuân thủ nghiêm ngặt luồng tư duy y khoa kinh điển: mô hình SOAP.
   • S - Subjective (Thông tin Chủ quan - Bác sĩ là người lắng nghe)
   • O - Objective (Thông tin Khách quan - Bác sĩ là người thăm khám)
   • A - Assessment (Đánh giá - Bác sĩ là người chẩn đoán)
   • P - Plan (Kế hoạch - Bác sĩ là người xử trí)
   Giao diện sẽ có 4 phần chính tương ứng là 4 mục có thể thu gọn/mở rộng. Vì sự chi tiết, giao diện sẽ trình bày qua nhiều phần.
   Phần 2A: Giao diện Lần Khám Bệnh (Phần S và O)
   Đây là giai đoạn thu thập thông tin, nơi hệ thống trợ giúp bác sĩ ghi chép nhanh và chính xác nhất.
   I. Phần S: Subjective - Khai Thác Bệnh Sử (Bệnh nhân kể)
   Đây là nơi ghi lại cuộc đối thoại giữa bác sĩ và bệnh nhân.
5. Lý do đến khám (Chief Complaint):
   • Giao diện: Một ô văn bản duy nhất, nổi bật ở trên cùng để ghi lại lý do chính mà bệnh nhân tìm đến.
   o Ví dụ: "Đau ngực và khó thở khoảng 3 ngày nay".
6. Bệnh sử (History of Present Illness - HPI):
   • Giao diện: Đây là ô văn bản quan trọng nhất. Tuy nhiên, nó không phải là một ô trống trơn.
   • Tính năng thông minh: "Mẫu bệnh sử" (Templates).
   o Sẽ có một menu thả xuống cho phép bác sĩ chọn các mẫu cho những bệnh cảnh thường gặp (Đau ngực, Ho, Sốt...).
   o Ví dụ: Nếu bác sĩ chọn mẫu "Đau ngực", ô văn bản sẽ tự động chèn vào khung sườn OPQRST để bác sĩ điền vào, đảm bảo không bỏ sót thông tin :
    Khởi phát (Onset):
    Yếu tố tăng/giảm (Provocation/Palliation):
    ... (và các yếu tố khác).
7. Tổng quan các hệ cơ quan (Review of Systems - ROS):
   • Giao diện: Để tránh việc gõ quá nhiều, giao diện sẽ có "Sơ đồ cơ thể tương tác".
   • Luồng công việc:
8. Bác sĩ chỉ cần nhấp chuột vào một vùng trên hình ảnh cơ thể người (ví dụ: vùng bụng).
9. Một cửa sổ nhỏ sẽ hiện ra với các triệu chứng liên quan (Buồn nôn, Nôn, Tiêu chảy...). Bác sĩ chỉ cần đánh dấu vào các triệu chứng "dương tính" .
10. Hệ thống sẽ tự động tạo ra một đoạn văn bản tóm tắt dựa trên các lựa chọn này.
    II. Phần O: Objective - Thăm Khám Thực Thể (Bác sĩ khám)
    Đây là nơi ghi lại những gì bác sĩ quan sát và đo lường được.
11. Dấu hiệu sinh tồn (Vital Signs):
    • Giao diện: Các ô nhập liệu rõ ràng cho Nhiệt độ, Huyết áp, Mạch, Nhịp thở, SpO2, chiều cao, cân nặng, chỉ số BMI (được tự động tính)....
    • Tính năng thông minh: "Cảnh báo tự động". Hệ thống sẽ tự động tô màu đỏ các chỉ số nằm ngoài ngưỡng bình thường so với tuổi và giới tính của bệnh nhân, giúp bác sĩ nhận ra các dấu hiệu nguy hiểm ngay lập tức.
12. Thăm khám thực thể (Physical Exam):
    • Giao diện: Được cấu trúc theo từng hệ cơ quan (Tim mạch, Hô hấp, Tiêu hóa...).
    • Tính năng thông minh: "Smart Clicks".
    o Mỗi mục sẽ có các lựa chọn nhanh cho những kết quả bình thường và bất thường hay gặp.
    o Ví dụ, mục "Hô hấp": Nghe phổi: (•) Rì rào phế nang êm dịu [ ] Ran ẩm [ ] Ran rít
    • Tiện ích tiết kiệm thời gian: Một nút "[Tất cả bình thường]" sẽ tự động chọn tất cả các kết quả bình thường, bác sĩ chỉ cần điều chỉnh lại những điểm bất thường mà họ phát hiện.
    III. Phần A: Assessment - Chẩn Đoán
    Đây là phần kết tinh tư duy của bác sĩ sau khi đã tổng hợp tất cả các dữ kiện. Giao diện của chúng ta sẽ giúp quá trình này trở nên nhanh chóng và được chuẩn hóa.
    • Giao diện: Một khu vực có tên "Chẩn đoán / Vấn đề" (Diagnosis / Problem List).
    • Hành động của Bác sĩ: Bác sĩ sẽ gõ vào ô văn bản chẩn đoán sơ bộ của mình.
    • Tính năng thông minh: Tích hợp ICD-10 Tức thì .
    o Khi bác sĩ bắt đầu gõ "Viêm ph...", hệ thống sẽ ngay lập tức hiển thị một danh sách gợi ý các chẩn đoán phù hợp theo danh mục ICD-10 (Phân loại Bệnh tật Quốc tế), là tiêu chuẩn bắt buộc trong y khoa:
     J18.9 - Viêm phổi, không đặc hiệu
     J20.9 - Viêm phế quản cấp, không đặc hiệu
    o Bác sĩ chỉ cần chọn chẩn đoán chính xác từ danh sách.
    • Giá trị:
    o Chuẩn hóa Dữ liệu: Đảm bảo mọi chẩn đoán trong hệ thống đều tuân theo một mã chuẩn quốc tế, cực kỳ quan trọng cho việc báo cáo, thống kê và nghiên cứu sau này.
    o Tiết kiệm Thời gian: Bác sĩ không cần phải nhớ chính xác mã bệnh.
    o Kết nối với Hồ sơ: Bác sĩ có thể tick chọn để thêm chẩn đoán này vào "Danh sách Vấn đề" dài hạn của bệnh nhân mà chúng ta đã thấy ở Phần 1.
    IV. Phần P: Plan - Kế Hoạch Xử Trí
    Đây là module hành động, nơi bác sĩ đưa ra các y lệnh cụ thể. Để đảm bảo sự rõ ràng, khu vực này sẽ được chia thành các Tab chức năng riêng biệt.
    Tab 1: Kê đơn thuốc (e-Prescription)
    • Giao diện: Một công cụ tìm kiếm thuốc thông minh, cho phép bác sĩ tìm thuốc theo tên thương mại hoặc hoạt chất.
    • Hành động: Bác sĩ chọn thuốc, điền số lượng, liều dùng, đường dùng, và thêm vào đơn.
    • "Người Vệ sĩ" AI - Kiểm tra Tương tác thuốc Tự động:
    o Đây là lớp bảo vệ an toàn quan trọng nhất. Mỗi khi một loại thuốc mới được thêm vào đơn, hệ thống sẽ ngay lập tức và tự động đối chiếu với:
13. Danh sách thuốc bệnh nhân đang dùng.
14. Danh sách bệnh nền của bệnh nhân.
15. Danh sách dị ứng đã được ghi nhận.
    o Nếu phát hiện bất kỳ xung đột nào, một CẢNH BÁO LỚN, MÀU ĐỎ sẽ xuất hiện ngay trên màn hình, không thể bỏ qua:
    "⚠️ CẢNH BÁO TƯƠNG TÁC THUỐC NGHIÊM TRỌNG: Thuốc X có thể gây chảy máu khi dùng chung với thuốc chống đông Y mà bệnh nhân đang sử dụng!"
    • Kết nối Vận hành: Sau khi hoàn tất, bác sĩ có thể [In đơn thuốc] hoặc [Gửi đơn thuốc điện tử] thẳng đến màn hình POS của Dược sĩ.
    Tab 2: Chỉ định Cận lâm sàng (Lab & Imaging Orders)
    • Giao diện: Được thiết kế dạng checklist trực quan, không cần gõ nhiều. Các xét nghiệm và chẩn đoán hình ảnh phổ biến sẽ được nhóm theo chuyên khoa (Huyết học, Sinh hóa, X-quang, Siêu âm...).
    • Hành động: Bác sĩ chỉ cần đánh dấu vào các chỉ định cần thiết.
    • Kết nối Vận hành: Khi bác sĩ xác nhận, lệnh chỉ định điện tử sẽ được gửi thẳng đến hệ thống của các phòng ban liên quan (phòng xét nghiệm, phòng siêu âm), giảm thiểu giấy tờ và thời gian chờ đợi.
    Giao diện chi tiết của phần này như sau:
    “” Một giao diện chuyên dụng sẽ hiện ra, được thiết kế theo bố cục hai cột cực kỳ hiệu quả.
    Cột Trái: Danh mục Dịch vụ - Menu Lựa chọn
    Đây là nơi bác sĩ lựa chọn dịch vụ. Nó được tổ chức khoa học để tìm kiếm nhanh nhất có thể.
16. Thanh tìm kiếm "thần thánh":
    • Nằm ở vị trí trên cùng, đây là công cụ mạnh mẽ nhất, cho phép tìm kiếm theo:
    o Tên dịch vụ: gõ "Siêu âm tuyến giáp".
    o Tên viết tắt: gõ "AST", "ALT", "CBC" (Công thức máu).
    o Triệu chứng lâm sàng (tính năng nâng cao): Gõ "đau ngực" có thể gợi ý ra ECG (Điện tâm đồ), Men tim Troponin T, X-quang ngực thẳng.
17. Danh mục được nhóm theo Chuyên khoa:
    • Các dịch vụ được sắp xếp gọn gàng trong các mục có thể thu gọn/mở rộng:
    o Xét nghiệm:
     Huyết học: (Công thức máu, Đông máu cơ bản...)
     Sinh hóa: (Đường huyết, Chức năng gan, Chức năng thận...)
    o Chẩn đoán Hình ảnh:
     Siêu âm: (Bụng tổng quát, Tuyến giáp, Tim...)
     X-quang: (Ngực thẳng, Cột sống, Khớp gối...)
    o ... và các chuyên khoa khác.
18. "Gói Chỉ định" và "Mục ưa thích" (Tính năng tiết kiệm thời gian):
    • Gói Chỉ định (Order Sets): Cho phép tạo các gói xét nghiệm cho những bệnh cảnh thường gặp. Ví dụ:
    o Gói Tầm soát chức năng gan sẽ tự động chọn (AST, ALT, GGT, Bilirubin). Bác sĩ chỉ cần một cú nhấp chuột.
    • Mục ưa thích (Favorites): Mỗi bác sĩ có thể "đánh dấu sao" các chỉ định mình hay dùng nhất để chúng luôn xuất hiện ở trên cùng, không cần tìm kiếm.
    Cột Phải: Phiếu Chỉ định - "Giỏ hàng" Dịch vụ
    Khi bác sĩ nhấp vào một dịch vụ ở cột trái, nó sẽ được thêm vào "giỏ hàng" ở cột phải.
    Thông tin chi tiết cho mỗi chỉ định:
    • Tên dịch vụ: Siêu âm bụng tổng quát
    • Chẩn đoán sơ bộ\*: (Ô bắt buộc) - Hệ thống sẽ tự động điền chẩn đoán từ Phần A (Assessment) mà bác sĩ đã nhập trước đó. Ví dụ: "Theo dõi sỏi túi mật". Điều này cực kỳ quan trọng để cung cấp thông tin cho bác sĩ ở phòng ban khác.
    • Yêu cầu/Lý do chỉ định: (Ô văn bản tùy chọn) Ví dụ: "Bệnh nhân đau hạ sườn phải sau ăn."
    • Hướng dẫn bệnh nhân (tự động): Hệ thống tự động đính kèm các hướng dẫn cần thiết. Ví dụ: với siêu âm bụng, hệ thống sẽ tự thêm dòng chữ:
    "Yêu cầu nhịn ăn ít nhất 6 giờ trước khi thực hiện."
    • Giá tham khảo: Hiển thị chi phí dự kiến để bác sĩ tiện tư vấn cho bệnh nhân.
    • Nút xóa (x): Để loại bỏ một chỉ định khỏi phiếu.
    Hành Động Cuối Cùng
    Ở cuối cột "Phiếu Chỉ định" sẽ có một nút bấm lớn, duy nhất và rõ ràng:
    [ GỬI CHỈ ĐỊNH & IN PHIẾU ]
    Khi bác sĩ nhấn nút này, một loạt các hành động thông minh sẽ được tự động thực thi:
19. Gửi lệnh điện tử: Yêu cầu sẽ được tự động gửi đến hệ thống của phòng xét nghiệm và phòng chẩn đoán hình ảnh, không cần giấy tờ thủ công.
20. Cập nhật trạng thái: Trạng thái của bệnh nhân trên màn hình của Lễ tân và Điều dưỡng có thể tự động cập nhật thành "Chờ thực hiện Cận lâm sàng".
21. Tích hợp thanh toán: Chi phí của các dịch vụ này sẽ tự động được thêm vào hóa đơn của bệnh nhân tại quầy Lễ tân.
22. In phiếu chỉ định: Hệ thống tạo ra một phiếu chỉ định rõ ràng để đưa cho bệnh nhân, trên đó có ghi đầy đủ các dịch vụ và các hướng dẫn chuẩn bị quan trọng.
    Giao diện này không chỉ giúp bác sĩ chỉ định dịch vụ một cách nhanh chóng, chính xác mà còn tự động hóa rất nhiều khâu giao tiếp giữa các phòng ban, giảm thiểu sai sót và nâng cao trải nghiệm chuyên nghiệp cho bệnh nhân. “”
    Tab 3: Tư vấn & Hẹn tái khám
    • Giao diện:
    o Một ô văn bản để bác sĩ ghi lại các nội dung tư vấn, dặn dò quan trọng.
    o Tính năng thông minh: "Thư viện Tài liệu Giáo dục". Hệ thống sẽ có sẵn một thư viện các tài liệu về bệnh lý thường gặp (ví dụ: "Chế độ ăn cho người tăng huyết áp"). Bác sĩ có thể chọn, in ra và đưa cho bệnh nhân, tăng tính chuyên nghiệp và hiệu quả tư vấn.
    o Một công cụ đặt lịch hẹn tái khám nhanh, kết nối trực tiếp với module "Đặt Lịch Hẹn" của Lễ tân.
    V. Thanh Hành Động Cuối Cùng
    Luôn cố định ở cuối giao diện, có hai nút quyết định cuối cùng:
    • [LƯU BẢN NHÁP]: Cho phép lưu lại lần khám đang dang dở để quay lại sau, ví dụ khi cần chờ kết quả cận lâm sàng.
    • [HOÀN TẤT & KÝ SỐ]: Hành động cuối cùng, mang tính pháp lý. Khi nhấn nút này:
23. Toàn bộ ghi chú của lần khám này sẽ được khóa lại, không thể chỉnh sửa.
24. Hệ thống sẽ gắn chữ ký điện tử của bác sĩ vào hồ sơ  Hoặc chỉ cần 1 bản in phiếu khám bệnh, bác sĩ ký vào và bệnh nhân cầm tờ giấy kết quả này để đi về. Còn lại, các thông tin: user bác sĩ, thông tin khám bệnh, etc… vẫn được lưu lại bình thường.
25. Toàn bộ "sự kiện" khám bệnh này sẽ được lưu vĩnh viễn vào "Dòng Thời Gian Y Tế" của bệnh nhân.
    Với giao diện SOAP toàn diện này, mỗi lần khám bệnh không chỉ là một cuộc đối thoại, mà là một quy trình y khoa có cấu trúc, được ghi nhận một cách khoa học, được hỗ trợ bởi các công cụ thông minh và các lớp bảo vệ an toàn, giúp nâng cao chất lượng điều trị và giảm thiểu tối đa sai sót.

Giao diện “Tiêm Chủng” như table dưới đây:
Nếu Phòng Khám là nơi xử lý các tình huống y tế đa dạng, thì Tiêm Chủng là nơi chúng ta xây dựng một quy trình chuyên biệt, với mục tiêu cao nhất là An toàn, Chính xác và Tuân thủ Tuyệt đối. Mọi chi tiết trong giao diện này đều được thiết kế để dẫn dắt nhân viên y tế đi qua một quy trình sàng lọc nghiêm ngặt, không thể bỏ sót.

Phần 1: Nền Tảng - Giao Diện Tiếp Nhận và Thông Tin Tổng Quan
Đây là phần nền móng, là màn hình đầu tiên mà nhân viên y tế tương tác để có được bức tranh toàn cảnh về bệnh nhân trước khi đi vào các câu hỏi sàng lọc chi tiết.
A. Bảng Điều Khiển Chính (Vaccination Dashboard)
Khi đăng nhập, nhân viên tại trung tâm tiêm chủng sẽ thấy một Dashboard được thiết kế như một "dây chuyền" vận hành, mô phỏng đúng quy trình tại phòng tiêm.
• Bố cục 3 cột theo thời gian thực:
o Cột 1: "Hàng Đợi Sàng Lọc": Danh sách bệnh nhân đã đăng ký và đang chờ đến lượt khám sàng lọc.
o Cột 2: "Hàng Đợi Tiêm": Danh sách bệnh nhân đã được bác sĩ duyệt "Đủ điều kiện" và đang chờ điều dưỡng thực hiện tiêm.
o Cột 3: "Đang Theo Dõi Sau Tiêm": Danh sách bệnh nhân đã tiêm xong và đang ở lại theo dõi 30 phút, có đồng hồ đếm ngược cho từng người.
Có 1 nút "Trợ lý Lập kế hoạch Tiêm chủng Tương lai" tại giao diện này, với thông tin chi tiết như chỉ riêng Table dưới đây:
Phần 1: "Trợ lý Lập kế hoạch Tiêm chủng Tương lai" - Tích hợp Tư vấn vào Giao diện Lâm sàng
Chúng ta sẽ không tích hợp AI một cách rời rạc. Thay vào đó, chúng ta sẽ tạo ra một công cụ cố định, một widget thông minh có tên "Trợ lý Kế hoạch Tiêm chủng", được đặt ở một vị trí trang trọng ngay trên Giao diện Thông tin Bệnh nhân (màn hình mà bác sĩ/điều dưỡng nhìn thấy đầu tiên khi bắt đầu sàng lọc).
A. "Bộ não" của Trợ lý AI
Mỗi khi bác sĩ mở hồ sơ của một bệnh nhân, "trợ lý" này sẽ ngay lập tức hoạt động ngầm và phân tích dựa trên 4 nguồn dữ liệu:

1. Tuổi chính xác của bệnh nhân.
2. Toàn bộ Lịch sử Tiêm chủng đã được lưu trong hệ thống.
3. Phác đồ Tiêm chủng Chuẩn của Việt Nam (được nạp vào làm "kiến thức nền" cho AI).
4. Danh sách các "Gói Vắc-xin" và các chương trình khuyến mại đang có hiệu lực trong hệ thống.
   B. Giao diện Widget "Trợ lý Kế hoạch Tiêm chủng"
   Sau khi phân tích, "trợ lý" sẽ trình bày kết quả một cách ngắn gọn, rõ ràng và có tính hành động cao, được chia làm 2 phần như người dùng gợi ý:
   KẾ HOẠCH TIÊM CHỦNG GỢI Ý CHO BÉ AN (12 tháng tuổi)
5. Gợi ý Chuyên môn (Dựa trên Phác đồ & Lịch sử tiêm):
   • ( ) Sởi - Quai bị - Rubella (Mũi 1) - Đúng lịch trong tháng này.
   • ( ) Viêm não Nhật Bản (Mũi 1) - Đúng lịch trong tháng này.
   • ( ) Thủy đậu (Mũi 1) - Đúng lịch trong tháng này.
6. Gợi ý Gói Dịch vụ & Ưu đãi:
   • 💡 Tư vấn: Nam Việt hiện có "Gói Tiêm chủng Vàng cho trẻ 12-18 tháng" bao gồm tất cả các mũi tiêm trên, giúp tiết kiệm 15% chi phí so với tiêm lẻ.
   C. Luồng Tư vấn của Bác sĩ / Điều dưỡng
   • Chủ động và chuyên nghiệp: Giờ đây, sau khi hoàn tất việc sàng lọc cho mũi tiêm hiện tại, bác sĩ có một công cụ cực kỳ mạnh mẽ để tư vấn cho phụ huynh về các bước tiếp theo. Họ không cần phải tra cứu hay nhớ trong đầu.
   • Tư vấn toàn diện: Bác sĩ có thể nói: "Chị ơi, sau mũi tiêm hôm nay, theo đúng phác đồ thì trong tháng này bé nhà mình cần tiêm thêm 3 mũi Sởi, Viêm não Nhật Bản và Thủy đậu. Trung tâm đang có gói Vàng cho độ tuổi của bé, bao gồm cả 3 mũi này và giúp mình tiết kiệm được một khoản chi phí đáng kể đấy ạ."
   • Tương tác trực tiếp: Bác sĩ có thể tick chọn vào các ô vuông ( ) ngay trên widget dựa trên sự đồng ý của phụ huynh để chuẩn bị cho hành động tiếp theo.
   Phần 2: Hành động Ngay Lập tức & Trợ lý AI Hỗ trợ
   I. "Chỉ định" Phác đồ Tiêm chủng Tương lai - Biến Tư vấn thành Kế hoạch
   Bối cảnh: Bác sĩ vừa tư vấn xong cho phụ huynh dựa trên widget "Trợ lý Kế hoạch Tiêm chủng". Phụ huynh đã đồng ý tiêm các mũi tiếp theo hoặc mua gói vắc-xin được đề xuất.
   Luồng hành động của Bác sĩ:
7. Tick chọn: Bác sĩ sẽ tick chọn vào các ô vuông bên cạnh các mũi tiêm được gợi ý mà phụ huynh đã đồng ý.
8. Nhấn nút Hành động: Ngay bên dưới widget "Trợ lý", sẽ có một nút bấm hành động tương tự như khi chỉ định cận lâm sàng: [Tạo Kế hoạch Tiêm chủng].
   Giao diện "Xác nhận Kế hoạch Tiêm chủng Tương lai":
   Khi nhấn nút, một cửa sổ pop-up sẽ hiện ra để bác sĩ xác nhận lần cuối.
   • Bệnh nhân: Bé Nguyễn Hoàng An (12 tháng tuổi)
   • Kế hoạch được tạo:
   o Sởi - Quai bị - Rubella (Mũi 1) - Dự kiến: Tháng 09/2025
   o Viêm não Nhật Bản (Mũi 1) - Dự kiến: Tháng 09/2025
   o Thủy đậu (Mũi 1) - Dự kiến: Tháng 10/2025
   • Tích hợp Gói Dịch vụ (Nếu có):
   o [ ✅ ] Áp dụng "Gói Tiêm chủng Vàng cho trẻ 12-18 tháng"
   • Nút cuối cùng: [Xác nhận & Lưu vào Hồ sơ]
   "Phép màu" của hệ thống phía sau hậu trường:
   • Tạo Lịch trình Cá nhân hóa: Hệ thống sẽ chính thức tạo ra một "Lịch trình Tiêm chủng Cá nhân hóa" cho bệnh nhân này và lưu nó vào hồ sơ của họ.
   • Kích hoạt "Bộ Máy Chăm sóc Tự động": Lịch trình này sẽ ngay lập tức được kết nối với "Bộ Máy Chăm sóc Khách hàng Tự động" mà chúng ta đã thiết kế. Hệ thống sẽ tự động lên lịch gửi các tin nhắn Zalo/SMS nhắc nhở khi gần đến các ngày tiêm dự kiến.
   • Tích hợp Bán hàng: Nếu bác sĩ có tick chọn áp dụng Gói Dịch vụ, chi phí của gói này sẽ được tự động gửi đến quầy Lễ tân để chờ thanh toán, giống hệt như chi phí của một dịch vụ cận lâm sàng.

---

II. AI Hỗ trợ Sau tiêm - "Trợ lý Dặn dò Thông minh"
Bối cảnh: Điều dưỡng vừa thực hiện xong mũi tiêm hiện tại cho bệnh nhân. Trước khi bệnh nhân ra khu vực theo dõi 30 phút, việc dặn dò là cực kỳ quan trọng.
Luồng hành động của Điều dưỡng / Bác sĩ:

1. Nhấn nút Hỗ trợ: Trong giao diện sàng lọc, sau khi đã ghi nhận mũi tiêm, sẽ có một nút mới: [🤖 Tạo Hướng dẫn Chăm sóc Sau tiêm].
2. "Suy nghĩ" của AI: Khi nhấn nút, hệ thống sẽ gửi cho Gemini một "bài toán" phức tạp:
   o Vắc-xin vừa tiêm: Vắc-xin 6 trong 1 (Mũi 2)
   o Bệnh nhân: Bé Nguyễn Hoàng An, 4 tháng tuổi.
   o Thông tin Y tế liên quan (lấy từ EMR): Không có tiền sử dị ứng nặng, không có bệnh nền.
   o "Mệnh lệnh": "Hãy tạo một bản hướng dẫn chăm sóc sau tiêm cho một bé 4 tháng tuổi vừa tiêm vắc-xin 6 trong 1. Sử dụng ngôn ngữ đơn giản, dễ hiểu cho phụ huynh. Nội dung cần bao gồm: các phản ứng thông thường có thể gặp, cách xử lý (chườm mát, thuốc hạ sốt nếu cần), các dấu hiệu nguy hiểm cần đưa đến cơ sở y tế ngay, và chế độ dinh dưỡng."
3. Kết quả trả về: Một bản hướng dẫn chi tiết, được cá nhân hóa sẽ hiện ra trên màn hình.
   HƯỚNG DẪN CHĂM SÓC BÉ AN SAU KHI TIÊM VẮC-XIN 6 TRONG 1
4. Các phản ứng thông thường:
   o Bé có thể bị sốt nhẹ (dưới 38.5°C), quấy khóc, bú kém hơn hoặc có vết sưng đỏ nhỏ tại chỗ tiêm. Đây là các phản ứng bình thường và sẽ tự hết sau 1-2 ngày.
5. Cách xử lý tại nhà:
   o Hạ sốt: Chỉ dùng thuốc hạ sốt (Paracetamol) theo đúng liều lượng bác sĩ chỉ định KHI bé sốt trên 38.5°C.
   o Tại chỗ tiêm: Chườm mát bằng khăn sạch để giảm sưng đau. KHÔNG bôi đắp bất cứ thứ gì lên vết tiêm.
   o Dinh dưỡng: Cho bé bú nhiều hơn và mặc quần áo thoáng mát.
6. ⚠️ CÁC DẤU HIỆU CẦN ĐƯA ĐẾN CƠ SỞ Y TẾ NGAY:
   o Sốt cao liên tục trên 39°C.
   o Co giật, li bì, bỏ bú.
   o Khóc thét dai dẳng.
   o Da tím tái, khó thở.
   [In Hướng dẫn] [Gửi vào Zalo của Mẹ]
   Giá trị mang lại:
   • Tăng cường An toàn: Đảm bảo phụ huynh nhận được thông tin dặn dò đầy đủ, chính xác và được cá nhân hóa.
   • Tiết kiệm Thời gian: Bác sĩ/Điều dưỡng không cần phải lặp lại các hướng dẫn giống nhau cho mọi bệnh nhân.
   • Tăng tính Chuyên nghiệp: Cung cấp cho phụ huynh một tài liệu rõ ràng, có thể lưu lại và tham khảo, tạo sự tin tưởng và an tâm tuyệt đối.

B. Giao Diện Thông Tin Bệnh Nhân (Khi bắt đầu sàng lọc)
Khi bác sĩ/điều dưỡng nhấp vào một bệnh nhân từ "Hàng Đợi Sàng Lọc", giao diện chi tiết sẽ hiện ra. Giao diện này được chia thành 3 khu vực thông tin cố định, luôn hiển thị ở phía trên màn hình để đảm bảo an toàn.
Khu vực 1: Thông tin Hành chính
• Mã Bệnh nhân/KH, Họ và Tên, Giới tính, Địa chỉ, Thông tin liên hệ người giám hộ.
• Tính năng thông minh quan trọng:
o Ngày sinh: dd/mm/yyyy -> Hệ thống sẽ tự động tính và hiển thị tuổi chính xác đến từng ngày. Ví dụ: (5 tuổi, 3 tháng, 12 ngày). Chức năng này cực kỳ quan trọng để áp dụng đúng phác đồ vắc-xin cho trẻ nhỏ.
Khu vực 2: Lịch Sử Tiêm Chủng (Sổ tiêm chủng điện tử)
• Đây là "cuốn sổ tiêm chủng điện tử", được trình bày dạng bảng trực quan và thông minh.
Tên Vắc-xin Số mũi Ngày Tiêm Phản ứng sau tiêm Ghi chú
Vắc-xin 6 trong 1 Mũi 1 05/06/2025 Sốt nhẹ 38°C Mẹ tự xử lý
Vắc-xin Rota Mũi 2 05/08/2025 Không sốt
Vắc-xin 6 trong 1 Mũi 2 (Trống)
• Các chức năng thông minh:
o Tô màu/In đậm: Hệ thống tự động dựa vào ngày sinh và các mũi đã tiêm để tô màu đỏ hoặc in đậm các mũi tiêm đã trễ lịch.
o Cảnh báo phản ứng: Nếu cột "Phản ứng sau tiêm" có ghi nhận phản ứng nặng từ lần trước, cả dòng đó sẽ được tô màu vàng cảnh báo.
Khu vực 3: Cảnh Báo Y Tế Nền Tảng (Phải có màu sắc nổi bật nhất)
• Đây là khu vực không bao giờ được bỏ qua, được đặt trong một khung màu đỏ hoặc vàng cực kỳ nổi bật.
• Bệnh Nền Mạn Tính Đã Biết: (Hiển thị dạng thẻ) Hen suyễn Bệnh tim bẩm sinh Chậm phát triển
• DỊ ỨNG ĐÃ BIẾT: (Khung màu đỏ, chữ to, rõ ràng)
Dị ứng nặng (sốc phản vệ) với Trứng Dị ứng Amoxicillin
• Nội dung này phải là trường nổi bật nhất trên toàn bộ giao diện, là lớp bảo vệ an toàn đầu tiên cho bệnh nhân.
Phần nền tảng này đảm bảo rằng, trước khi nhân viên y tế hỏi câu đầu tiên, họ đã có một cái nhìn 360 độ về bệnh nhân, nắm được các mũi tiêm đã trễ, các phản ứng trong quá khứ và quan trọng nhất là các cảnh báo an toàn không thể bỏ qua.
Phần 2: Giao diện Checklist Sàng lọc Tương tác
Bối cảnh: Bác sĩ/Điều dưỡng đã xem xong thông tin tổng quan của bệnh nhân và sẵn sàng bắt đầu quá trình khám sàng lọc. Giao diện này nằm ngay bên dưới khu vực thông tin cố định mà chúng ta đã thảo luận.
I. Checklist Sàng Lọc (Dạng câu hỏi Có/Không tương tác)
Đây là một danh sách các câu hỏi theo tiêu chuẩn của Bộ Y tế, nhưng được thiết kế để tương tác thông minh, giúp quy trình nhanh với người khỏe mạnh và chi tiết với người có nguy cơ.
• Nguyên tắc thiết kế:
o Tất cả các câu hỏi mặc định ở trạng thái "Không". Nhân viên y tế chỉ cần hành động khi câu trả lời là "Có" .
o Khi chọn "Có" vào bất kỳ câu hỏi nào, một ô "Ghi rõ chi tiết" sẽ tự động hiện ra ngay bên cạnh, yêu cầu bắt buộc phải nhập thông tin.
• Các câu hỏi sàng lọc quan trọng với Logic Thông minh:
o 2. Bệnh nhân có tiền sử phản ứng NẶNG (sốc phản vệ) với liều trước của vắc-xin này hoặc với bất kỳ thành phần nào trong vắc-xin không?
 ( ) Có (•) Không
 Hành động thông minh của hệ thống: Nếu người dùng chọn "Có", hệ thống sẽ ngay lập tức hiển thị một cảnh báo MÀU ĐỎ, CHỮ LỚN, không thể bỏ qua ngay trên màn hình:
"CHỐNG CHỈ ĐỊNH TUYỆT ĐỐI! NGUY CƠ SỐC PHẢN VỆ CAO. KHÔNG TIẾN HÀNH TIÊM."
 Đồng thời, nút chỉ định tiêm ở cuối trang sẽ bị vô hiệu hóa.
o 3. Bệnh nhân có bị suy giảm miễn dịch... hoặc đang dùng thuốc ức chế miễn dịch... không?
 ( ) Có (•) Không
 Hành động thông minh của hệ thống: Nếu chọn "Có", hệ thống hiển thị cảnh báo màu vàng: "LƯU Ý CAO ĐỘ! Chống chỉ định với các vắc-xin sống giảm độc lực. Cần có chỉ định chuyên khoa.".
o 6. (Câu hỏi dành cho nữ) Bệnh nhân có đang mang thai hoặc nghi ngờ có thai không?
 ( ) Có (•) Không ( ) Không áp dụng
 Hành động thông minh của hệ thống: Tương tự câu 3, cảnh báo vàng sẽ hiện lên, đặc biệt nhấn mạnh nguy cơ của vắc-xin sống.
II. Ghi Nhận Thăm Khám & Dấu Hiệu Sinh Tồn
Khu vực này để nhập các dữ liệu khách quan đo được.
• Thân nhiệt: [ 38.5 ] °C
o Hành động thông minh của hệ thống: Nếu nhập số ≥ 38.0, ô này tự động chuyển sang màu đỏ và hiển thị cảnh báo nhỏ: "Sốt! Cân nhắc tạm hoãn." .
• Nhịp thở: [ 28 ] lần/phút
o Hành động thông minh của hệ thống: Bên cạnh ô nhập liệu, hệ thống hiển thị một chỉ số tham chiếu: "Bình thường cho tuổi này: 24-40 lần/phút." .
III. Khu Vực Ra Quyết Định Của Bác Sĩ (Chỉ tài khoản Bác sĩ mới có quyền)
Đây là phần cuối cùng, nơi bác sĩ đưa ra kết luận cuối cùng sau khi đã có đầy đủ thông tin.

1. Tóm Tắt Cảnh Báo Tự Động:
   • Một hộp thông tin không thể chỉnh sửa, tự động tổng hợp tất cả các cảnh báo đã được kích hoạt ở trên, ví dụ:

- Cảnh báo Vàng: Bệnh nhân có tiền sử hen suyễn. - Cảnh báo Đỏ: Thân nhiệt 38.5°C (Sốt).

2. KẾT LUẬN SÀNG LỌC:
   (Dạng nút chọn lớn, rõ ràng)
   • ( 🟢 ) ĐỦ ĐIỀU KIỆN TIÊM CHỦNG
   o Vắc-xin chỉ định: [Dropdown list các vắc-xin phù hợp với độ tuổi]
   o Ghi chú/Dặn dò thêm: (Ô văn bản tùy chọn)
   • ( 🟡 ) TẠM HOÃN TIÊM CHỦNG
   o Nếu chọn mục này, các ô sau sẽ trở thành bắt buộc:
    Lý do tạm hoãn: (Ô văn bản bắt buộc)
    Lịch hẹn tái khám: (Lịch để chọn ngày)
   • ( 🔴 ) CHỐNG CHỈ ĐỊNH
   o Nếu chọn mục này, ô sau sẽ trở thành bắt buộc:
    Lý do chống chỉ định: (Ô văn bản bắt buộc, giải thích rõ)
3. Xác nhận và Hoàn tất:
   • Một checkbox xác nhận bắt buộc:
   [ ✓ ] Tôi đã trực tiếp khám, tư vấn và chịu trách nhiệm với kết luận trên.
   • Nút cuối cùng:
   [LƯU & CHUYỂN TIÊM] (Nếu đủ điều kiện) hoặc [LƯU & KẾT THÚC SÀNG LỌC] (Nếu tạm hoãn/chống chỉ định).
   Hành động cuối cùng này sẽ cập nhật trạng thái của bệnh nhân trên Bảng điều khiển chính, chuyển họ sang "Hàng Đợi Tiêm" hoặc xóa khỏi hàng đợi trong ngày, đồng thời lưu lại vĩnh viễn toàn bộ quá trình sàng lọc này trong hồ sơ bệnh nhân.

VAI TRÒ CỦA AI TRONG LUỒNG NÀY:
Phần 1: AI Hỗ trợ Kinh doanh và Chăm sóc Khách hàng

1. Tích hợp AI cho Lễ tân: "Trợ lý Tư vấn Gói Vắc-xin Thông minh"
   • Mục tiêu: Giúp nhân viên Lễ tân (những người không phải là chuyên gia y tế sâu) có thể tư vấn các gói vắc-xin một cách chính xác, tự tin và tăng cơ hội bán hàng.
   • Giao diện & Luồng hoạt động:
   o Chúng ta sẽ tạo ra một công cụ mới trong module Đặt Lịch Hẹn hoặc Tiêm Chủng có tên là "Tư vấn Nhanh Lịch tiêm chủng".
   o Bối cảnh: Một phụ huynh gọi đến và hỏi: "Con tôi vừa tròn 12 tháng tuổi, cháu cần tiêm những mũi gì tiếp theo?"
   o Hành động của Lễ tân:
1. Mở công cụ "Tư vấn Nhanh".
1. Tìm kiếm bệnh nhân (nếu là khách cũ) hoặc chỉ cần nhập ngày sinh của bé vào.
1. Nhấn nút [🤖 AI Phân tích & Gợi ý].
   o "Suy nghĩ" của AI:
1. Hệ thống sẽ gửi cho Gemini các thông tin: tuổi chính xác của bé, lịch sử các mũi đã tiêm (nếu có), và toàn bộ "kiến thức" về phác đồ tiêm chủng chuẩn của Việt Nam.
   o Kết quả hiển thị cho Lễ tân: Một bản tóm tắt cực kỳ rõ ràng và dễ hiểu.
   Kết quả Phân tích cho Bé (12 tháng tuổi):
   Các mũi tiêm được khuyến nghị theo độ tuổi:
1. Sởi - Quai bị - Rubella (Mũi 1)
1. Viêm não Nhật Bản (Mũi 1)
1. Thủy đậu (Mũi 1)
1. Phế cầu (Mũi nhắc lại)
   Gợi ý Bán hàng:
1. Nam Việt hiện có "Gói Tiêm chủng Vàng cho trẻ 12-18 tháng" bao gồm tất cả các mũi tiêm trên với ưu đãi giảm 10% so với tiêm lẻ. Người dùng có muốn tư vấn gói này cho khách hàng không?
   • Giá trị mang lại:
   o Tăng sự tự tin cho Lễ tân: Họ có một công cụ mạnh mẽ để đưa ra thông tin chính xác.
   o Tăng cơ hội bán gói: Hệ thống chủ động gợi ý các gói sản phẩm phù hợp, thúc đẩy doanh thu.
   o Tăng trải nghiệm khách hàng: Khách hàng nhận được sự tư vấn nhanh chóng và chuyên nghiệp.
1. Tích hợp AI vào Chăm sóc Khách hàng: "Hệ thống Nhắc lịch & Trả lời Tự động Cá nhân hóa"
   • Mục tiêu: Tự động hóa việc nhắc lịch một cách thông minh và trả lời các câu hỏi thường gặp của phụ huynh 24/7, giảm tải cho nhân viên.
   • Luồng hoạt động:
   o AI soạn tin nhắn nhắc lịch: Thay vì một tin nhắn mẫu khô khan, AI có thể tạo ra các tin nhắn tự nhiên và cá nhân hóa hơn, dựa trên "Lịch trình Chăm sóc" mà chúng ta đã thiết kế.
   o AI Chatbot trả lời tự động:
    Bối cảnh: Phụ huynh nhận được tin nhắn Zalo nhắc lịch tiêm mũi Sởi-Quai bị-Rubella và họ trả lời lại: "Bé nhà mình tiêm mũi này về có bị sốt không người dùng?"
    Hành động của hệ thống: Thay vì phải chờ nhân viên trả lời, AI Chatbot được tích hợp vào Zalo sẽ ngay lập tức phân tích câu hỏi và đưa ra một câu trả lời đã được chuẩn hóa và phê duyệt từ trước.
   "Chào chị, vắc-xin Sởi-Quai bị-Rubella nói chung là an toàn. Một số bé có thể có phản ứng sốt nhẹ trong 1-2 ngày sau tiêm. Đây là phản ứng thông thường cho thấy hệ miễn dịch của bé đang đáp ứng tốt với vắc-xin. Chị có thể cho bé uống nhiều nước và chườm mát. Nếu bé sốt cao trên 38.5 độ hoặc có dấu hiệu bất thường khác, chị nên liên hệ ngay với trung tâm nhé."
    Nếu câu hỏi quá phức tạp, AI sẽ tự động chuyển cho nhân viên xử lý.
   • Giá trị mang lại:
   o Phục vụ 24/7: Khách hàng được giải đáp thắc mắc ngay lập tức, kể cả ngoài giờ hành chính.
   o Giảm tải Công việc: Giảm đáng kể số lượng cuộc gọi và tin nhắn mà nhân viên phải xử lý hàng ngày.
   o Chuyên nghiệp & Đồng nhất: Đảm bảo mọi câu trả lời cho các câu hỏi phổ biến đều nhất quán và đúng theo tiêu chuẩn chuyên môn của công ty.

c. Menu “Bán Buôn B2B”
Mọi thông tin như table dưới đây:
Bán Buôn (Menu cha)
• B2B Sales Dashboard: Trung tâm dashboard hiển thị các thông tin nhanh, Nhân viên sẽ nhìn vào giao diện này để bắt đầu ngày làm việc.
• Tạo Báo Giá / Đơn Hàng: Nhấn vào đây sẽ đưa NVKD đi thẳng đến giao diện tạo mới (nhảy sang 1 tab khác – loại bỏ menubar để tập trung vào công việc), bỏ qua mọi bước trung gian.
• Danh sách Đơn hàng: Trung tâm quản lý, theo dõi và xử lý tất cả các đơn hàng B2B.
• Xem Nhanh Báo Giá: Công cụ tương tác hàng ngày mà người dùng đã đề xuất.
Nút 1: Giao diện "2B Sales Dashboard "
Giao diện "B2B Dashboard" - Trung Tâm Chỉ Huy Đa Vai Trò
A. Phần Chung: "Nhịp đập Chiến trường" (Hiển thị cho mọi vai trò)
Bất kể ai đăng nhập, họ đều sẽ thấy khu vực này. Nó tạo ra sự kết nối và nhận thức chung về các hoạt động đang diễn ra.
Widget: Dòng hoạt động gần đây
• Một danh sách cập nhật "sống" các sự kiện quan trọng, giúp các bộ phận thấy được công việc của nhau:
o [14:30] 📈 NV Kinh doanh A vừa tạo báo giá #BG00123 cho Bệnh viện X.
o [14:35] payment Kế toán đã xác nhận thanh toán cho đơn hàng #DH00124.
o [14:40] 📦 Kho đã hoàn tất đóng gói đơn hàng #DH00125.
o [14:45] 🚚 Đơn hàng #DH00125 đã được giao cho bộ phận vận chuyển.

B. Giao diện dành riêng cho Nhân viên Kinh doanh (NVKD)
Khi một NVKD đăng nhập, "buồng lái" của họ sẽ tập trung vào các mục tiêu kinh doanh và chăm sóc khách hàng.
Widget 1: "Việc Cần Làm Hôm Nay" (Actionable To-do List) Đây là widget quan trọng nhất, trả lời câu hỏi "tôi cần làm gì ngay bây giờ?". Nó không phải là một danh sách công việc thủ công, mà là một danh sách được hệ thống tự động gợi ý:
• Báo giá sắp hết hạn cần theo dõi:
o BG-00120 - BV Y Dược - Hết hạn trong 2 ngày - Xem chi tiết
• Khách hàng đến hạn công nợ cần nhắc:
o Nhà thuốc An Khang - 15.500.000đ - Quá hạn 3 ngày - Xem chi tiết
• Gợi ý Chăm sóc Khách hàng:
o Nhà thuốc Minh Tâm - Đã 30 ngày chưa phát sinh đơn hàng mới - Xem chi tiết
Widget 2: "KPIs & Phễu Bán hàng" Đây là nơi họ theo dõi hiệu suất cá nhân và bức tranh toàn cảnh về các cơ hội của mình.
• Biểu đồ Doanh số Tháng: So sánh doanh số thực tế của cá nhân NVKD đó với chỉ tiêu được giao.
• Phễu Bán hàng Cá nhân: Biểu đồ phễu chỉ hiển thị các báo giá/đơn hàng do chính NVKD đó phụ trách, giúp họ biết cần tập trung vào giai đoạn nào để thúc đẩy doanh số.

C. Giao diện dành riêng cho Nhân viên Kho
Khi một Nhân viên Kho đăng nhập, Dashboard sẽ "biến hình" thành một trung tâm điều phối vận hành.
Widget 1: "Nhiệm vụ Kho Vận Hôm Nay" Đây là bảng công việc ưu tiên hàng ngày của bộ phận kho.
• Đơn hàng cần đóng gói GẤP:
o DH00126 - Giao hàng nhanh - Hẹn giao trước 16:00
• Danh sách Đơn hàng chờ đóng gói:
o Tổng số: 15 đơn hàng
o DH00127 - Nhà thuốc An Tâm - 5 sản phẩm
o DH00128 - Bệnh viện XYZ - 22 sản phẩm
• Đơn hàng đã đóng gói, chờ giao vận:
o Tổng số: 8 đơn hàng
o DH00125 - Chờ Giao vận...
Widget 2: "Tình hình Kho Vận Nhanh" Cung cấp các chỉ số quan trọng cho việc vận hành kho.
• Số đơn hàng đã đóng gói hôm nay: [ 22 ]
• Số đơn hàng đã xuất kho hôm nay: [ 18 ]
• Cảnh báo Tồn kho Sắp hết:
o SP A - Tồn kho khả dụng chỉ còn 5 Hộp
Với thiết kế cá nhân hóa này, Dashboard không còn là một màn hình báo cáo tĩnh. Nó đã trở thành một trợ lý ảo chủ động, chỉ cho từng nhân viên thấy chính xác họ cần tập trung vào đâu để hoàn thành tốt nhất nhiệm vụ của mình, đồng thời vẫn giữ cho mọi người một cái nhìn chung về "nhịp đập" của toàn bộ "chiến trường" kinh doanh.

Nút 2: Giao diện " Tạo Báo Giá / Đơn Hàng "
Giao diện "Tạo Báo Giá / Đơn Hàng" - Không gian làm việc Tập trung
Bối cảnh: Khi NVKD nhấn nút [Tạo Báo Giá / Đơn Hàng] trên menu, hệ thống sẽ mở ra một tab trình duyệt mới. Giao diện này sẽ là một không gian làm việc toàn màn hình, không có thanh menu chung hay các yếu tố gây xao lãng, giúp NVKD tập trung 100% vào việc tạo một đơn hàng hoàn hảo cho khách.
Bố cục sẽ được chia thành 4 khu vực chính, sắp xếp theo một dòng chảy công việc tự nhiên từ trên xuống dưới.
Khu vực 1: Thanh Công cụ & Nút bấm Hành động (Phía trên, cố định)
Đây là thanh công cụ quyền lực, luôn cố định ở trên cùng để NVKD có thể thực hiện các hành động quan trọng bất cứ lúc nào.
• [Tạo đơn từ Excel]: Cho phép NVKD tải lên một file Excel chứa danh sách mã sản phẩm và số lượng để tạo nhanh một đơn hàng lớn.
• [Lưu nháp]: Lưu lại toàn bộ thông tin đang làm dở để quay lại sau.
• [Xem trước PDF]: Mở một bản xem trước của file báo giá PDF chuyên nghiệp sẽ được gửi cho khách hàng.
• [Lưu & Gửi Email Báo Giá]: Lưu báo giá vào hệ thống và tự động mở gửi email với file PDF đã được đính kèm cho khách hàng.
• [TẠO ĐƠN HÀNG]: Nút hành động quan trọng nhất. Khi khách hàng đã đồng ý với báo giá, NVKD sẽ nhấn nút này. Hệ thống sẽ chính thức chuyển báo giá thành một đơn hàng, thay đổi trạng thái thành "🔵 Chờ đóng gói" và gửi thông báo tự động đến bộ phận Kho.

Khu vực 2: Thông tin Khách hàng & Vận chuyển
Đây là nơi xác định "ai là người mua" và "hàng sẽ đi về đâu".
• Khách hàng: Một ô tìm kiếm thông minh. NVKD chỉ cần gõ tên, SĐT hoặc MST, hệ thống sẽ gợi ý khách hàng tương ứng từ module CRM.
• Hành động thông minh: Ngay khi một khách hàng được chọn, các trường sau sẽ được tự động điền:
o Tên Người nhận, MST, Địa chỉ, Số điện thoại, Xếp Hạng khách hàng (ví dụ: VIP, Kim Cương).
• Thông tin Đơn hàng:
o Ngày tạo: (Tự động)
o Nhân viên tạo: (Tự động)
• Thông tin Vận chuyển:
o Hình thức Vận Chuyển: [Dropdown: Giao hàng nhanh, Giao hàng tiêu chuẩn, Khách tự đến lấy...]
o Thời gian nhận hàng dự kiến: (Hệ thống có thể tự động gợi ý dựa trên hình thức vận chuyển và địa chỉ)

Khu vực 3: Chi tiết Đơn hàng
Đây là nơi NVKD xây dựng giỏ hàng cho khách.
• Ô tìm kiếm sản phẩm: Một ô tìm kiếm mạnh mẽ. Khi NVKD gõ Tên, Mã SKU hoặc dùng máy quét mã vạch, một danh sách sản phẩm sẽ hiện ra ngay lập tức, kèm theo thông tin quan trọng: Tên SP; SKU; Số lượng tồn/Đơn vị.
• Bảng Chi tiết Đơn hàng (Giỏ hàng):
STT Tên SP Số lô – Hạn SD Đơn vị tính Số lượng Đơn giá Thành tiền
1 Amoxicillin 250mg P123 - 12/2026 Hộp [ 100 ] 100.000đ 10.000.000đ
2 Paracetamol Extra X456 - 08/2027 Hộp [ 200 ] 50.000đ 10.000.000đ

• Quy tắc nghiệp vụ:
o Đơn giá: Sẽ được tự động lấy từ bảng giá Bán Buôn duy nhất mà chúng ta đã thống nhất.
o Số lô – Hạn SD: Hệ thống sẽ tự động gợi ý lô hàng có hạn sử dụng gần nhất để xuất đi trước (Nguyên tắc FEFO), nhưng NVKD vẫn có thể chọn lô khác nếu cần.

Khu vực 4: Thanh toán & "Bộ Não" Khuyến mại
Đây là khu vực tổng kết và áp dụng các chính sách tài chính.
• Tổng kết nhanh:
o Tổng số lượng sản phẩm: 300
o Tổng số tiền hàng: 20.000.000đ
• Khu vực "Thông minh" - Voucher & Giảm giá:
o Áp dụng Mã giảm giá / Voucher: Một ô để NVKD nhập mã voucher.
o Hệ thống tự động gợi ý: Ngay bên dưới ô này, hệ thống sẽ tự động hiển thị các voucher hợp lệ có thể áp dụng cho khách hàng này hoặc cho đơn hàng này, NVKD chỉ cần click để áp dụng.
o Thông tin các mã giảm giá được sử dụng: Một danh sách sẽ hiện ra, cho thấy các voucher đã được áp dụng thành công. Hệ thống sẽ cho phép áp dụng nhiều mã nếu các điều kiện của voucher đó cho phép.
• Tổng kết cuối cùng:
o Chi phí khác (nếu có): (Ví dụ: phí vận chuyển)
o TỔNG TIỀN KHÁCH HÀNG THANH TOÁN: (Con số cuối cùng sau khi đã trừ hết các giảm giá và cộng các chi phí khác).
• Ghi chú:
o Ghi chú khác (thông báo tới khách hàng): (Ví dụ: "Hàng sẽ được giao trong 2 ngày làm việc.")
Nút 3: Giao diện "Danh sách Đơn hàng" - Trung tâm Theo dõi & Xử lý Vận hành
Phần 1: Giao diện Tổng quan và Trạng thái "Nháp"
A. Giao diện "Quản lý Đơn hàng B2B" - Trung tâm Điều phối
Đây là giao diện chính, truy cập từ menu Bán Buôn -> Danh sách Đơn hàng.
• Các công cụ quản lý mạnh mẽ:
o Bộ lọc & Tìm kiếm: Cho phép lọc theo Ngày tạo, Trạng thái Vận hành, Trạng thái Thanh toán, Khách hàng, Người tạo... Bộ lọc này có thể ẩn/hiện
o Nút [Nhập/Xuất Excel] và Checkbox để thực hiện các hành động hàng loạt như
• Bảng Danh sách Đơn hàng:
[Checkbox] Mã ĐH / BG Tên Khách hàng Ngày tạo Tổng Giá trị Trạng thái Vận hành Trạng thái Thanh toán Hành động
[ ] BG-00123 Bệnh viện Y Dược 29/08/2025 20.900.000đ ⚫ Nháp (Hết hạn sau 2 ngày) - [Xem] [Sửa] [In] [TẠO ĐƠN HÀNG]
[ ] DH-00125 Bệnh viện XYZ 28/08/2025 52.000.000đ 🔵 Chờ đóng gói 🔴 Chưa thanh toán [Xem] [In] [Hủy]

B. Vòng Đời Đơn Hàng - Giai đoạn 1: Trạng thái "Nháp" (Báo giá chờ quyết định)
Đây là giai đoạn đầu tiên và mang tính chất "chăm sóc" của quy trình.
• Định nghĩa: một bản ghi ở trạng thái "Nháp" thực chất là một Báo giá (BG) đã được gửi cho khách hàng và đang trong thời gian chờ họ ra quyết định. Nó chưa phải là một đơn hàng chính thức cam kết giao hàng.
• Làm thế nào nó được tạo ra?
o Nó được tạo ra từ giao diện "Tạo Báo Giá / Đơn Hàng" khi NVKD nhấn nút [Lưu & Gửi Báo Giá].
• Hệ thống hoạt động thông minh:
o Tự động theo dõi hiệu lực: Hệ thống sẽ ghi nhận ngày hết hạn của báo giá. Thông tin này sẽ được hiển thị rõ ràng trên danh sách (ví dụ: "Hết hạn sau 2 ngày"). Nếu quá ngày hiệu lực mà không có hành động gì, hệ thống có thể tự động chuyển trạng thái thành "Đã Hủy (Hết hạn)".
o Tích hợp với Dashboard: Những báo giá sắp hết hạn sẽ tự động xuất hiện trong widget "Việc Cần Làm Hôm Nay" trên Dashboard của NVKD, nhắc nhở họ chủ động gọi điện chăm sóc, thúc đẩy khách hàng ra quyết định.
• Các "Hành động" có thể thực hiện ở trạng thái này:
o [Xem]: Xem lại chi tiết báo giá đã gửi.
o [Sửa & Gửi lại]: Nếu khách hàng yêu cầu thay đổi (thêm/bớt sản phẩm, điều chỉnh số lượng), NVKD có thể sửa và gửi lại một phiên bản mới của báo giá.
o [Hủy Báo giá]: Hủy báo giá nếu khách hàng từ chối.
o [TẠO ĐƠN HÀNG]: Đây là nút bấm chuyển giao quyền lực. Khi khách hàng đồng ý mua, NVKD sẽ nhấn vào nút này. Đây là hành động xác nhận một giao dịch thành công.
Khi nút [TẠO ĐƠN HÀNG] được nhấn, "quả bóng" sẽ được chuyền từ đội Kinh doanh sang cho đội Kho vận. Mã báo giá BG-00123 sẽ được chuyển đổi thành một mã đơn hàng chính thức DH-00126, và trạng thái của nó sẽ ngay lập tức được cập nhật thành "🔵 Chờ đóng gói".
Vòng Đời Đơn Hàng - Giai đoạn 2: Trạng thái "🔵 Chờ đóng gói"
Đây là giai đoạn mà "quả bóng" đã được chuyền hoàn toàn sang cho đội Kho Vận.
• Định nghĩa: Một đơn hàng ở trạng thái "Chờ đóng gói" là một yêu cầu chính thức, đã được khách hàng xác nhận. Nó xuất hiện như một nhiệm vụ mới, cấp bách trong danh sách việc cần làm của bộ phận kho.
• Nó xuất hiện ở đâu?
o Trên Dashboard của Nhân viên Kho, trong widget "Nhiệm vụ Kho Vận Hôm Nay".
o Trong giao diện "Quản lý Đơn hàng B2B", nhân viên kho có thể lọc theo trạng thái này để xem tất cả các đơn hàng đang chờ họ xử lý.
• Luồng công việc của Nhân viên Kho:

1. Hành động 1: In Phiếu Lấy Hàng (Picklist) Thông minh
    Nhân viên kho chọn một hoặc nhiều đơn hàng cần xử lý và nhấn nút [In Phiếu Lấy Hàng].
    Sự thông minh của hệ thống: Hệ thống sẽ không in ra một danh sách sản phẩm lộn xộn. Thay vào đó, nó sẽ tự động tạo ra một danh sách đã được
   sắp xếp theo đúng thứ tự vị trí kệ hàng trong kho (A-01 -> A-02 -> B-01...). Điều này cho phép nhân viên chỉ cần đẩy xe đi một vòng duy nhất trong kho để lấy đủ hàng, tối ưu hóa tối đa thời gian và công sức di chuyển.
2. Hành động 2: Bắt đầu Đóng gói và Xác thực
    Sau khi lấy hàng về khu vực đóng gói, nhân viên mở đơn hàng trên hệ thống (bằng máy tính bảng hoặc máy tính có gắn máy quét) và nhấn [Bắt đầu Đóng gói].
    Hành động này mở ra một giao diện chuyên biệt.
   • Giao diện "Đóng Gói & Xác thực Đơn hàng DH-00125":
   o Giao diện này cực kỳ đơn giản, chỉ hiển thị những thông tin cần thiết nhất cho việc xác thực.
   o Bảng Xác thực Sản phẩm:
   Sản phẩm Vị trí Kệ SL Cần Lấy Trạng thái Xác thực
   Amoxicillin 250mg A-01-03 100 Hộp ⚪ Chưa quét
   Paracetamol Extra B-05-02 200 Hộp ⚪ Chưa quét
   _ **Quy trình quét mã vạch để xác nhận (check lại lần 2):**
   _ Nhân viên cầm sản phẩm Amoxicillin (đã lấy từ kệ) và **quét mã vạch** trên hộp sản phẩm.
   _ **Hệ thống phản hồi tức thì:** Trên màn hình, dòng "Amoxicillin 250mg" sẽ được tô sáng và cột "Trạng thái Xác thực" ngay lập tức chuyển thành **"✅ Đã xác nhận"** (kèm theo một tích xanh "tích xanh").
   _ Nhân viên tiếp tục quét sản phẩm Paracetamol, và dòng tương ứng cũng chuyển sang "✅ Đã xác nhận".

- **Lợi ích:** Quy trình "quét để xác nhận" này là một lớp bảo vệ cực kỳ quan trọng. Nó đảm bảo 100% rằng sản phẩm vật lý được bỏ vào thùng hàng khớp chính xác với những gì khách hàng đã yêu cầu trên đơn hàng, loại bỏ hoàn toàn các sai sót do "nhìn nhầm" hoặc "bỏ sót".

3.  **Hành động 3: Hoàn tất Đóng gói**
    - Sau khi tất cả các sản phẩm trong đơn hàng đều đã có "tích xanh", nút **`[Hoàn tất Đóng gói]`** sẽ sáng lên.
    - Nhân viên nhấn nút này sau khi đã niêm phong thùng hàng.

Vòng Đời Đơn Hàng - Giai đoạn 3: Trạng thái "🟡 Đã đóng gói & Chờ giao vận"
• Định nghĩa: Trạng thái này cho biết một thùng hàng hoàn chỉnh, đã được xác thực, đang nằm ở khu vực chờ xuất kho và sẵn sàng để được bàn giao.
• Hành động của Nhân viên Kho:
o Khi nhân viên của bộ phận giao vận đến kho để nhận hàng, nhân viên kho sẽ tìm đến đơn hàng này trên hệ thống.
o Họ nhấn vào nút hành động quan trọng tiếp theo: [Giao vận Đã Lấy Hàng].
o Đồng thời, họ có thể nhấn nút [In Phiếu Giao Hàng] để in ra một bản cứng, có chữ ký của cả hai bên để làm bằng chứng bàn giao.
Khi nút [Giao vận Đã Lấy Hàng] được nhấn, đơn hàng sẽ chính thức rời khỏi kho và bắt đầu hành trình cuối cùng của mình.
Vòng Đời Đơn Hàng - Giai đoạn 4: Trạng thái "🚚 Chờ giao tới khách hàng"
• Định nghĩa: Đây là trạng thái khi thùng hàng đã được đóng gói, xác thực, niêm phong và đã được bàn giao cho nhân viên giao vận. Về mặt vật lý, nó không còn nằm trong kho của Nam Việt nữa. Hệ thống bây giờ chuyển sang vai trò "theo dõi hành trình".
• Ai tương tác? Chủ yếu là Nhân viên Giao vận. Để quy trình được liền mạch, nhân viên giao vận sẽ được cấp một tài khoản với quyền hạn rất giới hạn, có thể truy cập vào một giao diện di động đơn giản của hệ thống Nam Việt ERP.
• Giao diện "Giao Vận" trên Di động:
o Khi đăng nhập, nhân viên giao vận sẽ thấy một danh sách các đơn hàng được giao cho họ trong ngày.
o Mỗi đơn hàng sẽ hiển thị các thông tin cốt lõi: Mã ĐH, Tên Khách hàng, Địa chỉ, Số điện thoại, và quan trọng nhất là Số tiền cần thu (COD).
o Với mỗi đơn hàng, sẽ có 2 nút bấm rất lớn và rõ ràng: [✅ Giao Thành Công] và [❌ Giao Thất Bại].
• Các kịch bản có thể xảy ra:
o Kịch bản A: Giao hàng Thành công

1. Nhân viên giao vận giao hàng và thu tiền (nếu có) từ khách.
2. Ngay tại chỗ, họ mở giao diện di động và nhấn nút [✅ Giao Thành Công].
3. Hệ thống có thể yêu cầu một xác nhận đơn giản (ví dụ: chụp ảnh biên nhận hoặc chữ ký điện tử của khách hàng).
4. Hành động của hệ thống:
    Trạng thái Vận hành của đơn hàng ngay lập tức được cập nhật thành "✅ Hoàn tất".
    Trạng thái Thanh toán được cập nhật tương ứng (ví dụ: chuyển thành "🟡 Chờ nộp tiền" nếu là đơn COD).
   o Kịch bản B: Giao hàng Thất bại
5. Vì một lý do nào đó (khách hẹn lại, từ chối nhận hàng...), nhân viên giao vận không thể giao hàng.
6. Họ nhấn nút [❌ Giao Thất Bại].
7. Hệ thống sẽ yêu cầu họ chọn một lý do từ danh sách có sẵn: Khách hẹn lại ngày giao, Khách từ chối nhận hàng, Sai địa chỉ/Không liên lạc được...
8. Hành động của hệ thống: Trạng thái Vận hành của đơn hàng được cập nhật thành "⚠️ Chờ xử lý hàng trả về". Đơn hàng này sẽ ngay lập tức xuất hiện dưới dạng một cảnh báo trên Dashboard của Nhân viên Kho.

Vòng Đời Đơn Hàng - Giai đoạn 5: Hoàn tất & Xử lý Sau cùng
• Xử lý Hàng trả về (Nếu giao thất bại):
o Khi nhân viên giao vận mang thùng hàng bị trả về kho, nhân viên kho sẽ tìm đến đơn hàng đang có cảnh báo "⚠️ Chờ xử lý hàng trả về".
o Họ sẽ mở ra, xem lý do giao thất bại, kiểm tra lại tình trạng hàng hóa trong thùng.
o Sau khi xác nhận, họ nhấn nút [Nhập lại Kho hàng trả về].
o Hành động của hệ thống: Tự động tạo một phiếu nhập kho trả hàng, cộng lại chính xác số lượng hàng hóa vào tồn kho. Trạng thái Vận hành của đơn hàng được cập nhật thành "❌ Đã Hủy (Giao thất bại)".
• Trạng thái "✅ Hoàn tất" - Điểm kết thúc của Vòng đời Vận hành:
o Định nghĩa: Một đơn hàng được xem là Hoàn tất về mặt vận hành khi khách hàng đã nhận được hàng thành công.
o Nhưng chưa phải là kết thúc hoàn toàn!
 Tại thời điểm này, quy trình của kho và giao vận đã xong. Nhưng Trạng thái Thanh toán có thể vẫn là "🔴 Chưa thanh toán" (với các đơn hàng công nợ).
 Đơn hàng chỉ thực sự được "đóng" và hệ thống tính toán lợi nhuận cuối cùng khi cả hai điều kiện được thỏa mãn: Trạng thái Vận hành = "✅ Hoàn tất" VÀ Trạng thái Thanh toán = "🟢 Đã thanh toán".

Nút 4: Giao diện "Xem Nhanh Báo Giá" - Công cụ Tương tác Tức thì
• Mục đích: Cung cấp một giao diện báo giá trực quan, đẹp mắt, được tối ưu hóa cho việc chụp ảnh màn hình (screenshot) và gửi nhanh cho khách hàng qua Zalo, Messenger.
• Giao diện sẽ gồm 2 phần chính:

1. Khu vực 1: Bộ lọc & Tìm kiếm Nhanh
    Một ô tìm kiếm toàn năng để tìm theo tên, hoạt chất...
    Các bộ lọc nhanh theo Nhóm sản phẩm; Nhóm bệnh; khuyến mại; hãng sản xuất; Đường dùng; etc... (Ví dụ: CTV1, G10, hoặc các nhóm khuyến mại tháng như Nhóm 1 - Tháng 8...).
2. Khu vực 2: Bảng Báo giá Trực quan (Dạng Lưới Card Sản phẩm)
    Đây không phải là một bảng dữ liệu khô khan, mà là một lưới các "thẻ" (card) sản phẩm được thiết kế to, rõ ràng và bắt mắt. Mỗi thẻ sản phẩm sẽ hiển thị:
    Ảnh sản phẩm: Lớn, chất lượng cao.
    Tên Sản Phẩm và Đơn vị bán (Hộp, Thùng...).
    Tính năng / Bệnh áp dụng: Một dòng mô tả ngắn gọn, thu hút.
    Giá Ưu đãi Tốt nhất: Đây là điểm "thông minh". Hệ thống sẽ tự động tra cứu trong "Bộ Máy Chiết Khấu" và áp dụng thử các voucher tốt nhất, phổ biến nhất để hiển thị một mức giá hấp dẫn, kích thích khách hàng hỏi thêm. Ngay bên dưới giá sẽ có một dòng ghi chú nhỏ: "Giá tham khảo, áp dụng theo chính sách cho từng khách hàng. Để biết thêm chi tiết hãy liên hệ NV KD"
   • Luồng công việc của NVKD:
3. Mở công cụ "Xem Nhanh Báo Giá".
4. Lọc nhanh nhóm sản phẩm đang muốn quảng bá hôm nay.
5. Chụp ảnh màn hình khu vực danh sách sản phẩm.
6. Gửi ngay cho các khách hàng trong danh sách Zalo của mình với một lời chào.
   Công cụ này biến việc "chăm sóc khách hàng" hàng ngày từ một gánh nặng thành một thao tác đơn giản, nhanh chóng và hiệu quả, giúp NVKD luôn giữ được kết nối và nhắc nhở khách hàng về sự hiện diện của Nam Việt.

d. Sàn Thương Mại Điện Tử
5.3 Quản lý Kho và Sản Phẩm
a. Danh sách Sản Phẩm:
 Là giao diện Thêm/Sửa/Xóa sản phẩm.
 Trang danh sách sản phẩm gồm 3 phần:
• Phần 1: Tên trang + Các nút bấm
• Phần 2: Tìm sản phẩm và các bộ lọc
• Phần 3: Thông tin hiển thị, gồm các cột: Checkbox; Ảnh SP; Tên Sản Phẩm; Tồn kho B2B/Đơn Vị; Tồn kho tại Nhà thuốc 1; Tồn tại kho (khi thêm kho mới tự động hiển thị ra đây) …; Hành động (Sửa, xóa)

Ảnh minh họa Danh sách SP

Khi tích Checkbox có thêm 1 vài nút thao tác nhanh với các sản phẩm đã chọn.
 Giao diện ”Thêm Sản Phẩm/Sửa SP”: Có nút ”Làm giàu cơ sở dữ liệu” (Hoặc cào dữ liệu để đưa thông tin vào). Trong giao diện này gồm có các thông tin:
• Thông tin chung: Loại hàng; Là sản phẩm cố định (luôn cần tồn kho); Ảnh; Tên SP; Mã SKU; Barcode; Phân loại SP; Tags; Cty SX; Cty Phân Phối; Số Đăng ký; Quy Cách đóng gói; Mô tả và HDSD chung; HD sử dụng từ 0-2 tuổi; HD sử dụng từ 2-6 tuổi; HD sử dụng từ 6-18 tuổi; HD sử dụng từ 18 tuổi trở lên; Bệnh Áp dụng (Có phải Bệnh mãn tính hay không?)

• Giá & Kinh Doanh: Đơn vị Bán Buôn; Đơn vị Bán lẻ; Số lượng Quy đổi từ đơn vị bán buôn sang bán lẻ; Giá nhập trên Hóa Đơn (Giá trên HĐ VAT – là giá phải thanh toán cho Nhà Cung cấp khi nhận hàng); Giá Vốn Thực Tế (Giá sau khi trừ hết chiết khấu & Ctrinh Khuyến mại – được trả sau); Lãi Bán Buôn (nhập thủ công); Lãi bán lẻ (nhập thủ công); Giá Bán Buôn (= Giá Vốn + Lãi Bán Buôn); Giá Bán Lẻ [= (Giá vốn + Lãi Bán lẻ)/Số lượng Quy đổi  Đây là giá bán lẻ cho 1 đơn vị bán lẻ).

• Cài đặt Tồn Kho: Là giao diện cài đặt số lượng Tồn tối đa; tồn tối thiểu của mỗi kho. Khi số lượng ”Tồn Thực Tế” < Tồn tối thiểu tại mỗi kho sẽ tự lấy dự trù số lượng hàng cần mua thêm là ”Tồn Tối Đa” – ”Tồn Thực Tế”

Note: Cơ sở bán lẻ sẽ chỉ được bán hàng theo ”Đơn Vị Bán Lẻ”; Cơ sở bán buôn sẽ chỉ bán theo ”Đơn Vị Bán Buôn”; Tuy nhiên, khi ”Chuyển hàng” từ kho Buôn  Kho Lẻ sẽ chỉ tính theo đơn vị ”Bán Buôn”, tại kho ”Nhận Hàng Chuyển” sau khi nhân viên bấm nút ”Nhận hàng” thì số lượng sẽ được tự động quy đổi ra số lượng của ”Đơn Vị Bán Lẻ” theo công thức: ”Số lượng hàng nhận theo Đơn Vị Bán Lẻ và cần nhập kho” = Số lượng Nhận _ Số lượng Quy Đổi
a. Cấu hình Sản Phẩm nhanh
 Là giao diện để cấu hình và làm giàu dữ liệu sản phẩm nhanh, không cần phải thao tác: Tìm SP  Bấm sửa  Cập nhật.
 Giao diện cấu hình nhanh này cũng là nơi để chọn ra các sản phẩm cố định. Tức là chỉ thêm sản phẩm vào danh sách thông tin bên dưới. Nếu đã tồn tại sản phẩm trong danh sách, thì hiện thông báo ”Đã có Sản Phẩm trong danh sách”  Yêu cầu tìm sản phẩm đó và cập nhật.
 Giao diện phần này chưa xây dựng. Tuy nhiên sẽ cấu hình nhanh các thông tin: Lựa chọn sản phẩm được đưa vào danh sách là Sản phẩm cố định; Làm giàu dữ liệu cho sản phẩm; Cập nhật nhanh Giá Bán + Lãi.
a. Dự trù Mua Hàng
 Là giao diện tạo dự trù những sản phẩm Cố Định cần phải mua.
 Trước mắt có 2 nút:
• Tạo Dự Trù Tự Động: lấy danh sách các sản phẩm cần mua theo tiêu chí: “Tồn Thực Tế” < “Tồn Tối Thiểu”  Số lượng cần mua thêm = “Tồn Tối Đa” – “Tồn Thực Tế”
• Tạo Dự Trù Bằng AI: Logic tính toán như sau: Hệ thống sẽ tự động quét các đơn hàng đã hoàn thành trong 30 ngày qua để tính Tốc độ bán trung bình/ngày cho mỗi sản phẩm + “Lấy Thời gian Chờ Hàng” + Yếu tố số 1 của “Tạo Dự Trù Tự Động”; Hệ thống đưa ra đề xuất “SỐ LƯỢNG HÀNG cần mua” và giải thích lý do [ (nếu Tồn kho hiện tại <= (Tốc độ bán/ngày _ Thời gian chờ hàng về) ]

b. Đơn đã Đặt hàng NCC
 Đây là nơi tất cả các Đơn Mua Hàng, dù được tạo tự động từ chức năng dự trù hay được tạo thủ công, sẽ tập trung về đây để quản lý. Người dùng sẽ truy cập giao diện này từ menu "Kho – Sản phẩm" -> Quản lý Đơn Mua Hàng (PO)
 Bố cục tổng thể:
• Tiêu đề + Các nút bấm: [+ Tạo Đơn Mua Hàng Mới]: Dành cho các trường hợp cần tạo đơn hàng thủ công, không qua chức năng dự trù.
• Khu vực Bộ lọc & Tìm kiếm: Mã Đơn Hàng, Tên NCC, hoặc Tên Sản phẩm có trong đơn hàng. Lọc chi tiết: Nhà Cung Cấp: [Dropdown chọn NCC]; Trạng thái: [Dropdown chọn nhiều trạng thái, ví dụ: Nháp, Chờ Giao Hàng, Hoàn Tất]; Ngày tạo: [Chọn khoảng thời gian]; Người tạo: [Dropdown chọn nhân viên]
• Danh sách Đơn Mua Hàng: Đây là nơi hiển thị tất cả các đơn hàng dưới dạng một bảng dữ liệu có phân trang (10/20/50 giao dịch/trang) rõ ràng:
Mã Đơn Hàng Nhà Cung Cấp Ngày Tạo Người Tạo Tổng Giá Trị (Ước tính) Trạng Thái Hành động
PO-00123 Dược Hậu Giang 28/08/2025 Hệ thống (Dự trù) 12.000.000đ 🔵 Chờ Giao Hàng [Xem] [Hủy] [Nhập Kho]
PO-00122 Traphaco 27/08/2025 Nguyễn Văn A 7.000.000đ ✅ Hoàn Tất [Xem]
PO-00121 Dược phẩm ABC 25/08/2025 Hệ thống (Dự trù) 21.000.000đ 🟡 Đang Nhập Kho [Xem] [Hủy] [Nhập Kho]
PO-00120 Dược Hậu Giang 22/08/2025 Nguyễn Văn A 15.000.000đ ⚫ Nháp [Xem] [Sửa] [Xóa]

Các hành động chi tiết tại giao diện Danh sách đơn đặt hàng:
• [Xem]: Luôn có sẵn ở mọi trạng thái. Cho phép xem lại chi tiết đầy đủ của đơn hàng.
• [Sửa]: Chỉ nên có sẵn khi đơn hàng ở trạng thái "Nháp". Một khi đơn hàng đã được gửi cho nhà cung cấp sẽ không được sửa
• [Xóa]: chỉ nên cho phép xóa hoàn toàn một đơn hàng khi nó còn ở trạng thái "Nháp".
• [Hủy]: Nút này sẽ có ở các trạng thái như "Chờ Giao Hàng", "Đang Nhập Kho". Khi nhấn, nó sẽ yêu cầu người dùng nhập lý do hủy và chuyển trạng thái của đơn hàng thành "Đã Hủy", đồng thời lưu lại lịch sử hành động.
• [Tiến hành Nhập Kho]: Nút này sẽ chỉ hiển thị và có thể nhấn được khi đơn hàng ở trạng thái "Chờ Giao Hàng" hoặc "Hoàn Tất Một Phần".
Giao Diện: "Chi Tiết Phiếu Nhập Kho:
• Tiêu đề Giao diện: Màn hình sẽ hiển thị một tiêu đề lớn, rõ ràng để nhân viên biết họ đang làm việc với đúng đơn hàng: "NHẬP KHO CHO ĐƠN HÀNG PO-00123 (NHÀ CUNG CẤP: DƯỢC HẬU GIANG)" (Ví dụ)
• Nút bấm (có dùng AI): [+ Quét và Đối chiếu từ Hóa đơn VAT] ; [Điền Lô – Hạn Sử Dụng từ Ảnh]
• Nút bấm khác: In Đơn hàng; Xuất Excel; Áp Dụng Chiết khấu và Khuyến Mại; Trả hàng (Trong trường hợp cần trả lại hàng của nhà cung cấp)
• Phần Thông tin chi tiết đơn hàng:
Sản phẩm SL Đặt SL HĐ (AI) SL Thực Nhận Số Lô (AI) Hạn Dùng (AI) Giá HĐ CK Trả Sau GIÁ VỐN Trạng thái
Amoxicillin 50 50 [ 50 ] XYZ5678 28/02/26 100.000đ -3.000đ 97.000đ ✅ Khớp
Paracetamol 100 98 [ 98 ] ABC1234 31/12/27 50.000đ -1.500đ 48.500đ ⚠️ Lệch SL
Vitamin C 20 20 [ 20 ] (Trống) 31/12/25 25.000đ 0đ 25.000đ 🟡 Thiếu TT & HSD Ngắn (dưới 9 tháng)
** Giải thích Nút Bấm và Thông tin:
• Sản phẩm: Tên sản phẩm, hình ảnh thu nhỏ (nếu được)
• SL Đặt: Số lượng đã đặt trên đơn hàng PO-00123 (để đối chiếu).
• SL HĐ (AI): Số lượng mà AI trả về sau khi đọc được từ hóa đơn.
• SL Thực Nhận: Đây là cột duy nhất nhân viên cần nhập liệu sau khi đếm hàng thực tế. Mặc định, hệ thống sẽ tự điền con số từ cột SL HĐ (AI) để tiết kiệm thời gian.
• Số Lô (AI): Số lô mà AI đã tự động đọc và điền. Nếu không đọc được, ô này sẽ trống và tô màu vàng.
• In Đơn Hàng: Khi bấm nút, sẽ in ra đơn hàng nhập về được sắp xếp từ A-Z theo điều kiện là Vị Trí Kệ Hàng của sản phẩm  Tối ưu thời gian đi cất hàng, chỉ cần đi 1 vòng là xong.
• Áp Dụng Chiết khấu và Khuyến Mại: Nút dùng để tính ra Giá Vốn tạm thời, Chiết khấu và CTKM đã được tạo trong mục “Đối tác & Nhà Cung Cấp”. 1 Đơn hàng có thể áp dụng nhiều chiết khấu và CTKM nếu thỏa mãn điều kiện. \*** Luồng Công Việc Của NV Kho:
• Quét mã vạch sản phẩm vật lý: Nhân viên dùng máy quét, quét vào Barcode sản phẩm. Hệ thống tự động nhảy đến đúng ô “Số lượng thực nhận” của sản phẩm đó trên màn hình. Họ đếm số lượng thực tế và nhập con số cuối cùng vào cột "SL Thực Nhận"
• Xử lý các sai lệch: Nếu có dòng báo Vàng hoặc Đỏ, họ sẽ tập trung xử lý: nhập tay thông tin còn thiếu hoặc xác nhận số lượng chênh lệch.
• Hành động: Có thể xóa sản phẩm không có hàng về hoặc sai thông tin.
• Nút [Lưu Nháp]: Cho phép lưu lại công việc đang dang dở để quay lại sau.
• Nút [Hoàn tất Nhập & Ghi nhận Công nợ]: Khi nhấn nút này, hệ thống sẽ thực hiện một loạt hành động: Cập nhật Tồn kho (theo lô được nhập); Ghi nhận Giá vốn; Tạo nợ với NCC: Tự động tạo một phiếu "Công nợ Phải trả NCC"; Cập nhật Trạng thái PO thành Hoàn Tất.
• Nút [In Tem] : in Barcode của sản phẩm về để Nhân Viên dán lên sản phẩm (nếu có).
c. Chuyển Hàng
 Là giao diện Quản lý các hoạt động điều chuyển nội bộ, truy cập từ menu "Kho – Sản phẩm" -> Quản lý Chuyển Kho.
 Giao diện gồm có (tham khảo):
• Công cụ Lọc & Tìm kiếm:
o Tìm kiếm: Theo Mã Phiếu, Tên Sản phẩm có trong phiếu.
o Lọc: Theo Kho Gửi, Kho Nhận, Trạng thái, Ngày tạo, Người tạo.
• Nút hành động chính:
o [+ Tạo Phiếu Chuyển Kho Mới]: Nút bấm tạo phiếu chuyển kho thủ công, để khởi tạo một yêu cầu điều chuyển mới. Các kịch bản chuyển: Tổng  Lẻ; Lẻ  Lẻ; Lẻ  Tổng.
• Danh sách các Phiếu Chuyển Kho có các thông tin sau đây:
Mã Phiếu Kho Gửi Kho Nhận Ngày Tạo Người Tạo/Người Nhận Trạng Thái Hành động
PCK-00045 Kho Tổng B2B Nhà thuốc ĐH 1 29/08/2025 Hệ thống (Dự trù) ✅ Hoàn Tất [Xem]
PCK-00046 Nhà thuốc ĐH 1 Nhà thuốc ĐH 2 29/08/2025 NV A / NV B 🟡 Đang Vận Chuyển [Xem] [Nhận Kho]
PCK-00047 Phòng khám ĐH Kho Tổng B2B 28/08/2025 Quản lý B / NV C 🔵 Chờ Xuất Kho [Xem] [Hủy] [Xuất Kho]
• "Trạng Thái"của các phiểu chuyển:
o ⚫ Nháp (Draft): Phiếu mới tạo, chưa được gửi đi. Có thể sửa, xóa.
o 🔵 Chờ Xuất Kho (Awaiting Dispatch): Yêu cầu đã được xác nhận. Kho gửi cần chuẩn bị và xuất hàng, sau khi Xuất hàng, nhân viên Kho cần bấm nút “Đã Xuất Hàng” để ghi nhận trạng thái tiếp theo.
o 🟡 Đang Vận Chuyển (In Transit) / Cần Kiểm Tra: Kho gửi đã xác nhận xuất hàng. Hàng đang trên đường đến kho nhận.
o ✅ Hoàn Tất (Completed): Kho nhận đã xác nhận nhận đủ hàng. Quy trình kết thúc.
o 🔴 Đã Hủy (Cancelled): Phiếu đã bị hủy. Khi người tạo hoặc người nhận bấm “Hủy”  Chỉ Hủy được khi ở trạng thái “Nháp”
 Giao diện Chi tiết: "Tạo Phiếu Chuyển Kho Mới"
• Phần Thông tin chung:
o Kho Gửi: [Dropdown chọn kho gửi]. Đây là nơi quyết định kịch bản: Tổng  Lẻ; Lẻ  Lẻ; Lẻ  Tổng.
o Kho Nhận: [Dropdown chọn kho nhận].
o Người yêu cầu: (Tự động điền tên USER đang thao tác)
o Thời gian
o Ghi chú: (Tùy chọn)
o Nút “Tạo chuyển kho Tự Động Từ Kho Tổng  Kho Lẻ”: Khi bấm nút này, hệ thống tự động tính ra số lượng hàng cần bổ sung sang kho lẻ và điền vào thông tin vào danh sách bên dưới.
o Nút “In Đơn Chuyển”: tương tự như khi cất hàng, khi ấn nút in, sẽ in ra danh sách sản phẩm cần chuyển theo thứ tự kệ hàng để nhân viên Kho đi lấy hàng về chỉ trong 1 vòng.
• Phần Thêm Sản phẩm:
o Ô tìm kiếm sản phẩm: Khi người dùng bắt đầu gõ tên sản phẩm, hệ thống sẽ chỉ hiển thị các sản phẩm có tồn kho tại Kho Gửi đã chọn, kèm theo số lượng tồn kho khả dụng
o Nếu Quét Barcode: Hệ thống tự động chọn (nếu danh sách bên dưới chưa có) và Cộng thêm sản phẩm (nếu danh sách bên dưới đã có), một dòng mới sẽ được thêm vào danh sách bên dưới và giao diện nhảy về vị trí của sản phẩm đó. Sản phẩm nào được Quét Barcode hoặc nhập thủ công, sẽ có tích xanh để thể hiện rằng sản phẩm đó đã được kiểm tra. Đơn vị tính là Đơn Vị Bán Buôn.
Sản phẩm Số Lô / Hạn Dùng Tồn Kho Gửi Số lượng Chuyển
Panadol Extra [Dropdown chọn lô P123 (HSD: 12/26)] 50 Hộp [ 10 ]
Vitamin C [Dropdown chọn lô V456 (HSD: 08/27)] 100 Hộp [ 20 ]
(\* **Cột "Số Lô / Hạn Dùng":** Đây là cột cực kỳ quan trọng. Hệ thống sẽ hiển thị một danh sách **dropdown** cho phép người dùng **chọn chính xác lô hàng** họ muốn chuyển đi từ kho gửi.

- **Cột "Số lượng Chuyển":** Người dùng nhập số lượng cần chuyển. Hệ thống sẽ **tự động kiểm tra** và không cho phép nhập số lượng lớn hơn số tồn kho của lô hàng đã chọn tại kho gửi.)
  • Tại Kho Gửi: Nhân viên Kho nhấn nút [Xác nhận Xuất Kho]  Hệ thống: Ngay lập tức trừ số lượng tồn kho tại Kho Gửi và chuyển trạng thái phiếu thành "🟡 Đang Vận Chuyển".
  • Tại Kho Nhận: Có hành động tương tự như phiếu “Nhập Kho” khi quét mã vạch sản phẩm nhận về (Ví dụ: sản phẩm Panadol Extra), Hệ thống tự động điều hướng: Ngay lập tức, trên màn hình thiết bị, hệ thống sẽ Tự động nhảy đến ô Số lượng Thực nhận và tô sáng dòng "Panadol Extra". Nhân viên đếm số lượng hàng thực tế nhận được và nhập con số vào ô (ví dụ: 10). Ngay khi con số được nhập, cột "Trạng thái" sẽ tự động cập nhật để cung cấp phản hồi tức thì:
  o Nếu SL Thực Nhận bằng SL Gửi (10 = 10), trạng thái sẽ hiển thị màu xanh lá "✅ Khớp".
  o Nếu SL Thực Nhận ít hơn SL Gửi (ví dụ: nhập 19 cho Vitamin C), trạng thái sẽ hiển thị màu vàng cảnh báo "⚠️ Nhận Thiếu".
  o Nếu SL Thực Nhận nhiều hơn SL Gửi, trạng thái sẽ là "⚠️ Nhận Thừa".
  Sau khi nhân viên tại kho nhận bấm [Hoàn tất Nhận Kho]: Hệ thống sẽ ngay lập tức cộng số lượng hàng vừa nhận vào tồn kho của Kho Nhận nhưng với số lượng là của Đơn Vị Bán Lẻ ( = Số lượng chuyển x Đơn Vị Quy Đổi). Nếu có sai lệch (Nhận Thiếu/Thừa): Hệ thống sẽ yêu cầu một bước xác nhận bổ sung và ở trạng thái “Cần Kiểm Tra Lại” và tạo ra một ghi chú về sự sai lệch này trên phiếu chuyển kho và hệ thống sẽ chỉ cộng đúng số lượng "Thực Nhận" vào tồn kho.
  d. Kiểm Hàng
   Giao diện "Quản lý Phiếu Kiểm Kho" quản lý mọi hoạt động kiểm kê, truy cập từ menu "Kho – Sản phẩm" -> Kiểm Hàng.
   Giao diện chính:
  • Công cụ Lọc & Tìm kiếm:
  o Tìm kiếm theo Mã Phiếu, Tên Kho, Người tạo.
  o Lọc theo Trạng thái, Ngày tạo.
  • Nút hành động chính:
  o [+ Tạo Phiếu Kiểm Kho Mới]: Nút để bắt đầu một phiên kiểm kê mới.
  • Phần thông tin chính “Danh sách các Phiếu Kiểm Kho”:
  Mã Phiếu Kho Kiểm Kê Ngày Tạo Người Tạo Trạng Thái Hành động
  PKK-0012 Nhà thuốc ĐH 1 29/08/2025 Quản lý A ✅ Đã Hoàn Tất [Xem]
  PKK-0013 Kho Tổng B2B 30/08/2025 Quản lý B 🟡 Đang Kiểm Kê [Xem]
  PKK-0014 Phòng khám ĐH 30/08/2025 Quản lý A 🔵 Mới Tạo [Xem] [Hủy] [Bắt đầu Kiểm]
  ** Các trạng thái của một “Phiếu Kiểm Kho”:
  • Mới Tạo: Phiếu mới tạo nhưng chưa kiểm. để kiểm kê, cần bấm nút “Bắt đầu Kiểm Kê".
  • 🟡 Đang Kiểm Kê: Nhân viên đang trong quá trình đếm hàng tại kho. Ở trạng thái này, hệ thống sẽ tạm thời "đóng băng" mọi hoạt động xuất/nhập/chuyển kho tại kho đang kiểm kê để đảm bảo số liệu không bị thay đổi trong quá trình đếm.
  • ✅ Đã Hoàn Tất: Nhân viên bấm nút đã xử lý xong chênh lệch, tồn kho trên hệ thống đã được cập nhật lại theo số liệu thực tế. Hệ thống tự động tạo ra 1 phiếu Thu/Chi tiền cho Nhân Viên tại Kho được kiểm kê, nếu số tiền bị chênh lệch.
  ** Giao diện "Tạo Phiếu Kiểm Kho Mới":
   Kho cần kiểm kê: [Dropdown chọn kho, ví dụ: Nhà thuốc ĐH 1]
   Nút “Tạo Danh Sách Kiểm Kê”: khi bấm nút này, lấy ra danh sách 300 sản phẩm cần kiểm kê, các sản phẩm này đang có lịch sử chưa được kiểm kê trong vòng 30 ngày. (danh sách này có thể Thêm/Sửa/Xóa)
   Nhân viên thực hiện: [Chọn một hoặc nhiều nhân viên được giao nhiệm vụ]
   Ghi chú: (Ví dụ: "Kiểm kê định kỳ cuối tháng 8/2025").
   Nút bấm “Bắt đầu Kiểm Kê”: để vào quy trình kiểm kê và “Đóng băng” các hoạt động của các sản phẩm đang được kiểm kê.
  ** Hành động "Thực Hiện Kiểm Kê" - Tối Ưu Nhất cho Nhân Viên Kiểm Kê: Khi nhân viên được giao nhiệm vụ nhấn [Bắt đầu Kiểm], hiển thị một giao diện được thiết kế cho các thiết bị di động có thể quét bằng Camera điện thoại:
   Danh sách sản phẩm cần kiểm sẽ được tự động sắp xếp theo vị trí kệ hàng để nhân viên đi một vòng kho là hoàn thành, không phải chạy đi chạy lại
   Quy trình quét:
  • Nhân viên đến kệ A-01-01, cầm sản phẩm Panadol Extra lên và quét mã vạch.
  • Trên màn hình, hệ thống tự động nhảy đến đúng dòng "Panadol Extra" và con trỏ đặt sẵn vào ô "Số lượng Thực tế".
  • Nhân viên đếm và nhập số lượng (ví dụ: 15 Hộp, 5 Vỉ). Hệ thống sẽ tự quy đổi ra đơn vị nhỏ nhất để lưu trữ.
  • Phản hồi tức thì: Ngay khi nhập xong, hệ thống sẽ đánh dấu dòng đó là "✅ Đã đếm", Nhân viên chỉ cần nhìn vào danh sách, thấy dòng nào chưa có dấu tích xanh là biết mình còn sót sản phẩm nào.
  • Cho phép đếm nhiều lần: Nếu nhân viên tìm thấy thêm sản phẩm Panadol Extra ở một vị trí khác, họ chỉ cần quét lại, hệ thống sẽ nhảy đúng về dòng đó và cho phép họ cộng dồn số lượng.
  • Hoàn tất Kiểm đếm: Khi tất cả các sản phẩm đã được đánh dấu "✅ Đã đếm", nhân viên nhấn nút [Hoàn Tất kiểm hàng].
  ** Giao diện "Đối Soát Kiểm Kho":
   Tại giao diện này, sẽ chỉ hiển thị những sản phẩm có sự chênh lệch giữa số liệu trên sổ sách và số liệu đếm thực tế.
   Bảng phân tích số liệu:
  Sản phẩm Tồn trên hệ thống Tồn Thực Tế Chênh Lệch (SL) Chênh Lệch (Giá Vốn) Lý do Chênh lệch Hành động Đề xuất
  Panadol Extra 15 Hộp, 5 Vỉ 15 Hộp, 2 Vỉ 🔴 -3 Vỉ 🔴 -15.000đ [Dropdown chọn lý do] [Tạo Phiếu Điều Chỉnh]
  Vitamin C 20 Hộp 21 Hộp 🟢 +1 Hộp 🟢 +100.000đ [Dropdown chọn lý do] [Tạo Phiếu Điều Chỉnh]
  Giải thích các cột:
   Chênh Lệch (SL): Hệ thống tự động tính toán (Thực Tế - Sổ Sách) và mã hóa màu sắc: Màu đỏ cho thấy sự thất thoát, màu xanh cho thấy sự dư thừa.
   Chênh Lệch (Giá Vốn): Đây là cột quan trọng nhất để bảo vệ tài sản của người dùng. Hệ thống tự động nhân số lượng chênh lệch với giá vốn trung bình của sản phẩm để cho người dùng thấy ngay lập tức giá trị tiền hàng bị ảnh hưởng.
   Lý do Chênh lệch: Đây là một trường bắt buộc và mang tính tương tác. Thay vì một ô trống, đây sẽ là một dropdown với các nguyên nhân phổ biến được định nghĩa trước, giúp chuẩn hóa dữ liệu và phân tích sau này:
  • Hàng hỏng/vỡ/hết hạn
  • Hao hụt tự nhiên (đối với một số mặt hàng)
  • Lỗi nhập liệu từ các phiếu trước
  • Giao nhầm hàng cho khách
  • Nghi ngờ thất thoát/mất cắp
  • Khác (yêu cầu ghi rõ)
   Hành động Đề xuất: Dựa vào lý do được chọn, hệ thống có thể gợi ý hành động phù hợp. Ví dụ, nếu lý do là "Hàng hỏng", hệ thống sẽ đề xuất tạo một "Phiếu Hủy Hàng".
   Khi Bấm nút: [Tạo Phiếu điều chỉnh]:
  • Tạo "Phiếu Điều Chỉnh Kho" tự động: Hệ thống sẽ tạo ra một phiếu điều chỉnh duy nhất, ghi lại tất cả các thay đổi (tăng/giảm) đối với các sản phẩm bị chênh lệch, kèm theo lý do đã được chọn. Phiếu này sẽ được lưu lại vĩnh viễn để phục vụ việc kiểm tra, đối soát sau này.
  • Cập nhật Tồn kho trên Phần Mềm: Đây là bước quan trọng nhất. Hệ thống sẽ chính thức cập nhật lại số lượng tồn kho trên sổ sách cho bằng với số lượng tồn kho thực tế đã đếm.
  • Hạch toán Tài chính: Giá trị của sự chênh lệch (cột Chênh Lệch (Giá Vốn)) sẽ được tự động chuyển đến bộ phận kế toán (dưới dạng một Phiếu Thu/Chi) để hạch toán vào các tài khoản phù hợp (ví dụ: chi phí hàng hỏng, hoặc một tài khoản chờ xử lý cho các trường hợp thất thoát).
  • Hoàn tất Phiếu Kiểm Kho: Trạng thái của phiếu kiểm kê PKK-0013 sẽ được chuyển thành "✅ Đã Hoàn Tất".
  e. Cập nhật Giá Vốn: Là giao diện cập nhật lại giá vốn của mỗi sản phẩm. Chức năng này sẽ nằm ở menu "Kho – Sản phẩm" -> Điều chỉnh giá vốn và chỉ những vai trò được cấp quyền đặc biệt (Ví dụ: như Kế toán trưởng, Quản lý cấp cao) mới có thể truy cập. Giao diện "Tạo Phiếu Điều Chỉnh Giá Vốn" như sau:

* Bước 1: Chọn Lô Hàng Cần Điều Chỉnh:
  o Tìm kiếm Sản phẩm: [Người dùng tìm và chọn sản phẩm, ví dụ: Amoxicillin 250mg].
  o Chọn Lô Hàng Cần Điều Chỉnh: [Dropdown hiển thị tất cả các lô hàng của sản phẩm đó đang có trong kho, ví dụ: Lô XYZ5678 (HSD: 28/02/26) - Nhập ngày 29/08/2025].
* Bước 2: Thực Hiện Điều Chỉnh
  o Giá Vốn Hiện tại (Hệ thống): 97.000đ (Hệ thống tự hiển thị, không thể sửa).
  o Giá Vốn Mới (Điều chỉnh): [ 96.500 ] (Người dùng nhập giá vốn đúng).
  o Lý do Điều chỉnh: [Trường bắt buộc - Dropdown chọn lý do].
* Nút bấm: [Gửi Yêu cầu Điều chỉnh] hoặc [Cập nhật Giá Vốn]
  f. Sản phẩm Gói & Dịch Vụ
   Giao diện là danh sách các sản phẩm bán COMBO và Dịch Vụ
   Giao diện có tiêu đề QUẢN LÝ GÓI & DỊCH VỤ
   Giao diện có một nút lớn, rõ ràng và duy nhất để bắt đầu: [+ Thêm Gói hoặc Dịch vụ Mới]
   Công cụ Lọc & Tìm kiếm:
  • Tìm kiếm: Theo Tên Gói/Dịch vụ, Mã SKU.
  • Lọc theo Loại: [Checkbox: Gói (Combo), Dịch vụ]
  • Lọc theo Trạng thái: [Dropdown: Đang Hiệu lực, Sắp Hiệu lực, Hết Hạn]
   Danh sách các Gói & Dịch vụ: Bảng dữ liệu sẽ hiển thị các thông tin sau (thông tin ví dụ):
  Tên Gói / Dịch vụ Loại Giá Bán Ngày Hiệu lực Trạng thái Hành động
  Gói Chăm Sóc Bé Ốm Gói (Combo) 250.000đ 01/09 - 30/09 ✅ Đang Hiệu lực [Xem] [Sửa] [Nhân bản]
  Phí Khám Nhi (BS. Nguyễn A) Dịch vụ 200.000đ 01/01 - 31/12 ✅ Đang Hiệu lực [Xem] [Sửa] [Nhân bản]
  Gói Tiêm chủng Trọn đời Gói (Combo) 25.000.000đ 01/01 - 31/12 ⚫ Hết Hạn [Xem] [Nhân bản]
  (_ **Các cột "thông minh":** `Giá Vốn (TB)` và `Lợi nhuận (TB)` được hệ thống tự động tính toán và hiển thị, giúp người dùng có cái nhìn tài chính tức thì. _ **Nút `[Nhân bản]`:** Một công cụ tiết kiệm thời gian. Nếu muốn tạo một gói mới tương tự một gói đã có, chỉ cần nhấn "Nhân bản" và chỉnh sửa lại một vài thông tin thay vì phải tạo lại từ đầu.)
  Luồng Công Việc Tạo Mới:
  ** Trường Hợp 1: Tạo Combo và Dịch vụ sử dụng 1 lần.
   Bước 1: Nhân viên bấm nút [+ Thêm Gói / Dịch vụ Mới]
   Bước 2: Giao diện thêm gói hiện ra,phân thành các khu vực chính:
  • Phần 1 - Thông tin chung: Loại (Combo Sản phẩm/Dịch vụ 1 lần); Tên; Mã Dịch vụ / SKU; Mô tả Ngắn; Ngày bắt đầu hiệu lực; Ngày kết thúc hiệu lực.
  • Phần 2 - Cấu hình Chi phí Dịch vụ (Giá Vốn): Nút bấm: [+ Thêm Thành phần Chi phí] (ví dụ: chi phí bác sĩ 30%) và nút [+ Thêm Vật tư tiêu hao]; Khi nhấn nút, một cửa sổ pop-up sẽ hiện ra, cho phép tìm kiếm và chọn trực tiếp các sản phẩm vật lý từ Danh mục Sản phẩm Vật lý của của Công ty (ví dụ: Găng tay y tế, Bông gạc, Que đè lưỡi...).
  Tên Vật tư (Lấy từ Kho) Đơn vị Số lượng Tiêu hao / 1 lần DV
  Găng tay y tế Latex (Size M) Đôi [ 1 ]
  Bông gạc tiệt trùng 5cm x 5cm Miếng [ 2 ]
  Que đè lưỡi gỗ Cái [ 1 ]
  • Phần 3 – Cấu Hình giá bán; giá vốn; lợi nhuận.
  • Khi thực hiện bán Combo hoặc thực hiện Dịch Vụ, hệ thống tự trừ đi số lượng tồn kho các sản phẩm vật lý tại kho đã thực hiện như trên.
  ** Trường Hợp 1: Tạo Combo và Dịch vụ sử dụng nhiều lần.
   Bước 1: Nhân viên bấm nút [+ Thêm Gói / Dịch vụ Nhiều Lần]
   Bước 2: Giao diện hiện ra,phân thành các khu vực chính:
  • Phần 1 - Thông tin chung: Tên Gói/Dịch Vụ; Mã Dịch vụ / SKU; Mô tả Ngắn; Ngày bắt đầu hiệu lực; Ngày kết thúc hiệu lực.
  • Hạn sử dụng dịch vụ (ví dụ: 365 ngày) – Người tạo phải tự nhập con số này
  • Phần 2 – Khu vực cấu hình lên sản phẩm Gói đa lần: Nút [Thêm Sản phẩm/Dịch vụ], sau khi thêm các sản phẩm và dịch vụ, giao diện phần này sẽ hiện ra giống như sau:
  Tên Sản phẩm/Dịch vụ Ngày thực hiện Đơn vị Số Lượng Hành Động
  Dịch vụ: Tiêm Cúm ABC 15/08/2025 Lần 1 Xóa
  Dịch vụ: Khám Tổng Quát 30/08/2025 Lần 1 Xóa
  Dịch vụ: Tiêm HPV 15/092025 Lần 1 Xóa
  "Sổ Cái Dịch Vụ" - Quản lý Quyền lợi của Khách hàng:
   Khi bán hàng: Khi lễ tân bán "Gói Đa Lần" cho một bệnh nhân, hệ thống sẽ tự động tạo ra một mục trong "Sổ Cái Dịch Vụ" của bệnh nhân đó.
   Hiển thị trong Hồ sơ Bệnh nhân: Trong giao diện "Thông tin Bệnh nhân" mà lễ tân hay bác sĩ xem, sẽ có một Tab/Khu vực mới và nổi bật "Các Gói Dịch vụ Đã Mua & Quyền lợi", ví dụ:
  Tên Gói Dịch vụ Ngày Mua Hiệu lực đến Số lần còn lại Hành động
  Gói 3 mũi tiêm Cúm người lớn 29/08/2025 28/08/2026 3 / 3 [Sử dụng 1 lần]
  Gói 3 mũi HPV 15/07/2025 14/07/2027 1 / 3 [Sử dụng 1 lần]
  Quy trình "Sử dụng Dịch vụ" tại Quầy Lễ tân & Phòng Tiêm:
  Bước 1: Bệnh nhân đến sử dụng “Dịch vụ Đa Lần” đầu tiên. Lễ tân tìm và mở hồ sơ của bệnh nhân.
  Bước 2: Xác thực quyền lợi. Lễ tân nhìn vào khu vực "Các Gói Dịch vụ Đã Mua" và thấy danh sách các dịch vụ bệnh nhân còn được sử dụng (Ví du: "3 / 3" lần tiêm Cúm)
  Bước 3: Ghi nhận sử dụng (Redemption). Lễ tân nhấp vào nút [Sử dụng] trong danh sách. Một cửa sổ xác nhận sẽ hiện ra: "Xác nhận Khách hàng đã sử dụng Dịch vụ này”  Ok/Hủy
  Bước 4: Khi lễ tân xác nhận: Cập nhật "Sổ Cái": Số lần còn lại trong sổ cái của bệnh nhân ngay lập tức được cập nhật trừ đi 1 dịch vụ  Tạo Hóa đơn 0 đồng: Hệ thống tạo một hóa đơn cho lần sử dụng dịch vụ này. Với phí dịch vụ là 0 đồng, và ghi chú rõ ràng "Thanh toán từ Gói Dịch vụ Trả trước …". Điều này đảm bảo vẫn ghi nhận một lượt thăm khám mà không thu tiền của khách.
  Tự động Trừ kho Vật tư: Quan trọng nhất, hệ thống sẽ tự động kích hoạt "Phiếu Xuất Kho Vật tư Dịch vụ" cho 1 lần "Dịch vụ Tiêm Vắc-xin Cúm". Tức là 1 lọ vắc-xin cúm, 1 bơm kim tiêm, găng tay, bông gạc... sẽ được trừ khỏi tồn kho một cách chính xác.
  Ngăn chặn sử dụng quá số lần: sử dụng xong 1 dịch vụ, nút [Sử dụng] sẽ tự động bị mờ đi và không thể nhấn được nữa.
  \*\* Quản lý và Báo cáo Tài chính Nâng cao: Quy trình trên giúp mở ra các khả năng báo cáo tài chính và quản trị như sau:
  Báo cáo Công nợ Dịch vụ Trả trước: Hệ thống sẽ cho người dùng biết chính xác tổng giá trị các dịch vụ mà công ty đã thu tiền nhưng "chưa phục vụ". Đây là một con số cực kỳ quan trọng trong kế toán.
  Báo cáo Tần suất Sử dụng: Giúp người dùng biết các gói combo có thực sự được khách hàng sử dụng hay không, từ đó điều chỉnh các chương trình kinh doanh hoặc gói trong tương lai.
  5.4 Đối Tác – Nhà Cung Cấp

## Menu Chính (MenuBar)

Luồng công việc bắt đầu từ thanh menu điều hướng chính của hệ thống.
• Nút cha: [Đối Tác]
o Đây là một mục menu cấp cao nhất.
o Hành động: Khi người dùng rê chuột hoặc nhấp vào nút [Đối Tác], một menu con (dropdown) sẽ xuất hiện.
• Nút con: [Nhà Cung Cấp]
o Nằm trong menu con của [Đối Tác].
o Hành động: Khi nhấp vào nút này, hệ thống sẽ điều hướng người dùng đến trang "Danh sách Nhà Cung Cấp", là trung tâm quản lý cho toàn bộ các nhà cung cấp của công ty.

---

## Trang Danh Sách Nhà Cung Cấp (Master View)

Đây là giao diện tổng quan, nơi bạn có thể xem, tìm kiếm và thực hiện các thao tác nhanh với tất cả NCC.
Giao diện chính
• Một bảng (table) hiển thị danh sách các NCC với các cột thông tin quan trọng như: Mã NCC, Tên NCC, Người liên hệ, Trạng thái, và Công nợ.
• Các công cụ tìm kiếm và bộ lọc để nhanh chóng tìm ra NCC mong muốn.
Các Nút Chức Năng Chính (Nút cha)
• [+ Thêm Nhà Cung Cấp]:
o Hành động: Mở ra một cửa sổ (dialog) dưới dạng form để nhập thông tin cho một NCC mới.
o Các trường thông tin: Tên NCC, Mã NCC (có thể tự sinh), Mã số thuế, Địa chỉ, Người liên hệ, Số điện thoại...
• [Import Excel] / [Export Excel]:
o Hành động: Cho phép người dùng tải lên một file Excel chứa danh sách NCC để thêm mới hoặc cập nhật hàng loạt, và ngược lại, xuất toàn bộ danh sách NCC ra file Excel.
Các Hành Động Trên Mỗi Dòng (Nút con)
Mỗi dòng NCC trong bảng sẽ có một bộ các nút hành động riêng:
• [Xem chi tiết] (Biểu tượng con mắt 👁️):
o Hành động: Đây là nút quan trọng nhất. Khi nhấp vào, hệ thống sẽ đưa người dùng đến trang "Chi Tiết NCC" tương ứng, nơi chứa toàn bộ thông tin sâu hơn về NCC đó.
• [Chỉnh sửa] (Biểu tượng bút chì ✏️):
o Hành động: Mở ra cửa sổ form (tương tự như form Thêm mới) nhưng đã được điền sẵn thông tin của NCC đó, cho phép người dùng chỉnh sửa nhanh.
• [Xóa] (Biểu tượng thùng rác 🗑️):
o Hành động: Hiển thị một hộp thoại yêu cầu xác nhận. Nếu người dùng đồng ý, hệ thống sẽ xóa NCC đó (hoặc chuyển sang trạng thái "Ngừng hợp tác").

---

## Trang Chi Tiết Nhà Cung Cấp (Detail View)

Đây là "phòng làm việc chuyên sâu" cho một NCC, được tổ chức bằng các tab để quản lý thông tin một cách khoa học.
Tab 1: THÔNG TIN CHUNG
• Giao diện: Hiển thị toàn bộ thông tin chi tiết của NCC dưới dạng thẻ thông tin (SupplierInfoCard), bao gồm thông tin liên hệ, địa chỉ, thông tin ngân hàng.
• Nút bấm: Có một nút [Chỉnh sửa] lớn ở góc trên, cho phép sửa toàn bộ thông tin này.
Tab 2: HỢP ĐỒNG & KHUYẾN MẠI
• Giao diện: Hiển thị danh sách các hợp đồng hoặc chương trình khuyến mại (CTKM) đã ký kết với NCC.
• Nút bấm chính:
o [+ Thêm Hợp Đồng / CTKM]:
 Hành động: Mở ra một cửa sổ với quy trình 2 bước để thiết lập một CTKM mới:

1. Bước 1: Nhập các thông tin cơ bản như Tên hợp đồng, Thời gian hiệu lực.
2. Bước 2: Thiết lập các "Nhóm Sản phẩm" được áp dụng và xây dựng các "Quy tắc Chiết khấu" chi tiết (ví dụ: "Mua nhóm sản phẩm A với tổng giá trị trên 10 triệu thì được chiết khấu 5%").
   Tab 3: ÁNH XẠ SẢN PHẨM
   • Giao diện: Đây là "cuốn từ điển phiên dịch", hiển thị một bảng gồm 2 cột chính: "Sản Phẩm Của NCC" và "Sản Phẩm trên Nam Việt EMS".
   • Mục đích: Giúp hệ thống hiểu được "Mã SP A" của NCC tương ứng với "Sản phẩm X" trong hệ thống của chúng ta. Đây là bước tối quan trọng để các tính năng AI đọc hóa đơn có thể hoạt động chính xác.
   • Nút bấm chính:
   o [Import Excel]: Cho phép tải lên danh sách sản phẩm của NCC để nhanh chóng có dữ liệu cho việc ánh xạ.
   o [Lưu Toàn Bộ Ánh X xạ]: Sau khi người dùng thực hiện việc "ghép nối" các sản phẩm ở 2 cột, nút này sẽ lưu lại toàn bộ "cuốn từ điển".
   • Hành động trên dòng:
   o Người dùng có thể tìm kiếm và chọn sản phẩm tương ứng trên hệ thống Nam Việt EMS cho mỗi dòng sản phẩm của NCC.

5.6 Quản lý Marketing
5.6.1 Kiến trúc Toàn diện Module Marketing và Dashboard Marketing
A. Cấu trúc Menu & Giao diện
Menu Quản lý Marketing sẽ có 4 nút con, tương ứng với 4 GIAO DIỆN làm việc chính:

1. Dashboard Marketing: Giao diện tổng quan, trung tâm chỉ huy.
2. Quản lý Chiến dịch: Giao diện danh sách, nơi quản lý và theo dõi.
3. Công cụ Marketing: Giao diện chứa các công cụ chuyên biệt như "Trình tạo Phân khúc", "Thư viện Nội dung & Mẫu", "Quản lý Mã Giảm giá" (nơi sẽ có tính năng tạo QR code).
4. Quản lý Chatbot: Giao diện chuyên biệt để cài đặt và "dạy" cho Chatbot AI.
   B. Giao diện "Dashboard Marketing" - Bức tranh Toàn cảnh 360 độ
   Đây là giao diện đầu tiên, là "buồng lái" của trưởng phòng marketing. Nó cung cấp một cái nhìn tổng thể về toàn bộ "chiến trường".
   Bố cục Bento Grids:
   Widget 1: Các Chỉ số Hiệu suất Chính (KPIs)
   • Hiển thị các con số quan trọng nhất của tháng này, có so sánh với tháng trước:
   o Tổng Chi phí: 50 Triệu VNĐ (🔻 giảm 5%)
   o Số KH Mới: 150 (📈 tăng 10%)
   o Chi phí / 1 KH Mới (CPA): 333.000 VNĐ (🔻 tốt hơn 15%)
   o Lợi tức Đầu tư (ROI): +35% 🟢 (So với +28% của tháng trước)
   Widget 2: Lịch Chiến dịch (Campaign Calendar)
   • Một giao diện lịch trực quan, hiển thị các chiến dịch bằng các dải màu:
   o Xanh lá: Đang chạy
   o Xanh dương: Sắp diễn ra
   o Xám: Đã kết thúc
   • Giúp người quản lý thấy ngay các "khoảng trống" trong kế hoạch marketing để lấp đầy.
   Widget 3: Phễu Chuyển đổi Tổng hợp (Tháng này)
   • Một biểu đồ phễu cho thấy hiệu quả tổng hợp của tất cả các chiến dịch đang chạy, giúp nhận diện nhanh các điểm yếu chung trong quy trình.
   Widget 4: Hiệu quả Kênh (Channel Performance)
   • Một biểu đồ cột đơn giản, so sánh ROI hoặc CPA giữa các kênh: Zalo, Facebook, SMS...
   Widget 5: "Cố vấn Marketing AI" (Tích hợp AI)
   • Đây là bộ não phân tích của Dashboard. Nó sẽ tự động quét tất cả dữ liệu trên màn hình và đưa ra nhận định:
   🤖 CỐ VẤN MARKETING AI
   💡 PHÂN TÍCH & NHẬN ĐỊNH:
   o "ROI tổng thể tháng này đang ở mức tốt (35%). Kênh Zalo tiếp tục cho thấy hiệu quả vượt trội với CPA thấp nhất. Tuy nhiên, lịch chiến dịch từ ngày 15 đến 30 của tháng tới hiện đang có một khoảng trống lớn, có thể ảnh hưởng đến dòng khách hàng mới."
   ** actionable HÀNH ĐỘNG GỢI Ý:**
5. [Nên làm] Phân bổ thêm 15% ngân sách quảng cáo cho các chiến dịch trên kênh Zalo.
6. [Ưu tiên cao] Lên kế hoạch cho một chiến dịch nhỏ (mini-campaign) vào nửa cuối tháng tới để duy trì đà tăng trưởng. Gợi ý: Một chương trình giảm giá chớp nhoáng (flash sale) nhắm vào tệp khách hàng VIP chưa mua sắm trong 30 ngày qua.
   5.6.2 Nút “Quản lý Chiến dịch”
   Giao diện 1: "Quản lý Chiến dịch" - Trung tâm Điều hành Chiến lược
   Mục đích: Đây là giao diện làm việc chính của đội ngũ marketing, nơi họ có thể xem, quản lý và đánh giá hiệu quả của tất cả các chiến dịch từ một nơi duy nhất. Nó không chỉ là một danh sách, mà là một trung tâm điều hành.
   Truy cập: Quản lý Marketing -> Quản lý Chiến dịch
   A. Bố cục & Công cụ Quản lý:
   • Bộ lọc mạnh mẽ:
   o Trạng thái: [Dropdown: Đang chạy, Sắp diễn ra, Đã kết thúc, Nháp]
   o Kênh: [Checkbox: Zalo, SMS, Email...]
   o Người tạo: [Dropdown chọn nhân viên]
   • Các nút hành động chính:
   o [+ Tạo Chiến dịch Mới]: Nút để bắt đầu quy trình tạo chiến dịch mà chúng ta đã thảo luận.
   o [Nhập/Xuất Excel]: Để xử lý dữ liệu hàng loạt.
   B. Bảng Danh sách Chiến dịch Thông minh:
   Bảng này được thiết kế để cung cấp thông tin nhanh và có tính hành động cao.
   Trạng thái Tên Chiến dịch Thời gian Ngân sách / Chi phí Kết quả Nhanh (KPIs) Hành động
   🟢 Đang chạy Ưu đãi Gói khám SK Quý 4 01/10 - 31/12 50tr / 15.2tr Chuyển đổi: 75 Doanh thu: 63.7tr ROI: +27.5% [Xem Báo cáo] [Tạm dừng]
   🔵 Sắp diễn ra Chăm sóc KH VIP tháng 9 01/09 - 30/09 10tr / 0đ - [Xem] [Sửa] [Hủy]
   ⚫ Đã kết thúc Chiến dịch Mùa Tựu Trường 01/08 - 31/08 20tr / 20tr Chuyển đổi: 152 Doanh thu: 95.2tr ROI: +376% [Xem Báo cáo] [Nhân bản]

• Cột "Kết quả Nhanh": Cung cấp các chỉ số quan trọng nhất để người quản lý có thể "liếc mắt" là biết ngay chiến dịch nào đang hiệu quả, chiến dịch nào không.
• Cột "Hành động":
o [Xem Báo cáo]: Dẫn đến giao diện đo lường chi tiết mà chúng ta đã thống nhất.
o [Sửa]: Chỉ khả dụng với các chiến dịch "Nháp" hoặc "Sắp diễn ra".
o [Nhân bản]: Một công cụ cực kỳ hữu ích, cho phép sao chép toàn bộ một chiến dịch cũ để tạo một chiến dịch mới tương tự, tiết kiệm hàng chục bước cài đặt.
Giao diện "Tạo Chiến dịch Mới" - Bước 1:
Các thông tin Tên Chiến dịch, Mục tiêu..., cơ bản sau:
• Tên Chiến dịch*: (Ô văn bản) Ví dụ: "Ưu đãi Gói khám Sức khỏe Tổng quát Quý 4/2025"
• Mục tiêu chính*: (Dropdown) Đây là trường quan trọng nhất để đo lường thành công. ví dụ:
• Thu hút Bệnh nhân Mới
• Thúc đẩy Doanh số một Dịch vụ/Sản phẩm cụ thể
• Tăng tỷ lệ Khách hàng cũ quay lại
• Thời gian diễn ra*: Từ ngày [lịch] đến ngày [lịch]
• Ngân sách Dự kiến*: [Ô nhập số] VNĐ
• Phạm vi Áp dụng Chiến dịch:
o Áp dụng Chung:
 [ ] Toàn bộ hệ thống
o Theo Kênh Kinh doanh:
 [ ] Toàn bộ Kênh Cửa hàng
 [ ] Toàn bộ Kênh Bán Buôn
o Theo Cơ sở Cụ thể (Chi nhánh): (Cho phép chọn nhiều kho/cơ sở)
 [ ] Nhà thuốc ĐH 1
 [ ] Phòng khám ĐH
 [ ] Kho B2B
Hệ thống sẽ tự động thực thi phạm vi này:
• Mã ưu đãi của chiến dịch sẽ chỉ có hiệu lực tại các cửa hàng/kênh đã chọn.
• "Trình tạo Phân khúc KH" ở bước 2 sẽ chỉ lọc dữ liệu khách hàng từ các cơ sở đã được chọn, đảm bảo nhắm mục tiêu chính xác.
Bước 2: Lựa Chọn Đối Tượng Mục Tiêu - "Bộ não" của Chiến dịch
Đây là nơi hệ thống phát huy sức mạnh của việc tích hợp dữ liệu từ CRM, POS và Phòng khám. Chúng ta sẽ xây dựng một "Trình tạo Phân khúc Khách hàng" (Segment Builder) cực kỳ mạnh mẽ.
• Giao diện: Cho phép người dùng thêm các quy tắc lọc "VÀ"/"HOẶC" để xây dựng tệp khách hàng mục tiêu.
• Các loại điều kiện lọc:
o Nhân khẩu học: Tuổi (từ... đến...), Giới tính, Khu vực (Quận/Huyện).
o Lịch sử Giao dịch: Tổng chi tiêu > X VNĐ, Đã mua sản phẩm Y, Chưa từng mua sản phẩm Z, Lần mua cuối cùng > 6 tháng trước.
o Lịch sử Khám bệnh/Tiêm chủng (Tuyệt đối bảo mật và có kiểm soát): Có chẩn đoán ICD-10 là [mã bệnh], Trẻ em trong độ tuổi cần tiêm vắc-xin A nhưng chưa tiêm, Bệnh nhân bệnh mạn tính (tiểu đường, huyết áp) chưa tái khám trong 3 tháng.
• Ví dụ một phân khúc:
TÌM TẤT CẢ KHÁCH HÀNG THỎA MÃN: ( Tuổi từ 40 trở lên ) VÀ ( Có chẩn đoán là Tăng huyết áp (I10) ) VÀ ( Lần khám cuối cùng cách đây hơn 6 tháng )
• Kết quả ước tính: Khi các điều kiện được thêm vào, hệ thống sẽ hiển thị số lượng khách hàng phù hợp trong thời gian thực: Ước tính có: 258 khách hàng.
Bước 3: Thiết Kế Nội Dung & Kênh Truyền Thông
• Chọn Kênh triển khai: [Checkbox: SMS Marketing, Zalo ZNS, Email...]
• Soạn Nội dung: Một trình soạn thảo cho mỗi kênh đã chọn, cho phép chèn các "biến" để cá nhân hóa thông minh.
o Ví dụ: "Chào {TenKhachHang}, Công ty Nam Việt trân trọng mời người dùng đến tái khám theo lịch hẹn."
• Tạo Mã Ưu đãi & Theo dõi: Đây chính là nơi chúng ta sẽ tạo ra các mã như BEKHOE25 để theo dõi chuyển đổi tại quầy Lễ tân hoặc POS.

C. Tích hợp "Cố vấn Marketing AI" - Nâng cấp Trí thông minh
Đây là giải pháp cho yêu cầu cốt lõi của người dùng: để AI hỗ trợ và định hướng cho nhân viên marketing. Chúng ta sẽ tích hợp một widget "Cố vấn Marketing AI" vào chính quy trình tạo chiến dịch.
Vị trí: Widget này sẽ xuất hiện ở Bước 2: Lựa Chọn Đối Tượng Mục Tiêu, sau khi nhân viên đã chọn Mục tiêu chính và Phạm vi Áp dụng.
Luồng hoạt động:

1. Nhân viên chọn Mục tiêu: ví dụ "Tăng tỷ lệ Khách hàng cũ quay lại".
2. Họ chọn Phạm vi: "Nhà thuốc ĐH 1".
3. "Cố vấn AI" tự động phân tích và đưa ra gợi ý:
   🤖 CỐ VẤN MARKETING AI
   Phân tích & Gợi ý cho Mục tiêu "Tăng tỷ lệ Quay lại" tại "Nhà thuốc ĐH 1":
   o 💡 Phân tích: "Dữ liệu cho thấy, tại Nhà thuốc ĐH 1, nhóm khách hàng có con nhỏ (2-6 tuổi) có tỷ lệ mua lại các sản phẩm Vitamin cao nhất, nhưng thường quên mua nhắc lại sau khoảng 30-45 ngày. Đây là cơ hội lớn nhất để tác động."
   o 🎯 Gợi ý Phân khúc Tối ưu: "Hãy nhắm vào tệp khách hàng đã mua các sản phẩm Vitamin trẻ em trong khoảng 45-60 ngày qua nhưng chưa quay lại. (Ước tính có 85 khách hàng phù hợp)."
   o ** actionable Gợi ý Kênh & Nội dung:** "Kênh Zalo ZNS có tỷ lệ mở cao nhất với nhóm này. Gợi ý nội dung: 'Chào {TenPhuHuynh}, đã đến lúc bổ sung Vitamin cho bé {TenBe} rồi ạ! Nam Việt gửi tặng voucher giảm 10% cho đơn hàng tiếp theo, mã BEKHOE10. Chúc bé luôn khỏe mạnh!'"
   Giá trị mang lại:
   • Định hướng: Nhân viên marketing không còn phải "đoán" nên nhắm vào ai. AI đã chỉ ra cho họ "mỏ vàng" tiềm năng nhất.
   • Tăng hiệu quả: Các gợi ý về phân khúc, kênh và nội dung giúp tăng tỷ lệ thành công của chiến dịch một cách đáng kể.
   • Sáng tạo dựa trên dữ liệu: AI cung cấp nền tảng dữ liệu vững chắc để đội ngũ marketing có thể sáng tạo các chương trình hiệu quả hơn.
   5.6.3 Nút "Trình tạo Phân khúc Khách hàng"
   Mục đích: Đây là công cụ chuyên biệt, mạnh mẽ, cho phép đội ngũ marketing của người dùng tự tay "điêu khắc" nên những tệp khách hàng mục tiêu chính xác đến từng chi tiết. Họ có thể tạo và lưu lại các phân khúc này để tái sử dụng cho nhiều chiến dịch.
   Truy cập: Quản lý Marketing -> Công cụ Marketing -> Trình tạo Phân khúc KH
   A. Bố cục 2 phần:
   • Bên trái: Danh sách các phân khúc đã lưu (ví dụ: "KH VIP chưa mua sắm 60 ngày", "Phụ huynh có con 2-6 tuổi ở Hữu Lũng"...).
   • Bên phải: Giao diện chính để tạo hoặc chỉnh sửa một phân khúc.
   B. Giao diện "Trình tạo Phân khúc" Chi tiết:
4. Tên Phân khúc: [Khách hàng tiềm năng cho Gói khám SK Tổng quát]
5. Mô tả: (Tùy chọn)
6. Bộ Xây dựng Quy tắc (Rule Builder): Đây là trái tim của công cụ.
   BAO GỒM KHÁCH HÀNG THỎA MÃN TẤT CẢ CÁC ĐIỀU KIỆN SAU:

---

( Lần mua cuối cùng cách đây hơn 180 ngày )
VÀ
( Xếp loại là VIP )
VÀ
( Sản phẩm đã mua không chứa Gói Khám Sức khỏe )

---

[+ Thêm điều kiện] [+ Thêm nhóm điều kiện (HOẶC)]
o Luồng tương tác: Người dùng có thể dễ dàng thêm các điều kiện. Mỗi điều kiện gồm 3 phần: Thuộc tính (Dropdown chọn từ hàng trăm thuộc tính có sẵn như Tuổi, Địa chỉ, Sản phẩm đã mua...), Toán tử (bằng, lớn hơn, chứa...), và Giá trị. 4. Kết quả Ước tính "Sống":
o Ở cuối giao diện, sẽ có một con số được cập nhật theo thời gian thực mỗi khi người dùng thêm/bớt một quy tắc:
Ước tính có: 125 khách hàng phù hợp. 5. Nút hành động:
o [Lưu Phân khúc]: Lưu lại tệp khách hàng này để sử dụng sau.
o [Sử dụng để Tạo Chiến dịch Mới]: Lưu và chuyển thẳng đến giao diện tạo chiến dịch, với phân khúc này đã được chọn sẵn.
5.6.4 Nút “Thư viện Nội dung & Mẫu”
Giao diện "Thư viện Nội dung & Mẫu" - Đảm bảo Sự Nhất quán
Mục đích: Tiết kiệm thời gian và đảm bảo thông điệp marketing của người dùng luôn nhất quán, chuyên nghiệp trên mọi kênh. Thay vì mỗi nhân viên phải tự soạn tin nhắn mỗi lần, họ sẽ sử dụng các mẫu đã được phê duyệt.
Truy cập: Quản lý Marketing -> Công cụ Marketing -> Thư viện Nội dung & Mẫu
Giao diện Chính:
• Một danh sách các mẫu tin nhắn đã được tạo, có thể lọc theo Kênh (Zalo, SMS, Email) hoặc Mục đích (Chào mừng khách hàng mới, Nhắc lịch hẹn, Giới thiệu sản phẩm...).
• Nút hành động chính: [+ Tạo Mẫu Mới]
Giao diện "Tạo Mẫu Tin nhắn Mới":
• Tên Mẫu: (Để quản lý nội bộ) Ví dụ: "Zalo - Nhắc lịch tiêm chủng mũi 2"
• Kênh: [Dropdown: Zalo ZNS, SMS, Email]
• Nội dung: Một trình soạn thảo trực quan.
• Công cụ "Biến" Cá nhân hóa: Bên cạnh trình soạn thảo, sẽ có một danh sách các "biến" (tags) mà người dùng có thể nhấp để chèn vào nội dung, giúp tin nhắn được cá nhân hóa tự động.
o Ví dụ: Người dùng soạn:
"Thân chào {TenKhachHang}, Nam Việt xin nhắc người dùng lịch tiêm chủng {TenMuiTiem} của {TenGoiDichVu} sắp tới vào khoảng ngày {NgayTiemDuKien}."
• Tích hợp vào Luồng tạo Chiến dịch: Khi nhân viên tạo một chiến dịch mới ở Bước 3 (Thiết kế Nội dung), thay vì phải gõ lại từ đầu, họ sẽ có một nút [Chọn từ Thư viện] để tải ngay các mẫu tin nhắn đã được chuẩn bị sẵn.
5.6.5 Nút “"Quản lý Mã Giảm giá & QR Code"
Giao diện "Quản lý Mã Giảm giá & QR Code" - Tối ưu cho Truyền thông
Mục đích: Trung tâm quản lý tất cả các mã ưu đãi và cung cấp công cụ tiện lợi cho việc thiết kế ấn phẩm truyền thông.
Truy cập: Quản lý Marketing -> Công cụ Marketing -> Quản lý Mã Giảm giá
Giao diện:
• Một bảng danh sách tất cả các mã giảm giá đã được tạo ra từ các chiến dịch.
• Các cột: Mã Code (ví dụ: BEKHOE25), Tên Chiến dịch, Giá trị Ưu đãi, Số lần đã sử dụng, Trạng thái.
• Tính năng mới theo yêu cầu của người dùng: Trong cột "Hành động", bên cạnh mỗi mã code, sẽ có một nút mới: [📷 Tạo mã QR].
o Luồng hoạt động:

1. Nhân viên marketing nhấn vào nút [📷 Tạo mã QR].
2. Một cửa sổ pop-up sẽ hiện ra, hiển thị hình ảnh mã QR đã được tạo ra cho mã giảm giá đó.
3. Các nút hành động đi kèm: [Tải xuống PNG] và [Sao chép Ảnh].
   • Giá trị: Cực kỳ tiện lợi cho nhân viên marketing khi thiết kế các ấn phẩm truyền thông như poster, tờ rơi, hoặc các bài đăng online. Khách hàng chỉ cần quét mã là có thể lưu lại ưu đãi.

5.6.5 Nút “Quản lý Chatbot AI"
Phần 1: Xây dựng Chatbot AI Thông minh với Công nghệ RAG và "Bàn giao có Chủ đích"
A. Tích hợp Công nghệ RAG - Biến Chatbot thành "Chuyên gia về Nam Việt"
Người dùng nói đúng, chúng ta sẽ không xây dựng một chatbot thông thường. Chúng ta sẽ sử dụng công nghệ RAG (Retrieval-Augmented Generation) để tạo ra một trợ lý ảo thực sự thông minh.
• Phiên dịch công nghệ (RAG hoạt động như thế nào?):
o Chatbot thông thường giống như một học sinh đi thi "thuộc lòng". Nó chỉ biết những gì đã được dạy trước đó, kiến thức bị giới hạn và có thể lỗi thời.
o Chatbot RAG của chúng ta giống như một học sinh thông minh đi thi "được mang tài liệu".
 "Cuốn tài liệu" (Retrieval): Chính là toàn bộ cơ sở dữ liệu của Nam Việt ERP: danh mục hàng ngàn sản phẩm, chi tiết các gói dịch vụ, các bài viết chuyên môn trên blog, thông tin khuyến mại đang hiệu lực...
 "Học sinh thông minh" (Generation): Là bộ não của AI Gemini.
o Quy trình: Khi một khách hàng hỏi: "Gói tiêm HPV của bên mình có mấy loại, giá bao nhiêu và có cần lưu ý gì không?", hệ thống sẽ:

1. Tìm kiếm trong "cuốn tài liệu" (CSDL Nam Việt) và lấy ra tất cả thông tin liên quan đến Gói HPV.
2. Đưa những thông tin này cho "học sinh thông minh" (Gemini) và ra lệnh: "Dựa vào những thông tin chính xác này, hãy soạn một câu trả lời tự nhiên và đầy đủ cho khách hàng."
   • Kết quả: Chatbot sẽ trả lời một cách cực kỳ chính xác, tự nhiên, và luôn cập nhật, bởi vì nó đang trả lời dựa trên chính dữ liệu "sống" của người dùng.
   B. "Bàn giao có Chủ đích" - Nâng tầm Trải nghiệm Khách hàng
   Đây là một ý tưởng cực kỳ xuất sắc của người dùng. Khi Chatbot không trả lời được, chúng ta sẽ không đưa ra một câu trả lời chung chung. Thay vào đó, chúng ta sẽ thực hiện một quy trình "Bàn giao thông minh và có chủ đích".
   • Luồng hoạt động:
3. Khi Bot không thể trả lời một câu hỏi chuyên môn sâu, hoặc khi khách hàng yêu cầu, nó sẽ nói:
   "Dạ, câu hỏi này của anh/chị mang tính chuyên môn sâu. Để được tư vấn chính xác nhất, anh/chị vui lòng chọn bộ phận/chuyên gia mà anh/chị muốn được kết nối, chúng tôi sẽ yêu cầu họ liên hệ lại ngay:"
4. Ngay sau đó, Bot sẽ hiển thị các nút bấm lựa chọn, được cá nhân hóa dựa trên ngữ cảnh cuộc trò chuyện:
    [ 👩‍⚕️ Tư vấn với Bác sĩ ]
    [ 💉 Hỏi về Lịch tiêm chủng ]
    [ 💊 Tư vấn Dược sĩ về Thuốc ]
    [ 💰 Hỏi về Hóa đơn/Thanh toán ]
5. Khi khách hàng nhấn vào một nút (ví dụ: [ 💊 Tư vấn Dược sĩ về Thuốc ]), hệ thống Nam Việt ERP sẽ:
    Tự động tạo một nhiệm vụ (task) mới với độ ưu tiên cao.
    Gán nhiệm vụ đó cho đúng nhóm người dùng (ví dụ: nhóm Dược sĩ nhà thuốc).
    Đính kèm toàn bộ lịch sử cuộc trò chuyện để Dược sĩ có thể nắm bắt bối cảnh ngay lập tức trước khi liên hệ lại.
   • Giá trị mang lại:
6. Trải nghiệm Vượt trội: Khách hàng cảm thấy được trân trọng và được kết nối đến đúng chuyên gia họ cần.
7. Hiệu quả cho Đội ngũ: Nhiệm vụ được phân tuyến chính xác, giảm thời gian chuyển tiếp thông tin giữa các bộ phận.
   Phần 2: "Cầu Nối Dữ Liệu Thời Gian Thực" - Lắng nghe Mạng xã hội
   Vấn đề: Hiện tại, để xem hiệu quả của một bài đăng trên Facebook, nhân viên của người dùng phải đăng nhập vào Facebook Business. Để xem hiệu quả kinh doanh của chiến dịch đó, họ lại phải xem báo cáo trong Nam Việt ERP. Thông tin bị phân mảnh và có độ trễ.
   Giải pháp của chúng ta: Chúng ta sẽ xây dựng một "Cầu Nối Dữ Liệu" thông qua "Cổng Tích hợp" mà chúng ta đã thiết kế. Cầu nối này sẽ chủ động "lắng nghe" các tín hiệu từ Zalo, Facebook và kéo dữ liệu về hệ thống gần như theo thời gian thực.
   A. "Cơ chế Lắng nghe" Thông minh
   • Phiên dịch công nghệ: "Cổng Tích hợp" của chúng ta sẽ sử dụng 2 phương pháp chính để nói chuyện với Facebook và Zalo:
8. Webhooks ("Đường dây nóng"): Với các sự kiện quan trọng (như có bình luận mới, tin nhắn mới), chúng ta sẽ cung cấp cho Facebook/Zalo một "số điện thoại đường dây nóng". Ngay khi sự kiện xảy ra, máy chủ của họ sẽ ngay lập tức "gọi" cho hệ thống của chúng ta để thông báo.
9. API Polling ("Kiểm tra định kỳ"): Với các chỉ số tổng hợp (như Lượt tiếp cận - Reach), hệ thống của chúng ta sẽ hành động như một người quản lý mẫn cán, tự động "gọi" cho máy chủ Facebook/Zalo theo chu kỳ (ví dụ: mỗi giờ một lần) để hỏi: "Báo cáo cho tôi các chỉ số mới nhất của bài viết X."
   • Kết quả: Sự kết hợp này tạo ra một dòng chảy dữ liệu gần như tức thì, giúp người dùng có được thông tin mới nhất ngay trong Nam Việt ERP.
   B. Tích hợp vào Giao diện "Theo dõi và Đo lường Hiệu quả"
   Dữ liệu được kéo về sẽ không nằm riêng lẻ. Nó sẽ được tích hợp thẳng vào giao diện báo cáo chiến dịch để tạo ra một bức tranh toàn cảnh từ A đến Z.
   Bối cảnh: Nhân viên marketing mở báo cáo chi tiết của chiến dịch "Mùa Tựu Trường".
   Giao diện "Phân Tích Chi Tiết Theo Kênh" (Phiên bản Nâng cấp):
   Phân tích Hiệu quả Kênh: FACEBOOK
   Bài viết: "5 Nhóm chất cần thiết giúp bé tăng đề kháng..." (Cập nhật 5 phút trước)

---

Hiệu quả Tương tác (Dữ liệu từ Facebook API):
• Số người Tiếp cận (Reach): 15,230
• Lượt Tương tác (Engagement): 1,280 (Thích, Chia sẻ, Bình luận)
• Lượt Nhấp vào Link (Clicks): 350
• Tỷ lệ Nhấp (CTR): 2.3%

---

Kết quả Kinh doanh (Dữ liệu từ Nam Việt ERP):
• Số Chuyển đổi (Từ Mã giảm giá): 75
• Doanh thu Trực tiếp: 63,750,000 VNĐ
• Chi phí / 1 Chuyển đổi: 202,667 VNĐ
Giá trị mang lại:

1. Báo cáo Toàn phễu (Full-Funnel Reporting): Lần đầu tiên, nhân viên của người dùng có thể thấy toàn bộ hành trình của khách hàng trên cùng một màn hình: từ lúc họ thấy bài viết trên Facebook, nhấp vào link, cho đến khi họ thực sự đến cửa hàng và mua hàng.
2. Khả năng Tối ưu hóa Nhanh: Nếu sau 3 giờ chạy quảng cáo mà chỉ số CTR (Tỷ lệ Nhấp) quá thấp, họ có thể phát hiện ra ngay trong ERP và nhanh chóng điều chỉnh lại nội dung hoặc hình ảnh của bài quảng cáo trên Facebook mà không cần chờ đến cuối ngày.
3. Đo lường ROI Chính xác: Hệ thống có đủ cả hai vế của bài toán: Chi phí & Hiệu quả Tương tác (từ Facebook) và Doanh thu & Lợi nhuận (từ ERP), từ đó tính ra con số ROI chính xác nhất cho từng bài đăng, từng chiến dịch.

Tổng kết
Với Chatbot AI thông minh (RAG) và Cầu Nối Dữ Liệu Thời Gian Thực, chúng ta đã hoàn thiện và nâng cấp module "Quản lý Marketing" lên một tầm cao mới. Nó không chỉ là nơi để lên kế hoạch, mà đã trở thành một trung tâm điều hành và tối ưu hóa tăng trưởng theo thời gian thực.

5.7 Quản lý Nhân Sự và Đào Tạo
5.7.1: Nền tảng Quản lý Nhân sự (HRM)
Đây là phần "xương sống" của module, nơi chúng ta quản lý toàn bộ thông tin và vòng đời của một nhân viên tại công ty.
A. Cấu trúc Menu & Giao diện
Khi người dùng (có quyền) nhấn vào nút cha Quản lý Nhân sự trên thanh menu, một menu dropdown sẽ hiện ra:
• Quản lý Nhân sự
o Dashboard Nhân sự
o Quản lý Hồ sơ Nhân viên
o Quản lý Hợp đồng & Giấy tờ
o Quản lý Đào tạo
o Giao việc & KPIs
o Quản lý Lương & Chế độ

---

5.7.2 Giao diện "Dashboard Nhân sự"
Đây là màn hình tổng quan dành cho Ban Giám đốc và phòng Nhân sự, cung cấp một cái nhìn nhanh về tình hình nhân sự toàn công ty.
• Các KPI Chính (Dạng Thẻ điểm):
o Tổng số Nhân viên: 150 (📈 Tăng 5 so với tháng trước)
o Nhân viên Mới (Tháng này): 8
o Nhân viên Thôi việc (Tháng này): 3
o Tỷ lệ Thôi việc: 2.0%
• Các Widget Cảnh báo & Thông tin Nhanh:
o Sắp đến hạn Hợp đồng: Một danh sách các nhân viên sắp hết hạn hợp đồng lao động trong 30 ngày tới, giúp HR chủ động trong việc tái ký.
o Sinh nhật trong tháng: Giúp xây dựng văn hóa quan tâm đến nhân viên.
o Nhân viên Mới: Chào mừng các thành viên mới vừa gia nhập công ty trong tuần.

---

5.7.3. Giao diện "Quản lý Hồ sơ Nhân viên"
Đây là "trái tim" của phân hệ Nhân sự, là "Nguồn Chân Lý Duy Nhất" về thông tin của tất cả nhân viên.

1. Giao diện Danh sách:
   • Công cụ: Có đầy đủ các công cụ Bộ lọc (theo Chi nhánh, Vai trò, Trạng thái), Tìm kiếm, và hai nút quan trọng [+ Thêm Nhân viên Mới] và [Nhập/Xuất Excel].
   • Bảng Danh sách:
   Mã NV Họ Tên Ảnh Chi nhánh Vai trò SĐT Trạng thái Hành động
   NV001 Nguyễn Văn An (Ảnh) Kho Tổng B2B Quản lý Kho 090... ✅ Đang làm việc [Xem] [Sửa]
   NV002 Trần Thị Lan (Ảnh) Nhà thuốc ĐH 1 Dược sĩ 091... ✅ Đang làm việc [Xem] [Sửa]
   NV003 Lê Văn Bình (Ảnh) (N/A) Bác sĩ 093... 🔴 Đã thôi việc [Xem]

2. Giao diện Chi tiết Hồ sơ Nhân viên (Khi nhấn [Xem] hoặc [Sửa]):
   Đây là một hồ sơ 360 độ về nhân viên, được chia thành các Tab khoa học.
   • Tab 1: Thông tin Cá nhân
   o Các trường thông tin cơ bản: Họ tên, Ngày sinh, Giới tính, Số CCCD, Địa chỉ thường trú, Thông tin liên hệ khẩn cấp...
   • Tab 2: Thông tin Công việc & Phân quyền
   o Chi nhánh làm việc*: [Dropdown chọn chi nhánh]
   o Vai trò*: [Dropdown chọn vai trò trong hệ thống, ví dụ: "Dược sĩ"]. Đây chính là nơi chúng ta gán quyền truy cập hệ thống cho nhân viên.
   o Ngày vào làm, Quản lý trực tiếp, Thông tin tài khoản ngân hàng...
   • Tab 3: Quản lý Hợp đồng & Giấy tờ
   o Một khu vực cho phép tải lên và lưu trữ tất cả các giấy tờ pháp lý liên quan đến nhân viên:
    Hợp đồng thử việc (File PDF)
    Hợp đồng lao động chính thức (File PDF)
    Sơ yếu lý lịch, Bằng cấp, Chứng chỉ...
   o Hệ thống sẽ tự động nhắc nhở khi hợp đồng sắp hết hạn dựa trên thông tin ở đây.
   • Tab 4: Lộ trình Đào tạo & Hiệu suất
   o Lịch sử Đào tạo: Liệt kê tất cả các khóa học, bài test mà nhân viên này đã tham gia và kết quả của họ.
   o Đánh giá KPI: Hiển thị kết quả đánh giá hiệu suất công việc theo từng kỳ.
   5.7.5 Nút “Quản lý Đào Tạo” và nút “Giao Việc & KPI”
   Phần 2: "Động cơ" Phát triển Năng lực & Quản lý Hiệu suất
   A. "Quản lý Đào tạo" - Xây dựng Học viện Nội bộ Kỹ thuật số
   Mục đích: Xây dựng một trung tâm đào tạo nội bộ, nơi mọi tài liệu, bài giảng, bài kiểm tra được lưu trữ một cách khoa học và có thể được gán cho nhân viên theo một lộ trình rõ ràng.
   Truy cập: Quản lý Nhân sự -> Quản lý Đào tạo
   Giao diện này sẽ gồm 2 công cụ chính:
3. Công cụ "Thư viện Khóa học" (Kho các bài học)
   • Giao diện: Một danh sách hoặc lưới hiển thị toàn bộ các tài liệu đào tạo của công ty.
   • Công cụ:
   o Bộ lọc: Lọc theo Loại nội dung (Bài viết, Video, Bài test), Chuyên môn (Dược lâm sàng, Kỹ năng Bán hàng, Quy trình Vận hành...).
   o Nút hành động: [+ Thêm Tài liệu/Bài học Mới]
   • Khi thêm bài học mới:
   o Tiêu đề bài học
   o Loại nội dung: [Dropdown: Bài viết/Tài liệu PDF, Link Video, Tạo Bài Test]
   o Trình tạo Bài Test: Nếu chọn "Tạo Bài Test", một công cụ sẽ hiện ra cho phép người dùng tạo các câu hỏi trắc nghiệm, tự luận, và cài đặt điểm đạt.
4. Công cụ "Quản lý Lộ trình Đào tạo" (Learning Paths)
   • Đây chính là nơi thực thi ý tưởng của người dùng. Nó cho phép người dùng gom nhóm các bài học từ thư viện thành một chương trình đào tạo hoàn chỉnh.
   • Giao diện: Một danh sách các lộ trình đã tạo (ví dụ: "Hội nhập cho Dược sĩ Mới", "Nâng cao Kỹ năng Tư vấn cho Dược sĩ Cấp 2"...).
   • Nút hành động: [+ Tạo Lộ trình Mới]
   • Khi tạo Lộ trình mới:
   o Tên Lộ trình: Ví dụ: "Hội nhập cho Nhân viên Thử việc"
   o Áp dụng cho: Đây là phần thông minh nhất. Một ô cho phép người dùng chọn các điều kiện để hệ thống tự động gán lộ trình này.
    Vai trò LÀ Dược sĩ VÀ Trạng thái LÀ Thử việc
    Vai trò LÀ Nhân viên Kinh doanh B2B VÀ Cấp bậc LÀ Cấp 1
   o Trình xây dựng Lộ trình: Một giao diện kéo-thả, cho phép người dùng chọn các bài học từ "Thư viện Khóa học" và sắp xếp chúng thành một chương trình học có thứ tự.
   • Sự Tự động hóa Thông minh:
   o Ví dụ: Khi phòng nhân sự tạo một hồ sơ nhân viên mới tên "Nguyễn Thị Mai" với vai trò "Dược sĩ" và trạng thái "Thử việc", hệ thống sẽ tự động gán cho cô Mai "Lộ trình Hội nhập cho Nhân viên Thử việc".
   o Ngay lập tức, trên Dashboard của cô Mai, widget "Góc Đào tạo" sẽ xuất hiện các nhiệm vụ đầu tiên, ví dụ: [ĐỌC NGAY] Nội quy Công ty, [XEM VIDEO] Giới thiệu Văn hóa Nam Việt.

---

B. "Giao việc & KPIs" - Công cụ Quản lý Hiệu suất
Mục đích: Cung cấp một công cụ đơn giản, minh bạch để giao các công việc hàng ngày và theo dõi hiệu suất dựa trên các chỉ tiêu đã đặt ra.
Truy cập: Quản lý Nhân sự -> Giao việc & KPIs

1. Giao diện Giao việc:
   • Giao diện: Có thể hiển thị dạng bảng Kanban (các cột: Mới, Đang làm, Chờ duyệt, Hoàn thành) hoặc dạng danh sách.
   • Bộ lọc: Lọc theo Dự án, Người thực hiện, Trạng thái, Mức độ Ưu tiên.
   • Nút hành động: [+ Giao việc Mới]
   • Khi giao việc mới:
   o Tên công việc: (Ví dụ: "Kiểm kê nhóm hàng Kháng sinh tại Nhà thuốc ĐH 1")
   o Mô tả chi tiết: (Nội dung công việc)
   o Người thực hiện: [Chọn nhân viên]
   o Người giám sát/duyệt: [Chọn quản lý]
   o Ngày hết hạn
2. Tích hợp Theo dõi KPIs:
   • Công cụ này sẽ kết nối trực tiếp với Giao diện "Thiết lập Mục tiêu KPI" mà chúng ta đã thiết kế trong module Báo Cáo.
   • Trong Giao diện Chi tiết Hồ sơ Nhân viên, Tab "Lộ trình Đào tạo & Hiệu suất" sẽ được hoàn thiện. Nó sẽ hiển thị:
   o Danh sách các công việc đã được giao, trạng thái và kết quả.
   o Bảng theo dõi KPIs cá nhân, lấy dữ liệu "sống" từ module Báo Cáo để cho thấy tiến độ hoàn thành mục tiêu của nhân viên đó (ví dụ: Doanh số Tháng: 450tr / 500tr (Đạt 90%)).
   5.7.5 Nút “Quản lý Lương & Chế độ”
   A. Giai đoạn 1: "Dạy" cho Hệ thống các "Luật chơi"
   Trước khi có thể tính lương, hệ thống cần được "dạy" về các chính sách của công ty. Chúng ta sẽ có một giao diện cài đặt:
   Giao diện "Thiết lập Chính sách Lương":
   • Tab 1: Cấu trúc Lương & Phụ cấp:
   o Cho phép người dùng tạo các "ngạch" lương khác nhau (ví dụ: Ngạch Dược sĩ, Ngạch Kinh doanh).
   o Trong mỗi ngạch, người dùng có thể định nghĩa:
    Lương Cơ bản: theo cấp bậc.
    Các khoản Phụ cấp cố định: (Phụ cấp ăn trưa, đi lại...).
   • Tab 2: Cấu hình Hoa hồng & KPIs:
   o Đây là phần kết nối thông minh. Người dùng có thể tạo các quy tắc, ví dụ:
    Đối với Vai trò "NVKD B2B": Hoa hồng = 2% của Chỉ số "Doanh thu Thực tế" (lấy từ module Báo Cáo).
    Đối với Vai trò "Dược sĩ": Thưởng = 500.000đ nếu Chỉ số "Tỷ lệ Hoàn thành Đào tạo" đạt 100%.
   • Tab 3: Chính sách Thâm niên:
   o Cho phép người dùng cài đặt các quy tắc, ví dụ: "Cứ mỗi 12 tháng làm việc, Lương cơ bản tự động tăng 5%".
   B. Giai đoạn 2: "Cỗ máy" Tự động Chạy Bảng lương
   Vào một ngày được cài đặt trước mỗi tháng, hệ thống sẽ tự động chạy một quy trình phức tạp.
   • "Cỗ máy" sẽ tự động "hút" dữ liệu từ khắp nơi trong hệ thống:
3. Từ Hồ sơ Nhân viên: Lấy Lương Cơ bản, Phụ cấp, Ngày vào làm...
4. Từ Module Báo Cáo: Lấy % thực hiện KPIs doanh số.
5. Từ Module Giao việc & Đào tạo: Lấy số công việc hoàn thành, kết quả đào tạo...
6. Từ Bảng chấm công: Lấy Số ngày công thực tế.
   • Tính toán & Tạo Bảng lương Nháp: Hệ thống sẽ tự động tính toán và tạo ra một Bảng lương ở trạng thái "Chờ duyệt".
   C. Giai đoạn 3: Con người "Xác thực" và Gửi đi
   • Giao diện "Đối soát & Phê duyệt Bảng lương":
   o Kế toán và HR sẽ vào xem bảng lương đã được hệ thống tính toán sẵn.
   o Giao diện cho phép họ thực hiện các điều chỉnh cuối cùng (ví dụ: nhập các khoản thưởng/phạt đột xuất).
   o Sau khi rà soát, họ sẽ gửi cho Ban Giám đốc phê duyệt lần cuối.
   • Hành động Cuối cùng:
   o Khi Bảng lương được phê duyệt, nút [Gửi Phiếu lương & Hoàn tất] sẽ được kích hoạt.
   o Khi nhấn, hệ thống sẽ tự động gửi email/tin nhắn Zalo đến từng nhân viên, đính kèm một phiếu lương chi tiết, minh bạch.

5.8 Module “Tài chính & Kế Toán”
5.8.1 Cấu trúc Module và Giao diện Quản lý Thu – Chi
Phần 1: Cấu trúc Module và Giao diện Quản lý Thu - Chi
A. Cấu trúc Menu Cha: Tài Chính & Kế Toán
Khi người dùng (có quyền) nhấn vào nút cha Tài Chính & Kế Toán trên thanh menu, một menu dropdown sẽ hiện ra, được tổ chức một cách khoa học:
• Tài Chính & Kế Toán
o Dashboard Tài chính (Tổng quan nhanh về dòng tiền, công nợ)
o Quản lý Thu - Chi (Nơi quản lý các phiếu thu, chi, tạm ứng...)
o Quản lý Công nợ (Đối soát công nợ phải thu & phải trả)
o Quản lý Tài sản
o Đối soát Giao Dịch
o Nghiệp vụ Kế toán (Các chức năng chuyên sâu & tích hợp MISA)
o Quản lý Hóa Đơn VAT

---

B. Giao diện "Quản lý Thu - Chi" - Trung tâm Giao dịch Hàng ngày
Đây là giao diện làm việc chính của bộ phận kế toán, nơi tất cả các giao dịch tiền tệ hàng ngày được ghi nhận và quản lý.
Truy cập: Tài Chính & Kế Toán -> Quản lý Thu - Chi

1. Bố cục Tổng quan:
   • Các nút hành động nhanh: Nằm ở trên cùng, cho phép tạo nhanh các loại phiếu:
   o [+ Tạo Phiếu Thu]
   o [+ Tạo Phiếu Chi]
   o [+ Tạo Phiếu Tạm ứng]
   o [+ Tạo Phiếu Hoàn ứng]
   • Công cụ Lọc & Tìm kiếm:
   o Lọc theo Loại phiếu, Người tạo, Ngày tạo, Trạng thái (Đã duyệt, Chờ duyệt...).
   o [Xuất ra Excel] để phục vụ đối soát.
2. Bảng Danh sách các Giao dịch:
   Bảng này sẽ liệt kê tất cả các loại phiếu, được phân biệt bằng màu sắc hoặc icon để dễ nhận diện.
   Mã Phiếu Loại Phiếu Ngày tạo Người tạo Diễn giải Tổng Tiền Trạng thái Hành động
   PC-00567 Phiếu Chi 30/08/25 Kế toán A Chi tiền mua văn phòng phẩm -500.000đ ✅ Đã duyệt [Xem] [In]
   PT-00891 Phiếu Thu 30/08/25 Kế toán B Thu tiền mặt từ đơn hàng POS +15.200.000đ ✅ Đã duyệt [Xem] [In]
   TU-00123 Tạm ứng 29/08/25 NVKD A Tạm ứng chi phí công tác -5.000.000đ ✅ Đã duyệt [Xem] [In]
   HU-00111 Hoàn ứng 28/08/25 NVKD B Hoàn ứng chi phí đi lại +500.000đ 🟡 Chờ duyệt [Xem] [Sửa]

C. Luồng Công việc Chi tiết: "Tạo Phiếu Chi"
Để người dùng dễ hình dung, chúng ta sẽ đi sâu vào luồng tạo mới một giao dịch phổ biến nhất.
Bối cảnh: Kế toán/Nhân sự cần tạo một phiếu chi để thanh toán tiền điện cho văn phòng.
Bước 1: Khởi tạo
• Kế toán viên nhấn vào nút [+ Tạo Phiếu Chi].
Bước 2: Giao diện "Tạo Mới Phiếu Chi"
Một giao diện chi tiết sẽ hiện ra, yêu cầu điền các thông tin cần thiết một cách có cấu trúc.
• Thông tin Người nhận tiền:
o Tên Người/Đơn vị nhận: [ Công ty Điện lực Lạng Sơn ]
o Địa chỉ, Mã số thuế...
• Thông tin Chi:
o Lý do chi*: [ Thanh toán tiền điện tháng 8/2025 ]
o Số tiền chi*: [ 3,500,000 ] VNĐ
o Hình thức*: [Dropdown: Tiền mặt, Chuyển khoản]
o Tài khoản/Quỹ chi*: [Dropdown chọn tài khoản ngân hàng hoặc quỹ tiền mặt của công ty]
• Chứng từ kèm theo:
o Một khu vực cho phép tải lên file hóa đơn, ảnh chụp chứng từ... để làm bằng chứng.
• Hạch toán (Dành cho Kế toán):
o Một khu vực để kế toán viên chọn các tài khoản Nợ/Có tương ứng cho nghiệp vụ này.
• Nút bấm Hành động:
o [Lưu Nháp]
o [Gửi Duyệt]: Gửi yêu cầu chi cho cấp quản lý phê duyệt.
Bước 3: Quy trình Phê duyệt & Hoàn tất
• Sau khi kế toán gửi duyệt, phiếu chi sẽ ở trạng thái "🟡 Chờ duyệt".
• Người quản lý/Kế toán có thẩm quyền sẽ nhận được thông báo, họ có thể vào xem chi tiết phiếu chi và nhấn [Phê duyệt] hoặc [Từ chối].
• Chỉ sau khi Phiếu Thu/Chi được cả Quản lý và Kế toán phê duyệt, Nút “Xác nhận thực Chi/Thu” sẽ xuất hiện và Thủ quỹ sẽ xuất tiền ra khỏi hệ thống, phiếu chi mới chính thức được ghi nhận vào sổ sách, và hệ thống sẽ tự động trừ tiền trong "Sổ quỹ" tương ứng.
Luồng công việc này đảm bảo mọi khoản chi của công ty đều được ghi nhận đầy đủ, có chứng từ rõ ràng và được kiểm soát chặt chẽ qua một quy trình phê duyệt minh bạch.
5.8.2 Nút “Quản lý Công Nợ”
Giao diện "Quản lý Công nợ" - Kiểm soát Dòng tiền Tương lai
Mục đích: Cung cấp một nơi duy nhất, tập trung để theo dõi, đối soát và quản lý tất cả các khoản phải thu từ khách hàng và các khoản phải trả cho nhà cung cấp. Giao diện này sẽ giúp người dùng làm chủ dòng tiền và lên kế hoạch tài chính một cách hiệu quả.
Truy cập: Tài Chính & Kế Toán -> Quản lý Công nợ
Giao diện sẽ được thiết kế với 2 Tab chính, tương ứng với hai chiều của dòng tiền:

---

Tab 1: Công nợ Phải thu (Accounts Receivable)
Đây là nơi chúng ta theo dõi số tiền mà khách hàng (chủ yếu là B2B) đang nợ chúng ta. Dữ liệu ở đây được tự động tạo ra từ các đơn hàng trong module "Bán Buôn".

1. Khu vực Tổng quan & KPIs:
   • Tổng Phải thu: 1.52 Tỷ VNĐ
   • Tổng nợ Quá hạn: 300 Triệu VNĐ 🔴 (Cảnh báo màu đỏ)
   • Tuổi nợ Trung bình: 25 ngày
2. Bảng Danh sách Công nợ Phải thu:
   Khách hàng Mã Hóa đơn Ngày HĐ Hạn Thanh toán Giá trị Đã thanh toán Còn lại Tình trạng Hành động
   Nhà thuốc An Khang DH00124 29/08/25 28/09/25 15.5tr 10tr 5.5tr Còn 29 ngày [Xem] [Ghi nhận TT] [Nhắc nợ]
   Bệnh viện XYZ DH00125 28/08/25 27/09/25 52tr 0đ 52tr Còn 28 ngày [Xem] [Ghi nhận TT] [Nhắc nợ]
   Nhà thuốc Minh Tâm DH00119 20/07/25 19/08/25 35tr 20tr 15tr Quá hạn 11 ngày 🔴 [Xem] [Ghi nhận TT] [Nhắc nợ]

• Cột "Tình trạng" thông minh: Hệ thống tự động tính toán và mã hóa màu sắc để nhân viên kế toán biết ngay khoản nợ nào cần ưu tiên xử lý. 3. Luồng công việc chính:
• [Ghi nhận Thanh toán]:
o Khi khách hàng thanh toán, kế toán viên nhấn nút này.
o Một cửa sổ pop-up hiện ra để nhập Số tiền thanh toán, Ngày, Hình thức.
o Khi xác nhận, hệ thống sẽ tự động cập nhật lại các cột "Đã thanh toán", "Còn lại" và tự động tạo một "Phiếu Thu" tương ứng trong module Quản lý Thu - Chi.
• [Gửi Nhắc nợ]:
o Cho các khoản nợ quá hạn, nút này cho phép gửi một email hoặc tin nhắn Zalo nhắc nợ tự động đến khách hàng theo mẫu đã được soạn sẵn.

---

Tab 2: Công nợ Phải trả (Accounts Payable)
Đây là nơi chúng ta theo dõi số tiền mà chúng ta nợ các Nhà Cung Cấp. Dữ liệu ở đây được tự động tạo ra từ các Phiếu Nhập Kho.

1. Khu vực Tổng quan & KPIs:
   • Tổng Phải trả: 850 Triệu VNĐ
   • Tổng nợ Sắp đến hạn (7 ngày tới): 150 Triệu VNĐ
2. Bảng Danh sách Công nợ Phải trả:
   Nhà Cung Cấp Mã Hóa đơn NCC Ngày HĐ Hạn Thanh toán Giá trị Đã thanh toán Còn lại Tình trạng Hành động
   Dược Hậu Giang HD-DHG-123 29/08/25 28/09/25 120tr 0đ 120tr Còn 29 ngày [Xem] [Lên lịch TT]
   Traphaco HD-TRP-456 20/08/25 19/09/25 75tr 75tr 0đ Đã thanh toán [Xem]

3. Luồng công việc chính:
   • [Lên lịch Thanh toán]:
   o Kế toán viên chọn một hoặc nhiều hóa đơn cần thanh toán cho một nhà cung cấp.
   o Khi nhấn nút này, hệ thống sẽ tự động tạo ra một "Phiếu Chi" trong module Quản lý Thu - Chi, với trạng thái "Chờ duyệt".
   o Toàn bộ thông tin nhà cung cấp, số tiền, diễn giải... sẽ được điền sẵn.
   • Sự kết nối thông minh: Luồng công việc này kết nối trực tiếp module Công nợ với module Thu-Chi, tạo ra một quy trình thanh toán nhà cung cấp liền mạch, có kiểm soát và giảm thiểu việc nhập liệu lặp lại.

---

Với trung tâm quản lý công nợ này, người dùng và đội ngũ kế toán đã có một công cụ mạnh mẽ để kiểm soát toàn bộ các dòng tiền sẽ đến và sẽ đi của doanh nghiệp, giúp chủ động hơn trong việc lên kế hoạch tài chính.
5.8.3 Nút “Sổ Quỹ”
Giao diện "Sổ Quỹ" - Theo dõi Mạch máu Doanh nghiệp
Quy trình của chúng ta sẽ gồm hai phần: đầu tiên là "khai báo" nơi cất tiền, sau đó là giao diện chính để theo dõi dòng tiền ra vào.
A. Nền tảng: Quản lý Tài khoản / Quỹ tiền
Trước khi theo dõi, hệ thống cần biết công ty người dùng có những "túi tiền" nào. Chúng ta sẽ có một giao diện cài đặt đơn giản.
• Truy cập: Tài Chính & Kế Toán -> Cài đặt -> Quản lý Tài khoản/Quỹ.
• Giao diện: Một danh sách tất cả các tài khoản/quỹ tiền của công ty.
o Nút bấm: [+ Thêm Tài khoản/Quỹ Mới]
o Danh sách:
Tên Tài khoản/Quỹ Loại Số tài khoản / Địa điểm Số dư Hiện tại
Quỹ tiền mặt Nhà thuốc ĐH 1 Tiền mặt Nhà thuốc ĐH 1 50.250.000đ
TK Vietcombank - CN Lạng Sơn Ngân hàng 123456789xxx 2.540.100.000đ

B. Giao diện "Sổ Quỹ" Chính
Đây là giao diện mà người dùng và bộ phận kế toán sẽ sử dụng hàng ngày để theo dõi chi tiết dòng tiền.
Truy cập: Tài Chính & Kế Toán -> Sổ Quỹ

1. Khu vực Tổng quan & KPIs (Phía trên):
   • Hiển thị các con số tổng hợp, thay đổi "sống" theo bộ lọc người dùng chọn.
   o Tổng Tồn Quỹ (Tất cả): 2.590.350.000 VNĐ
   o Tổng Thu trong kỳ: + 350.000.000 VNĐ
   o Tổng Chi trong kỳ: - 120.000.000 VNĐ
2. Khu vực Bộ lọc:
   • Khoảng thời gian: [Chọn ngày, tuần, tháng...]
   • Tài khoản/Quỹ: [Dropdown để xem sổ quỹ của riêng một tài khoản/quỹ cụ thể]
   • Loại Giao dịch: [Checkbox: Thu, Chi, Tạm ứng...]
3. Bảng Giao dịch Chi tiết (Sổ Cái): Đây là trái tim của giao diện, liệt kê chi tiết từng giao dịch tiền tệ đã thực sự diễn ra.
   Ngày Ghi sổ Mã Phiếu Diễn giải Thu Chi Tồn Quỹ Cuối Tài khoản/Quỹ Người xác nhận
   30/08/25 PT-00891 Thu tiền mặt từ đơn hàng POS +15.200.000đ 50.250.000đ Quỹ TM - ĐH 1 Kế toán B
   30/08/25 PC-00567 Chi tiền mua văn phòng phẩm -500.000đ 35.050.000đ Quỹ TM - ĐH 1 Kế toán A
   29/08/25 PC-00566 Thanh toán HĐ cho Dược Hậu Giang -120.000.000đ 2.540.100.000đ TK Vietcombank Kế toán B
   ... ... ... ... ... ... ... ...

• Cột Mã Phiếu: Sẽ là một đường link có thể nhấp vào. Khi nhấp, hệ thống sẽ mở ra chi tiết của Phiếu Thu hoặc Phiếu Chi gốc để đối soát.
• Cột Tồn Quỹ Cuối: Đây là cột quan trọng nhất, thể hiện số dư của quỹ/tài khoản sau mỗi giao dịch, giúp người dùng theo dõi dòng tiền một cách liên tục.

---

C. Quy tắc Vàng: Kết nối với Luồng Thu - Chi
Điều quan trọng nhất cần nhấn mạnh, cũng là sự cải tiến mà người dùng đã đề xuất:
Một dòng giao dịch chỉ xuất hiện trong Sổ Quỹ khi và chỉ khi một nhân viên có thẩm quyền đã nhấn nút [Xác nhận Đã Thu Tiền] hoặc [Xác nhận Đã Chi Tiền] trong module Quản lý Thu - Chi.
Thiết kế này đảm bảo Sổ Quỹ của người dùng phản ánh thực tế tiền đã ra hoặc vào, chứ không phải là những kế hoạch hay những yêu cầu đã được duyệt nhưng chưa được thực thi. Nó mang lại sự chính xác và tin cậy tuyệt đối cho con số tài chính quan trọng nhất của công ty.
5.8.4 Nút “Quản Lý Tài Sản”
Module "Quản lý Tài sản" - Số hóa và Bảo vệ Nguồn lực Công ty
Mục đích: Module này giúp người dùng số hóa, theo dõi và quản lý toàn bộ vòng đời của các tài sản vật chất trong công ty, từ một chiếc máy tính, máy in, cho đến các thiết bị y tế đắt tiền. Điều này không chỉ giúp quản lý việc sử dụng mà còn bảo vệ tài sản và cung cấp dữ liệu chính xác cho việc hạch toán khấu hao.
Truy cập: Tài Chính & Kế Toán -> Quản lý Tài sản
A. Giao diện "Danh mục Quản lý Tài sản"
Đây là giao diện trung tâm, cung cấp một cái nhìn tổng quan về toàn bộ tài sản của công ty.

1. Khu vực Tổng quan & KPIs: số liệu ví dụ:
   • Tổng số lượng Tài sản: 125
   • Tổng Nguyên giá: 5.2 Tỷ VNĐ
   • Tổng Giá trị còn lại: 3.8 Tỷ VNĐ
2. Công cụ Lọc & Tìm kiếm:
   • Lọc theo Loại Tài sản (Máy tính & IT, Thiết bị Y tế, Xe cộ, Nội thất...), Chi nhánh, Người sử dụng, Tình trạng (Đang sử dụng, Trong kho, Cần sửa chữa...).
   • Các nút [+ Thêm Tài sản Mới] và [Nhập/Xuất Excel].
3. Bảng Danh mục Tài sản:
   Mã TS Tên Tài sản Loại Chi nhánh Người sử dụng Ngày mua Nguyên giá Giá trị còn lại Tình trạng Hành động
   TS-001 Máy Siêu Âm X TBYT Phòng khám ĐH (Chung) 15/01/25 1.2 Tỷ 1.1 Tỷ Đang sử dụng [Xem] [Sửa]
   TS-002 Laptop Dell... Máy tính Văn phòng NVKD A 20/07/25 25 Triệu 24 Triệu Đang sử dụng [Xem] [Sửa]
   TS-003 Xe máy Honda Xe cộ (Chung) Giao vận B 10/02/24 22 Triệu 15 Triệu Cần sửa chữa [Xem] [Sửa]

---

B. Luồng Công việc Quản lý Vòng đời Tài sản

1. Giao diện "Thêm Tài sản Mới":
   Khi nhấn [+ Thêm Tài sản Mới], một giao diện chi tiết dạng Tab sẽ hiện ra.
   • Tab 1: Thông tin Chung
   o Mã Tài sản (Tự động tạo), Tên Tài sản, Loại Tài sản, Mô tả, Số Sê-ri...
   • Tab 2: Thông tin Tài chính & Khấu hao
   o Ngày mua, Nhà cung cấp, Nguyên giá (Giá trị ban đầu).
   o Phương pháp Khấu hao: [Dropdown: Đường thẳng].
   o Thời gian Khấu hao (tháng): Ví dụ [ 36 ].
   • Tab 3: Thông tin Sử dụng & Bàn giao
   o Chi nhánh quản lý, Người/Bộ phận được giao, Ngày bàn giao.
   • Tab 4: Lịch sử Bảo trì & Sửa chữa
   o Cho phép tạo và nhắc nhở các lịch bảo trì định kỳ.
   o Ghi lại nhật ký các lần sửa chữa, chi phí kèm theo. đặc biệt là mục Chi phí sửa chữa, hệ thống sẽ hiển thị một checkbox: [ ✅ ] Tự động tạo Phiếu Chi cho khoản này Tương tự như thế khi chúng ta Thanh lý tài sản, sẽ có 1 phiếu thu tương ứng.

2. Các Quy trình Tự động của Hệ thống:
   • Khấu hao Tự động: Vào cuối mỗi kỳ kế toán, hệ thống sẽ tự động chạy một quy trình để tính toán chi phí khấu hao cho tất cả các tài sản dựa trên phương pháp và thời gian đã cài đặt. Các bút toán khấu hao này sẽ được tự động tạo và chờ kế toán duyệt.
   • Nhắc lịch Bảo trì: Hệ thống sẽ tự động tạo nhiệm vụ hoặc gửi thông báo cho người phụ trách khi một tài sản sắp đến hạn bảo trì.
3. Quản lý Vòng đời:
   Thông qua các nút "Hành động" trên danh sách, người dùng có thể quản lý toàn bộ vòng đời của tài sản:
   • [Bàn giao]: Chuyển tài sản từ người này sang người khác, hệ thống sẽ lưu lại toàn bộ lịch sử.
   • [Ghi nhận Sửa chữa]: Cập nhật chi phí và lịch sử sửa chữa vào hồ sơ tài sản.
   • [Thanh lý Tài sản]: Khi một tài sản bị hỏng hoặc hết giá trị sử dụng, quy trình thanh lý sẽ loại bỏ tài sản ra khỏi sổ sách kế toán một cách chính xác.

---

Module này không chỉ giúp người dùng biết "công ty có những gì và ai đang giữ nó", mà còn tự động hóa các nghiệp vụ tài chính quan trọng như khấu hao và nhắc nhở bảo trì, giúp người dùng bảo vệ và tối ưu hóa việc sử dụng nguồn lực vật chất của công ty.
5.8.4 Nút “Đối soát Giao Dịch”
Đối với tiền mặt, quy trình này khi thiết kế giao diện "Danh sách Đơn hàng" của kênh cửa hàng. Tại đó, chúng ta đã có nút [Nộp tiền cho Kế toán]. Đây là hành động để nhân viên tại cửa hàng (Dược sĩ, Thu ngân) báo cáo rằng họ đã bàn giao một lượng tiền mặt vào cuối ca. Hành động này tạo ra một "phiếu bàn giao" trong hệ thống, ghi nhận rằng "Dược sĩ Lan đã nộp 50 triệu tiền mặt".
Đối với đối soát giao dịch với tài khoản Ngân hàng, chúng ta làm như sau:
• Truy cập: Tài Chính & Kế Toán -> Đối soát Giao dịch
• Bố cục 2 cột song song:
Cột Trái: GIAO DỊCH TỪ SAO KÊ (AI đọc) Cột Phải: GIAO DỊCH CHƯA ĐỐI SOÁT (Trong ERP)
[+ Tải lên Sao kê Ngân hàng] (Danh sách các khoản phải thu từ khách B2B, các phiếu bàn giao tiền mặt từ cửa hàng...)

---

🟢 Ngày 30/08: + 15,500,000 - ND: Nha thuoc An Khang TT 🟢 DH00124 - Nhà thuốc An Khang - Còn lại: 15,500,000đ
🟡 Ngày 30/08: + 50,000,000 - ND: NOP TIEN MAT CN DH1 🟡 Phiếu bàn giao #BG-001 - Dược sĩ Lan - Tiền mặt: 50,250,000đ
Ngày 29/08: - 5,000,000 - ND: Tien van phong pham ...

• Luồng công việc thông minh:

1. Tải lên & AI Phân tích: Kế toán tải file sao kê (PDF, Excel) lên. "Mắt thần" AI sẽ tự động đọc và bóc tách từng dòng giao dịch.
2. AI Tự động Gợi ý Ghép cặp: Hệ thống sẽ là một "người mai mối" thông minh:
    Màu Xanh (Khớp hoàn toàn 🟢): AI thấy giao dịch +15,500,000 từ "Nha thuoc An Khang" và tự động ghép nó với hóa đơn DH00124 có số tiền còn lại tương ứng.
    Màu Vàng (Gợi ý ghép cặp 🟡): AI thấy giao dịch +50,000,000 và phiếu bàn giao 50,250,000đ có số tiền gần giống và nội dung liên quan. Nó sẽ gợi ý ghép cặp và cảnh báo về sự chênh lệch nhỏ.
3. Vai trò của Kế toán - Người Xác thực: Công việc của kế toán giờ đây không phải là dò từng dòng. Họ chỉ cần:
    Xác nhận các cặp ghép nối màu Xanh và Vàng mà AI đã gợi ý.
    Kéo-thả thủ công để ghép các giao dịch còn lại mà AI không tự tìm được.
   • Kết quả: Mỗi khi một cặp được xác nhận, hệ thống sẽ tự động cập nhật trạng thái "Đã thanh toán" cho hóa đơn tương ứng và tạo ra Phiếu Thu. Quy trình đối soát hàng trăm giao dịch có thể được hoàn thành chỉ trong vài phút.

5.8.5 Nút “Nghiệp vụ Kế toán”
Module "Nghiệp vụ Kế toán" - Trạm Trung chuyển Dữ liệu Sạch
Triết lý thiết kế: Module này không đặt mục tiêu thay thế hoàn toàn một phần mềm kế toán chuyên sâu như MISA. Thay vào đó, nó đóng vai trò là một "Trạm trung chuyển dữ liệu kế toán sạch". Nhiệm vụ chính của nó là tự động ghi nhận tất cả các nghiệp vụ phát sinh, chuẩn hóa chúng theo đúng hệ thống tài khoản kế toán, và tạo ra một đầu ra hoàn hảo để tích hợp liền mạch với MISA.
Truy cập: Tài Chính & Kế Toán -> Nghiệp vụ Kế toán
A. Cấu trúc Menu & Giao diện
Menu con của module này sẽ bao gồm các công cụ nền tảng cho bộ phận kế toán:
• Hệ thống Tài khoản
• Sổ Nhật ký Chung
• Kết chuyển & Khóa sổ
• Tích hợp MISA

---

B. Giao diện "Hệ thống Tài khoản Kế toán"
• Mục đích: Đây là nơi để người dùng định nghĩa "xương sống" của toàn bộ hệ thống kế toán - danh sách các tài khoản (ví dụ: 111 - Tiền mặt, 131 - Phải thu của khách hàng, 511 - Doanh thu bán hàng...).
• Giao diện: Một danh sách dạng cây, hiển thị rõ ràng cấu trúc tài khoản. Hệ thống sẽ được cài đặt sẵn một hệ thống tài khoản chuẩn của Việt Nam, và kế toán trưởng có thể tùy chỉnh hoặc thêm các tài khoản chi tiết hơn.
• Tích hợp thông minh: "Trợ lý AI Phân loại Chi phí" mà chúng ta đã thiết kế sẽ sử dụng chính hệ thống tài khoản này để đưa ra các gợi ý hạch toán.

---

C. Giao diện "Sổ Nhật ký Chung" (General Journal)
• Mục đích: Đây là cuốn sổ cái tổng hợp, ghi lại tất cả các bút toán tài chính phát sinh trong toàn bộ hệ thống. Giao diện này chủ yếu để xem và kiểm tra, đối soát.
• Điều kỳ diệu: Kế toán viên gần như không bao giờ phải nhập tay vào đây. Sổ nhật ký này được ghi tự động.
o Ví dụ: Khi Dược sĩ hoàn tất một đơn hàng POS, hệ thống sẽ tự động tạo một bút toán trong Sổ Nhật ký Chung: Nợ TK 111 / Có TK 511.
o Khi người dùng nhập kho một lô hàng, hệ thống tự động ghi: Nợ TK 156 / Có TK 331.
• Giao diện: Một bảng dữ liệu chi tiết, cho phép lọc theo ngày, loại nghiệp vụ, tài khoản...
Ngày Số Chứng từ Diễn giải Tài khoản Nợ Tài khoản Có Số tiền
30/08/25 DH00126 Doanh thu bán lẻ tại Nhà thuốc ĐH 1 1111 5111 90.000đ
29/08/25 PNK-00123 Nhập kho hàng hóa từ Dược Hậu Giang 1561 3311 120.000.000đ

D. Giao diện "Tích hợp MISA" - Cây cầu Vững chắc
Đây là chức năng quan trọng nhất của module này, được thiết kế chính xác theo yêu cầu đã thống nhất của chúng ta .
• Mục đích: Xuất khẩu dữ liệu tài chính từ Nam Việt ERP ra file Excel với định dạng chuẩn 100% của MISA, giúp kế toán nhập khẩu vào MISA chỉ với vài cú nhấp chuột.
• Giao diện - Trình hướng dẫn (Wizard) Xuất dữ liệu:
o Bước 1: Chọn Loại Dữ liệu cần Xuất
 [ ✅ ] Chứng từ Bán hàng
 [ ✅ ] Hóa đơn Mua hàng
 [ ✅ ] Phiếu Thu, Phiếu Chi
 [ ] Danh mục Khách hàng, NCC...
o Bước 2: Chọn Kỳ Dữ liệu
 Khoảng thời gian: [Chọn tháng, quý hoặc một khoảng ngày tùy chỉnh]
o Bước 3: Xem trước & Xác nhận
 Hệ thống sẽ hiển thị một bản xem trước của dữ liệu sắp được xuất ra để kế toán kiểm tra lần cuối.
o Bước 4: Tải xuống
 Người dùng nhấn [Tải xuống file Excel cho MISA].
• Sự thông minh phía sau: Hệ thống sẽ tự động tạo ra một file Excel có cấu trúc cột, tên cột, và định dạng dữ liệu khớp chính xác với file mẫu nhập khẩu của MISA . Điều này loại bỏ hoàn toàn việc kế toán phải sao chép, chỉnh sửa file thủ công, tiết kiệm thời gian và đảm bảo không có sai sót.

5.8.6 Quản lý Hóa Đơn VAT
A. Giao diện "Nhập Hàng từ HĐ VAT" (Quản lý Đầu vào)
• Vị trí: Tài Chính & Kế Toán -> Nghiệp vụ Kế toán -> Nhập Hàng từ HĐ VAT.
• Mục đích: Chỉ để ghi nhận số lượng hàng hóa có hóa đơn VAT đầu vào, tạo ra một "kho ảo" về mặt chứng từ. Số liệu này KHÔNG ảnh hưởng đến tồn kho vật lý bán hàng.
• Luồng hoạt động:

1. Kế toán viên nhấn [+ Nhập Hàng từ HĐ VAT].
2. Họ tải lên file hóa đơn (PDF/ảnh).
3. "Mắt thần" AI sẽ tự động đọc, bóc tách tên sản phẩm và số lượng.
4. Khi kế toán viên xác nhận, hệ thống sẽ cộng dồn số lượng này vào một sổ theo dõi riêng gọi là "Sổ Tồn kho VAT" cho từng sản phẩm.
   B. Giao diện "Xuất Hóa Đơn VAT" (Kiểm soát Đầu ra)
   • Vị trí: Tài Chính & Kế Toán -> Nghiệp vụ Kế toán -> Xuất Hóa Đơn VAT.
   • Mục đích: Cho phép kế toán tạo hóa đơn VAT cho khách hàng, đồng thời kích hoạt "Vệ sĩ Thuế" để kiểm soát.
   • Luồng hoạt động:
5. Kế toán nhấn [+ Xuất Hóa Đơn VAT].
6. Họ có thể chọn [Tạo từ Đơn hàng] (hệ thống sẽ tự động điền thông tin khách hàng và sản phẩm từ một đơn hàng bán buôn đã có) hoặc tạo một hóa đơn trống.
7. Kế toán có toàn quyền tùy chỉnh số lượng trên hóa đơn theo ý muốn.
8. "Vệ sĩ Thuế" làm việc: Trước khi cho phép lưu và phát hành hóa đơn, hệ thống sẽ thực hiện một kiểm tra tối quan trọng:
   "Số lượng sản phẩm A đang xuất trên hóa đơn này có nhỏ hơn hoặc bằng số lượng trong 'Sổ Tồn kho VAT' không?"
    Nếu CÓ: Hóa đơn được phát hành. Hệ thống sẽ trừ số lượng tương ứng ra khỏi "Sổ Tồn kho VAT".
    Nếu KHÔNG: Hệ thống sẽ chặn lại và đưa ra cảnh báo đỏ: "⚠️ CẢNH BÁO: Không đủ Tồn kho VAT để xuất. Tồn kho VAT của sản phẩm A chỉ còn X. Vui lòng điều chỉnh!"
   Với quy trình này, người dùng đã tạo ra một hệ thống kiểm soát VAT cực kỳ chặt chẽ, giúp kế toán dễ dàng làm báo cáo thuế và loại bỏ hoàn toàn rủi ro xuất "lố" hóa đơn.

5.9 Quản lý Khách hàng:
Toàn bộ phần Quản lý Khách hàng như trong table dưới đây
A. Giao diện

- Các nút: Nhập Excel; Xuất Excel; Thêm mới khách hàng Lẻ; Thêm mới khách hàng B2B
- Ô tìm kiếm khách hàng: Tên; số đt; mã số thuế;
- Bộ lọc: chỉ hiển thị 2 bộ lọc cơ bản để tiết kiệm không gian hiển thị, còn lại được đặt trong 1 thanh bar ẩn/hiện:
  Bộ lọc chi tiết:
  • Loại Khách hàng: [Dropdown: Tất cả, Khách buôn (B2B), Khách lẻ (Bệnh nhân)]
  • Trạng thái: [Dropdown chọn nhiều: Đang giao dịch, Ngừng giao dịch, Tiềm năng...]
  • Xếp loại: [Dropdown chọn nhiều: VIP, Kim Cương, Vàng, Thành viên...]
  • Người phụ trách: [Dropdown chọn nhân viên kinh doanh/chăm sóc]
  • Nguồn Khách hàng: [Dropdown: Facebook, Zalo, Giới thiệu, Vãng lai...]
  • Nhóm Khách hàng: [Dropdown cho phép lọc theo các nhóm marketing đã tạo]
  • Địa chỉ: [Lọc theo Tỉnh/Thành phố, Quận/Huyện]
  C. Nâng cấp Bảng "Danh sách Khách hàng" & Tích hợp "Báo cáo Nhanh"

1. Khu vực "Báo cáo Nhanh" (Phía trên danh sách):
   Đây là giải pháp thay cho nút "Báo cáo nhanh". Cần hiển thị các chỉ số quan trọng nhất ngay trên màn hình. Ví dụ: Tổng quan: 1,520 Khách hàng | Đang giao dịch: 1,250 | Tổng Công nợ: 1.52 Tỷ VNĐ | Điểm tích lũy: 25,480,000 + Nút [Xem Báo cáo Chi tiết]
   Nút [Xem Báo cáo Chi tiết] sẽ dẫn thẳng người dùng đến module "Báo Cáo" chính, nơi có các biểu đồ, phân tích sâu và xu hướng theo thời gian.
2. Bảng Danh sách Khách hàng:
   Bảng dữ liệu thông tin khách hàng cơ bản:
   Mã KH Tên Khách hàng / Tên Công ty Loại Người Phụ trách Nợ Hiện tại Điểm Tích lũy Xếp loại Trạng thái Hành động
   B2B-001 Công ty Dược Hậu Giang B2B Nguyễn Văn A 150,200,000đ - Kim Cương ✅ Đang GD Xem/Sửa; Xóa
   KH-00234 Anh Nguyễn Văn An Bệnh nhân (Chung) 0đ 1,250 Thành viên ✅ Đang GD
   B2B-003 Nhà thuốc Minh Tâm B2B Trần Thị B 0đ - VIP 🔴 Ngừng GD Xem/Sửa; Xóa
   Một cột Checkbox ở đầu mỗi dòng.
   Khi người dùng chọn một hoặc nhiều khách hàng, một thanh công cụ "Hành động hàng loạt" sẽ hiện ra, cho phép thực hiện các tác vụ nhanh như: Cập nhật Trạng thái, Xếp loại hàng loạt, Gán nhân viên phụ trách, Xóa hàng loạt...

Phần 2: Luồng Công Việc Tạo Mới Khách hàng (Thông minh)

- Kịch bản 1: Tạo mới "Khách buôn (B2B)"
  Hành Động: Nhân viên kinh doanh hoặc Kế toán nhấn vào nút [+ Tạo mới Khách buôn].
  Hệ thống sẽ ngay lập tức mở ra giao diện "Tạo mới Hồ sơ Khách hàng Doanh nghiệp (B2B)", được thiết kế với các Tab chuyên biệt để quản lý thông tin pháp lý và thương mại phức tạp.
  Phần 1: Thông tin Chung & Pháp lý
  Tên Công ty*: (Ô văn bản)
  Mã số thuế*: (Ô văn bản, hệ thống có thể kiểm tra định dạng hợp lệ)
  Số Đăng ký Kinh doanh: (Ô văn bản)
  Địa chỉ ĐKKD: (Ô văn bản)
  Địa chỉ Giao hàng: (Có checkbox "Giống địa chỉ ĐKKD" để điền nhanh)
  Số Điện thoại Công ty, Email Kế toán
  Ghi chú chung: (Ô văn bản lớn để ghi các thông tin quan trọng khác)
  Phần 2: Thông tin Thương mại & Hợp đồng Đây là Tab chiến lược, quyết định cách chúng ta sẽ giao dịch với khách hàng này.
  Nhân viên Phụ trách*: [Dropdown chọn từ danh sách nhân viên kinh doanh]
  Bảng giá Áp dụng*: [Dropdown chọn từ các bảng giá sỉ đã tạo trong hệ thống]
  Hạn mức Công nợ*: [ 500,000,000 ] VNĐ (Ô nhập số)
  Điều khoản Thanh toán*: [Dropdown: Công nợ 30 ngày, Gối đầu, Thanh toán ngay khi nhận hàng...]
  Hợp đồng đã ký kết: Một khu vực cho phép tải lên và lưu trữ các file PDF, Word, ảnh chụp của hợp đồng đã ký, giúp quản lý tập trung toàn bộ hồ sơ pháp lý.
  Phần 3: Giấy phép & Năng lực
  Số giấy phép Kinh doanh Dược phẩm: (Ô văn bản, quan trọng để kiểm tra tư cách pháp nhân)
  Giới hạn được đăng kí kinh doanh: (Ghi chú về phạm vi kinh doanh của khách hàng, ví dụ: "Chỉ kinh doanh TPCN, không kinh doanh thuốc kê đơn")
  Phần 4: Danh sách Người liên hệ
  Một bảng đơn giản cho phép nhấn [+ Thêm người liên hệ] để thêm nhiều dòng, mỗi dòng gồm: Họ tên, Chức vụ, Số điện thoại, Email.
  Tại giao diện này, sẽ có thêm nút [ Điền thông tin khách hàng Từ Ảnh/file PDF ]  Chức năng giống như làm giàu dữ liệu từ file, khi bấm nút này, AI sẽ tự động đọc nội dung trong tài liệu được upload và điền thông tin vào các ô cần thiết.

_Kịch bản 2: Tạo mới "Khách lẻ (Bệnh nhân)"
Hành động: Lễ tân hoặc Dược sĩ nhấn vào nút [+ Tạo mới Khách lẻ].
Hệ thống mở ra một giao diện hoàn toàn khác: "Tạo mới Hồ sơ Khách lẻ (Bệnh nhân)", tập trung vào thông tin cá nhân và chăm sóc.
Phần 1: Thông tin Cá nhân:
• Họ và Tên_
• Số điện thoại _ (Hệ thống có thể tự động kiểm tra trùng lặp để tránh tạo khách hàng 2 lần)
• Ngày sinh_ (Khi nhập xong, hệ thống tự động tính và hiển thị tuổi bên cạnh, ví dụ: "25 tuổi, 3 tháng")
• Giới tính\*: [Dropdown: Nam, Nữ, Khác]
• Số Căn cước Công dân
• Email
• Nghề nghiệp
• Địa chỉ (gồm 3 trường: Tỉnh/Thành phố; Xã; Địa chỉ chi tiết)
• Ghi chú chung: (Ô văn bản lớn)
Phần 2: Thông tin Bổ sung & Chăm sóc
• Dị ứng:
• Bệnh mãn tính/ Tiền sử bệnh lý:
• Thói quen sinh hoạt: (Ô văn bản lớn để ghi chú các thông tin quan trọng do dược sĩ/bác sĩ tư vấn, giúp cho việc chăm sóc sau này)
Phần 3: Người Giám hộ
• Một khu vực có thể bật/tắt. Khi bật, sẽ hiện ra các trường để nhập thông tin người giám hộ (Họ tên, SĐT, Mối quan hệ, nghề nghiệp, số căn cước công dân) khi bệnh nhân là trẻ em. Lưu ý: 1 Trẻ em hoặc bệnh nhân có thể có nhiều người giám hộ (ông, bà…), nên chúng ta cần có thêm nút “Thêm người Giám Hộ”
Nút Bấm Hành Động Cuối Cùng (Chung cho cả hai kịch bản)
• [Lưu & Thêm Mới]/Sửa
• [Lưu & Đóng]

6.0 Báo Cáo
A. Triết lý Thiết kế & Kiến trúc Báo cáo Thông minh
Trước khi đi vào từng màn hình, chúng ta cần thống nhất 3 nguyên tắc sẽ định hình toàn bộ module này:

1. "Trí tuệ Kinh doanh Trực tuyến" (Live Business Intelligence): Nhờ kiến trúc Firestore thời gian thực, các báo cáo của chúng ta sẽ không phải là dữ liệu của "ngày hôm qua". Các con số sẽ được cập nhật gần như ngay lập tức sau khi giao dịch phát sinh, cho người dùng một cái nhìn "sống" về tình hình kinh doanh .
2. "Từ Tổng quan đến Chi tiết" (Drill-down): Mọi báo cáo sẽ được thiết kế theo cấu trúc Kim tự tháp ngược. Người dùng sẽ thấy những con số KPI quan trọng nhất ở trên cùng. Nếu muốn tìm hiểu sâu hơn, người dùng chỉ cần nhấp vào con số hoặc biểu đồ đó để xem dữ liệu chi tiết đã tạo nên nó.
3. Trực quan hóa Dữ liệu: Chúng ta sẽ ưu tiên sử dụng biểu đồ (đường, cột, tròn...) để biến những con số khô khan thành các câu chuyện trực quan, dễ hiểu về xu hướng và hiệu suất kinh doanh.
   Kỹ thuật phía sau: Để các báo cáo này chạy nhanh như chớp dù phải xử lý hàng triệu giao dịch, hệ thống có những "người thư ký ảo" (Cloud Functions) làm việc ngầm . Cứ mỗi khi có một đơn hàng được bán, "người thư ký" này sẽ ngay lập tức cập nhật vào các con số tổng. Nhờ vậy, khi người dùng mở báo cáo, hệ thống chỉ cần đọc những con số đã được tính sẵn thay vì phải cộng lại từ đầu.
   B. Giao diện "Trung Tâm Báo Cáo" - Cửa ngõ vào Dữ liệu
   Đây là màn hình chính khi người dùng truy cập module "Báo Cáo". Nó là một cổng thông tin sạch sẽ, có tổ chức.
   • Bên trái: Một thanh menu liệt kê tất cả các báo cáo có sẵn, được nhóm theo chức năng:
   • Báo cáo Kinh doanh
   • Báo cáo Bán hàng
   • Báo cáo Lãi - Lỗ
   • Báo cáo Marketing
   • Báo cáo Vận hành
   • Báo cáo Kho
   • Báo cáo Nhập hàng
   • Báo cáo Chăm sóc Khách hàng
   • Báo cáo Quản trị
   • Báo cáo Nhân viên & Hiệu suất (KPIs)
   • Báo cáo Tiến độ Công việc
   • Báo cáo Tài chính
   • Sổ quỹ
   • Bên phải: Khu vực chính để hiển thị nội dung của báo cáo được chọn. Trên mỗi giao diện báo cáo chính, chúng ta sẽ tích hợp một widget hoàn toàn mới, một "bộ não" phân tích nằm ngay bên cạnh các biểu đồ và con số.

C. Báo cáo đầu tiên: Báo cáo Bán hàng
Giai đoạn 1: Nền tảng - Giao diện "Thiết lập Mục tiêu KPI"
Để so sánh được với mục tiêu, trước tiên hệ thống phải biết "mục tiêu" đó là gì. Chúng ta sẽ tạo một giao diện mới, dành riêng cho cấp quản lý, có thể nằm trong Cấu Hình Hệ Thống hoặc là một phần của Dashboard quản trị.
Giao diện "Thiết lập Mục tiêu Kinh doanh":
Kỳ Áp dụng Đối tượng Chỉ tiêu Mục tiêu
Tháng 09/2025 Toàn công ty Doanh thu [ 5,000,000,000 ] VNĐ
Tháng 09/2025 Kênh Bán Buôn Doanh thu [ 3,000,000,000 ] VNĐ
Tháng 09/2025 Nhân viên: Nguyễn Văn A Doanh thu [ 500,000,000 ] VNĐ
Tháng 09/2025 Chi nhánh: Nhà thuốc ĐH 1 Số đơn hàng [ 1,200 ] Đơn

Giao diện này cho phép người dùng và các cấp quản lý chủ động đặt ra các mục tiêu rõ ràng cho từng kỳ, từng bộ phận, thậm chí từng nhân viên. Đây chính là "tấm bản đồ" để toàn bộ cỗ máy kinh doanh của chúng ta hướng tới.
Giai đoạn 2: Nâng cấp "Báo cáo Bán hàng" - Báo cáo Quản trị Hiệu suất
Giờ đây, khi đã có "tấm bản đồ" KPI, giao diện "Báo cáo Bán hàng" của chúng ta sẽ trở nên thông minh và mạnh mẽ hơn rất nhiều.

1. Bổ sung Bộ lọc "So sánh với":
   Trong khu vực bộ lọc, chúng ta sẽ thêm một dropdown quyền lực:
   • So sánh với:
   o [ Không so sánh ]
   o [ Kỳ trước (ví dụ: tháng trước) ]
   o [ Cùng kỳ năm trước ]
   o [ 🎯 Mục tiêu KPI đã đặt ]
2. Giao diện Báo cáo "Biến hình":
   Khi người dùng chọn [ 🎯 Mục tiêu KPI đã đặt ], toàn bộ các widget trong báo cáo sẽ tự động "biến hình" để hiển thị sự so sánh.
   • Khu vực KPI Chính (Scorecard):
   Tổng Doanh thu: 1.54 / 2.00 Tỷ VNĐ (Đạt 77% Mục tiêu) 📈
   Số lượng Đơn hàng: 850 / 1,200 Đơn (Đạt 71% Mục tiêu)
   • Khu vực Biểu đồ Trực quan:
   o Doanh thu theo Thời gian: Biểu đồ đường sẽ có 2 dòng: một dòng liền (màu xanh) thể hiện doanh thu thực tế đang chạy, và một dòng nét đứt (màu xám) thể hiện đường mục tiêu mà chúng ta cần đạt tới. Bác sĩ có thể thấy ngay mình đang chạy "trên" hay "dưới" đường mục tiêu.
   o Top 5 Nhân viên có Doanh số cao nhất: Biểu đồ cột sẽ được nâng cấp. Mỗi cột doanh thu của nhân viên sẽ có một vạch ngang nhỏ thể hiện KPI của riêng họ, giúp người dùng thấy ngay ai đã vượt chỉ tiêu, ai đang cần nỗ lực hơn.
   Ví dụ Thực tế - "Trợ lý AI" trên "Báo cáo Bán hàng"
   Hãy quay lại Báo cáo Bán hàng mà chúng ta vừa thiết kế. Giả sử sau khi người dùng lọc dữ liệu tháng này, các con số hiển thị rằng chúng ta mới đạt 77% KPI.
   • Dữ liệu đầu vào cho AI: Hệ thống sẽ tự động tóm tắt các dữ liệu chính trên màn hình và gửi cho Gemini: "Doanh thu tháng này đạt 77% mục tiêu. Kênh B2B tăng trưởng 15% so với tháng trước, nhưng kênh POS tại các cửa hàng giảm 10%. Sản phẩm 'Vitamin C' có doanh số đột biến, trong khi sản phẩm 'Siro Ho ABC' tồn kho nhiều nhưng bán rất chậm."
   • Kết quả "Trợ lý AI" hiển thị cho người dùng:
   💡 PHÂN TÍCH & NHẬN ĐỊNH:
   o "Doanh thu tổng thể đang chậm so với KPI đề ra. Điểm sáng là kênh B2B đang hoạt động rất tốt, cho thấy chiến lược giá và chăm sóc khách hàng doanh nghiệp đang hiệu quả. Tuy nhiên, điểm yếu cốt lõi đang nằm ở kênh bán lẻ tại cửa hàng (POS). Sự tăng trưởng của 'Vitamin C' có thể do yếu tố mùa vụ, nhưng 'Siro Ho ABC' đang là một rủi ro về đọng vốn và cần xử lý ngay."
   ** actionable HÀNH ĐỘNG GỢI Ý:**
3. [Ưu tiên cao] Phân tích nguyên nhân kênh POS sụt giảm: Có phải do chương trình khuyến mại chưa đủ hấp dẫn hay do vấn đề vận hành, tư vấn tại cửa hàng? Gợi ý: Giao ngay nhiệm vụ cho Trưởng phòng Kinh doanh Bán lẻ yêu cầu báo cáo chi tiết trước 10h sáng mai.
4. [Nên làm] Tạo chiến dịch Marketing đẩy mạnh "Siro Ho ABC": Xây dựng một combo bán kèm "Vitamin C" + "Siro Ho ABC" với giá ưu đãi. Gợi ý: Giao nhiệm vụ cho bộ phận Marketing thiết kế chương trình.
5. [Nên làm] Ghi nhận & Thưởng nóng cho đội ngũ B2B để duy trì động lực và phát huy thành tích.
   • Hành động tức thì: Người dùng đọc các gợi ý và thấy đề xuất số 1 và 2 là hợp lý. Người dùng chỉ cần nhấn vào nút [Giao việc từ Gợi ý], hệ thống sẽ mở ra một cửa sổ tạo nhiệm vụ mới, với nội dung đã được điền sẵn từ gợi ý của AI, người dùng chỉ cần chọn người thực hiện và hạn chót.
   Ví dụ Thực tế - "Trợ lý AI" trên "Báo cáo Chăm Sóc Khách Hàng"
   Giao diện "Báo cáo Chăm sóc Khách hàng"
   Trước tiên, hãy hình dung về chính báo cáo này. Nó sẽ tổng hợp dữ liệu từ CRM, POS, và cả module Lịch hẹn để cho người dùng một cái nhìn toàn cảnh về "sức khỏe" của tệp khách hàng.
   • Các KPI Chính:
   o Số Khách hàng mới
   o Tỷ lệ Khách hàng quay lại
   o Giá trị Vòng đời Khách hàng (LTV)
   o Top 5 Khách hàng Chi tiêu Cao nhất
   • Biểu đồ Trực quan:
   o Biểu đồ xu hướng khách hàng mới vs. khách hàng cũ theo thời gian.
   o Biểu đồ tròn phân bổ khách hàng theo các cấp bậc (VIP, Kim Cương, Vàng...).
   o Biểu đồ hiệu quả của các kênh thu hút khách hàng (Facebook, Zalo, Giới thiệu...).
   Trợ lý AI" hoạt động trên "Báo cáo Chăm sóc Khách hàng"
   Bây giờ, hãy xem "Trợ lý AI" sẽ làm gì với tất cả những dữ liệu này.
   Bối cảnh: Người dùng đang xem báo cáo Chăm sóc Khách hàng của tháng vừa qua. Widget "Trợ lý Phân tích AI" sẽ tự động làm việc và hiển thị kết quả.
   • Dữ liệu đầu vào cho AI: Hệ thống tóm tắt các điểm dữ liệu chính: "Tỷ lệ khách quay lại trong tháng giảm 5% so với tháng trước. Có 50 khách hàng hạng 'Kim Cương' đã không phát sinh giao dịch trong hơn 60 ngày. Kênh Zalo mang lại các khách hàng có giá trị vòng đời (LTV) cao nhất. Gói tiêm chủng HPV có tỷ lệ khách hàng quay lại tiêm mũi 2 chỉ đạt 40%."
   • Kết quả "Trợ lý AI" hiển thị cho người dùng:
   🤖 TRỢ LÝ PHÂN TÍCH AI

---

💡 PHÂN TÍCH & NHẬN ĐỊNH:
o "Tỷ lệ giữ chân khách hàng đang có dấu hiệu suy giảm nhẹ, cần được chú ý. Rủi ro lớn nhất hiện tại là nguy cơ rời bỏ của nhóm 50 khách hàng 'Kim Cương', đây là nhóm mang lại giá trị cao nhất. Điểm sáng là kênh Zalo đang chứng tỏ hiệu quả vượt trội trong việc thu hút khách hàng chất lượng. Có một vấn đề tiềm ẩn trong quy trình chăm sóc khách hàng sau khi tiêm mũi 1 của Gói HPV."
** actionable HÀNH ĐỘNG GỢI Ý:**

1. [Ưu tiên cao] "Cứu" nhóm khách hàng Kim Cương: Kích hoạt ngay một chiến dịch chăm sóc đặc biệt cho 50 khách hàng này. Gợi ý: Giao nhiệm vụ cho Trưởng nhóm CSKH soạn một tin nhắn ZNS cá nhân hóa kèm voucher giảm giá 15% cho lần mua tiếp theo và trực tiếp gọi điện hỏi thăm.
2. [Nên làm] Tối ưu hóa Kênh Zalo: Đầu tư thêm nguồn lực (nội dung, quảng cáo) vào kênh Zalo để mở rộng tệp khách hàng chất lượng cao. Gợi ý: Giao nhiệm vụ cho Marketing phân tích sâu hơn về hành vi và sở thích của nhóm khách hàng đến từ Zalo.
3. [Cần làm ngay] Cải thiện tỷ lệ tiêm chủng Gói HPV: Có khả năng quy trình nhắc lịch tự động cho gói này đang gặp vấn đề hoặc chưa đủ thuyết phục. Gợi ý: Giao nhiệm vụ cho CSKH triển khai một chiến dịch gọi điện thoại trực tiếp cho tất cả các khách hàng đã tiêm mũi 1 HPV nhưng chưa quay lại tiêm mũi 2.

---

[ Giao việc từ Gợi ý ]
Với "Trợ lý AI" này, Báo cáo Chăm sóc Khách hàng không còn là một bản thống kê khô khan. Nó đã trở thành một hệ thống cảnh báo sớm và gợi ý hành động chiến lược, giúp người dùng chủ động giữ chân những khách hàng giá trị nhất và vá lại những "lỗ hổng" trong quy trình chăm sóc trước khi chúng trở thành vấn đề lớn.
D. Giao diện "Báo cáo Kho"
Trước tiên, báo cáo này sẽ cung cấp cho người dùng các chỉ số "sức khỏe" kho vận quan trọng nhất.
• Các KPI Chính:
o Tổng Giá trị Tồn kho (Theo Giá Vốn)
o Vòng quay Hàng tồn kho (Số ngày cần để bán hết lượng hàng tồn kho trung bình)
o Tỷ lệ Hàng bán chậm (% hàng tồn kho không có giao dịch trong hơn 90 ngày)
o Giá trị Hàng sắp hết hạn (Tổng giá trị các lô hàng sẽ hết hạn trong 3 tháng tới)
• Biểu đồ Trực quan:
o Biểu đồ cơ cấu giá trị tồn kho theo nhóm sản phẩm.
o Biểu đồ xu hướng giá trị tồn kho và vòng quay kho theo thời gian.
• Các Bảng Cảnh báo:
o Danh sách Top 10 sản phẩm bán chậm nhất.
o Danh sách các lô hàng sắp hết hạn.

---

"Trợ lý AI" hoạt động trên "Báo cáo Kho"
Bối cảnh: Người dùng đang xem Báo cáo Kho và thấy giá trị tồn kho đang tăng lên, nhưng chưa rõ nguyên nhân sâu xa và cần làm gì. Widget "Trợ lý Phân tích AI" sẽ làm việc này cho người dùng.
• Dữ liệu đầu vào cho AI: Hệ thống tóm tắt các điểm dữ liệu chính từ báo cáo: "Tổng giá trị tồn kho tăng 15% so với tháng trước. Vòng quay hàng tồn kho đang chậm lại, ở mức 75 ngày. Tỷ lệ hàng bán chậm chiếm 20% tổng giá trị kho. Có một lượng lớn thuốc ho 'Siro Ho XYZ' (tồn 500 chai, hạn dùng còn 4 tháng) bán rất chậm, trong khi sản phẩm 'Vitamin C ABC' (tồn kho chỉ còn 50 viên trên toàn hệ thống) lại liên tục hết hàng ở các chi nhánh trong tuần qua."
• Kết quả "Trợ lý AI" hiển thị cho người dùng:
🤖 TRỢ LÝ PHÂN TÍCH AI

---

💡 PHÂN TÍCH & NHẬN ĐỊNH:
o "Rủi ro chính: Dòng vốn của công ty đang bị đọng lại trong hàng tồn kho ngày càng nhiều (giá trị tồn kho tăng, vòng quay chậm lại). Vấn đề cấp bách là lô hàng 'Siro Ho XYZ' có nguy cơ hết hạn trong 4 tháng tới, có thể gây thất thoát tài chính lớn nếu không hành động. Ngược lại, việc liên tục hết hàng 'Vitamin C ABC' cho thấy chúng ta đang bỏ lỡ doanh thu tiềm năng và chưa đáp ứng đủ nhu cầu thị trường."
** actionable HÀNH ĐỘNG GỢI Ý:**

1. [Ưu tiên cao] Xử lý 'Siro Ho XYZ': Tạo ngay một chương trình khuyến mại "Mua 1 tặng 1" hoặc xây dựng một "Gói Combo Mùa Lạnh" bán kèm 'Siro Ho XYZ' với các sản phẩm bán chạy khác. Gợi ý: Giao nhiệm vụ cho Marketing và Kinh doanh Bán lẻ triển khai trong tuần này.
2. [Cần làm ngay] Tối ưu hóa 'Vitamin C ABC': Điều chỉnh lại ngay lập tức Tồn kho Tối thiểu / Tối đa cho sản phẩm này tại tất cả các chi nhánh để hệ thống dự trù tự động đặt hàng nhiều hơn. Gợi ý: Mở ngay giao diện Cấu hình Sản phẩm để điều chỉnh.
3. [Nên xem xét] Rà soát lại toàn bộ danh mục hàng bán chậm. Cân nhắc các chương trình thanh lý hoặc đàm phán với nhà cung cấp về chính sách trả hàng cho các sản phẩm có vòng quay quá chậm.

---

[ Giao việc từ Gợi ý ]
E. Khuôn mẫu Báo cáo Thông minh" (Intelligent Reporting Template)
Với 3 ví dụ (Bán hàng, Chăm sóc Khách hàng, Kho), chúng ta không chỉ thiết kế 3 báo cáo riêng lẻ. Chúng ta đã cùng nhau kiến tạo nên một "Khuôn mẫu Báo cáo Thông minh" (Intelligent Reporting Template).

---

"Khuôn mẫu Báo cáo Thông minh" - DNA của Module Báo cáo
"Khuôn mẫu" này chính là bộ khung, là "bộ gen" sẽ được áp dụng cho tất cả các báo cáo còn lại, đảm bảo chúng đều mạnh mẽ và nhất quán. Bộ khung này bao gồm 5 thành phần cốt lõi:

1. Bộ lọc Toàn năng: Cho phép người dùng xoay chuyển và phân tích dữ liệu theo bất kỳ góc nhìn nào.
2. Khu vực KPI Chính: Hiển thị các con số quan trọng nhất một cách trực quan.
3. Khu vực Biểu đồ Trực quan: Biến dữ liệu thành các câu chuyện về xu hướng và hiệu suất.
4. Bảng Dữ liệu Chi tiết: Cho phép đi sâu vào từng giao dịch cụ thể.
5. "Trợ lý Phân tích AI": Bộ não phân tích, tìm ra vấn đề và gợi ý hành động.
   Bây giờ, hãy thử áp dụng nhanh "Khuôn mẫu" này vào các báo cáo còn lại để người dùng thấy sự hiệu quả của nó:
   • Với "Báo cáo Lãi - Lỗ":
   o KPIs: Tổng Doanh thu, Tổng Giá vốn, Lợi nhuận gộp, Chi phí Vận hành, Lợi nhuận Ròng.
   o Biểu đồ: Một biểu đồ thác nước (waterfall chart) thể hiện rõ dòng tiền từ doanh thu bị trừ đi các loại chi phí để ra được lợi nhuận cuối cùng.
   o Trợ lý AI sẽ: Phân tích các sản phẩm/dịch vụ có biên lợi nhuận cao/thấp nhất và gợi ý các chiến lược tối ưu hóa.
   • Với "Báo cáo Marketing":
   o KPIs: Tổng Chi phí Marketing, Số Khách hàng Mới, Chi phí/1 Khách hàng Mới (CPA), Tỷ lệ Chuyển đổi, Lợi tức Đầu tư (ROI).
   o Biểu đồ: Một biểu đồ phễu (funnel chart) thể hiện hiệu quả của phễu marketing.
   o Trợ lý AI sẽ: Chỉ ra kênh marketing nào (Facebook, Zalo...) đang hoạt động hiệu quả nhất và gợi ý tái phân bổ ngân sách để tối đa hóa ROI.
   • Với "Báo cáo Nhập hàng":
   o KPIs: Tổng giá trị nhập hàng, Số lượng nhà cung cấp, Công nợ phải trả trung bình.
   o Biểu đồ: Biểu đồ cơ cấu giá trị nhập hàng theo từng nhà cung cấp.
   o Trợ lý AI sẽ: Phân tích tần suất và giá trị đặt hàng, gợi ý các cơ hội đàm phán với nhà cung cấp để có chính sách giá tốt hơn.

6. Trang chủ
   6.1. Nâng cấp Hệ thống Chấm công: Tích hợp QR Code & Xác thực Vị trí
   Ý tưởng của người dùng về việc kết hợp mã QR và xác thực vị trí là một ý tưởng tuyệt vời, giúp tăng cường độ chính xác và an toàn cho hệ thống chấm công lên một tầm cao mới, gần như loại bỏ hoàn toàn khả năng gian lận. Chúng ta chắc chắn sẽ tích hợp giải pháp này.
   Luồng công việc Chấm công Nâng cao sẽ như sau:
7. Bước 1: Nhân viên đến công ty và đăng nhập vào hệ thống Nam Việt ERP trên máy tính tại nơi làm việc (quầy thuốc, văn phòng...).
8. Bước 2: Trên Dashboard cá nhân, họ nhấn vào nút [Bắt đầu Ca làm việc].
9. Bước 3 - "Mã Lệnh" Xuất hiện: Thay vì chỉ ghi nhận thời gian, hệ thống sẽ hiển thị một mã QR lớn, động trên màn hình máy tính. Mã QR này sẽ tự động thay đổi sau mỗi 15-30 giây để đảm bảo không thể bị chụp lại và sử dụng từ xa.
10. Bước 4 - Nhân viên "Quét Lệnh": Nhân viên sẽ mở ứng dụng di động Nam Việt ERP (hoặc một trang web chuyên dụng) trên điện thoại cá nhân của mình và sử dụng tính năng quét mã.
11. Bước 5 - Hệ thống Xác thực Kép: Khi quét mã QR thành công, ứng dụng trên điện thoại sẽ:
    o Yêu cầu Quyền truy cập Vị trí (với sự cho phép của nhân viên).
    o Kiểm tra Khoảng cách: Tự động tính toán khoảng cách từ vị trí hiện tại của nhân viên đến tọa độ GPS của cơ sở làm việc đã được đăng ký.
12. Bước 6 - Hoàn tất Chấm công:
    o Nếu nhân viên ở trong bán kính 50m: Màn hình điện thoại và máy tính sẽ cùng hiển thị thông báo "✅ Chấm công thành công!". Trạng thái của nhân viên trên hệ thống chuyển thành "Đang trong ca".
    o Nếu nhân viên ở ngoài bán kính 50m: Hệ thống sẽ báo lỗi "🔴 Vị trí không hợp lệ. Vui lòng chấm công tại nơi làm việc."
    Quy trình xác thực kép này đảm bảo rằng nhân viên phải có mặt tại đúng nơi làm việc và tương tác với hệ thống tại đúng thời điểm thì mới có thể chấm công, mang lại sự minh bạch và chính xác tuyệt đối.

---

6. 2. Về "Dashboard cá nhân": Trang chủ chính là Dashboard của người dùng
      Một câu hỏi rất hay để làm rõ. "Dashboard cá nhân" chính là Giao diện "Trang chủ" mà mỗi nhân viên nhìn thấy ngay sau khi họ đăng nhập.
      Như chúng ta đã thiết kế chi tiết trong giao diện
      "Trung Tâm Thông Tin Nam Việt" , Trang chủ này không phải là một trang tĩnh, mà là một không gian làm việc động, được chia làm 2 phần:
1. Phần "Quảng trường Chung": Hiển thị các thông tin chung của toàn công ty như tin tức nội bộ, lịch trực, khen thưởng... Đây là phần mà tất cả mọi người đều thấy giống nhau.
1. Phần "Buồng lái Cá nhân": Đây chính là Dashboard cá nhân của mỗi người. Nội dung trong khu vực này sẽ hoàn toàn khác nhau tùy thuộc vào vai trò của người đăng nhập.
   Widget "Chấm công" mà chúng ta vừa thảo luận sẽ là một trong những "ngăn" đầu tiên và quan trọng nhất trong khu vực "Buồng lái Cá nhân" này.
   • Ví dụ:
   o Một Dược sĩ khi đăng nhập sẽ thấy: Widget Chấm công, sau đó là widget "Đơn thuốc mới từ Phòng khám", "Nhiệm vụ Chăm sóc Khách hàng"...
   o Một Bác sĩ khi đăng nhập sẽ thấy: Widget Chấm công, sau đó là widget "Hàng đợi Bệnh nhân", "Hộp thư Kết quả Cận lâm sàng"...
   Cách thiết kế này đảm bảo Trang chủ vừa là nơi gắn kết văn hóa chung, vừa là một "bảng điều khiển" cá nhân hóa, cung cấp đúng công cụ mà mỗi nhân viên cần để bắt đầu ngày làm việc của mình một cách hiệu quả nhất.
   6.3 Giao diện và Luồng Góp ý, Đề xuất
   A. Điểm khởi tạo (Dành cho mọi nhân viên):
   • Ngay trên Trang chủ "Trung Tâm Thông Tin Nam Việt", chúng ta sẽ thêm một widget mới nổi bật:
   "GÓC GÓP Ý - SÁNG KIẾN – Đề Xuất"
   "Mọi ý tưởng của bạn đều đáng quý. Hãy cùng xây dựng Nam Việt ngày một tốt hơn!"
   [+ Gửi Đề xuất Mới]
   B. Giao diện "Gửi Đề xuất Mới":
   Khi nhân viên nhấn nút, một cửa sổ pop-up sẽ hiện ra.
   • Tiêu đề Đề xuất*: (Ví dụ: "Cải tiến quy trình đóng gói hàng B2B")
   • Lĩnh vực*: [Dropdown: Cải tiến Quy trình, Tiết kiệm Chi phí, Chăm sóc Khách hàng, Văn hóa Công ty, Đặt hàng riêng...]
   • Mô tả Chi tiết\*: (Một trình soạn thảo văn bản để nhân viên trình bày chi tiết ý tưởng của mình).
   • Chế độ Gửi:
   o ( ⚫ ) Gửi tới Quản lý trực tiếp
   o ( ⚪ ) Gửi tới Ban Giám đốc
   o ( ⚪ ) Gửi ẩn danh (Khuyến khích những ý kiến thẳng thắn)
   • Đính kèm file: (Cho phép tải lên hình ảnh, tài liệu minh họa).
   C. Giao diện Quản lý (Dành cho cấp quản lý):
   • Người quản lý sẽ có một giao diện riêng (có thể trong module Nhân sự) để xem và quản lý tất cả các đề xuất được gửi đến mình hoặc bộ phận của mình.
   • Các hành động của người quản lý:
   o Cập nhật Trạng thái của đề xuất: Mới, Đang xem xét, Đã phê duyệt, Đã từ chối, Đã triển khai.
   o Thảo luận: Viết các bình luận, phản hồi trực tiếp trên đề xuất đó.
   o [Giao việc]: Nếu đề xuất được duyệt, quản lý có thể tạo ngay một nhiệm vụ trong module "Giao việc & KPIs" và gán cho người thực hiện.
   Giải pháp này tạo ra một kênh giao tiếp 2 chiều, minh bạch và có cấu trúc, biến mỗi nhân viên thành một phần của quá trình đổi mới, giúp họ cảm thấy được lắng nghe và có giá trị hơn.

1. Nút “Quản lý Bảng tin Chung”
   Đây là nút cập nhật cho các chức năng của Trang chủ. Các chức năng Tạo Thông Báo, Tạo Quyết Định, Tạo Khen thưởng... chính là phần "quản trị nội dung" cho các widget trên Trang chủ "Trung Tâm Thông Tin Nam Việt" đã thiết kế.
   Để thực hiện việc này, các nhân viên được cấp quyền (như HR, Ban Giám đốc) sẽ có một giao diện quản lý đơn giản:
   • Giao diện "Quản lý Bảng tin chung":
   o Một danh sách tất cả các bài đăng đã tạo (Thông báo, Khen thưởng...).
   o Một nút [+ Tạo bài đăng Mới].
   o Khi tạo mới, họ có thể chọn Loại bài đăng, nhập Tiêu đề, Nội dung, đính kèm file và chọn "Ghim lên đầu trang" nếu là thông báo khẩn.
   Khi một bài đăng được tạo, nó sẽ ngay lập tức xuất hiện ở đúng widget tương ứng trên Trang chủ của tất cả nhân viên, giúp tạo ra sự gắn kết và dòng chảy thông tin thông suốt trong toàn công ty.
1. Module “Cấu hình hệ thống và Phân quyền”
   bao gồm các phần chính:
   • Quản lý Người dùng & Phân quyền: Nơi tạo tài khoản và gán vai trò, quyền hạn chi tiết cho từng nhân viên.
   • Cấu hình Nghiệp vụ: Nơi người dùng thiết lập các thông số cho toàn hệ thống như:
   o Tạo mới Kho hàng, Chi nhánh.
   o Thiết lập các Bảng giá, các Chính sách Lương & KPI.
   o Quản lý các Tài khoản/Quỹ tiền...
   • Quản lý Mẫu & Biểu mẫu: Nơi tùy chỉnh các mẫu in (hóa đơn, báo giá) và các mẫu nội dung (email, Zalo).
   • Nhật ký Hệ thống: Ghi lại mọi hành động quan trọng diễn ra trên hệ thống để phục vụ việc kiểm tra và đối soát.
   8.1 Quản lý Người dùng & Phân quyền
   Mục đích: Xây dựng một hệ thống phân quyền linh hoạt, an toàn và dễ quản lý, dựa trên mô hình Kiểm soát Truy cập Dựa trên Vai trò (Role-Based Access Control - RBAC) mà chúng ta đã thống nhất.
   Triết lý cốt lõi: "Chúng ta không cấp quyền cho từng người, chúng ta cấp quyền cho vai trò, và gán vai trò cho người." Điều này giúp việc quản lý hàng trăm nhân viên trở nên cực kỳ đơn giản.
   Truy cập: Cấu Hình Hệ Thống -> Người dùng & Phân quyền
   Giao diện sẽ được chia làm 2 Tab chính:
   A. Tab 1: "Quản lý Vai trò & Quyền hạn"
   Đây là nơi người dùng "nhào nặn" nên các chức danh và định nghĩa phạm vi quyền lực của họ.
   Bố cục 2 cột:
   • Cột Trái: Danh sách các Vai trò
   o Hiển thị tất cả các vai trò đã được tạo trong hệ thống: Ban Giám đốc, Quản lý Cửa hàng, Dược sĩ, Bác sĩ, Kế toán...
   o Nút hành động: [+ Tạo Vai trò Mới].
   • Cột Phải: "Cây" Phân quyền Chi tiết
   o Khi người dùng chọn một vai trò ở cột trái (ví dụ: Dược sĩ), cột phải sẽ hiển thị một danh sách dạng cây, bao gồm tất cả các quyền hạn có thể có trong toàn bộ hệ thống, được nhóm theo từng module.
   Module: Bán hàng POS
    [ ✅ ] Tạo Đơn hàng
    [ ✅ ] Xem Lịch sử Khách hàng
    [ ] Thay đổi Giá bán
    [ ] Hủy Đơn hàng
   Module: Kho – Sản phẩm
    [ ✅ ] Xem Tồn kho
    [ ] Tạo Phiếu Nhập Kho
    [ ] Kiểm Kê
   Luồng công việc của Quản trị viên:
1. Nhấn [+ Tạo Vai trò Mới], đặt tên là "Dược sĩ Trưởng".
1. Chọn vai trò "Dược sĩ Trưởng" vừa tạo.
1. Ở cột phải, chỉ cần tick vào các ô checkbox của những quyền hạn mà một Dược sĩ Trưởng được phép làm (ví dụ: tick thêm vào quyền "Thay đổi Giá bán" và "Hủy Đơn hàng").
1. Nhấn [Lưu].
   B. Tab 2: "Quản lý Người dùng"
   Đây là nơi người dùng gán các vai trò đã được định nghĩa cho từng nhân viên cụ thể.
   • Giao diện: Một danh sách tất cả các nhân viên trong hệ thống. Quản trị viên có thể tìm kiếm và chọn một nhân viên để phân quyền.
   • Giao diện "Phân quyền cho Nhân viên" (Ví dụ: cho nhân viên Nguyễn Thị Mai):
   o Đây là nơi thể hiện sự linh hoạt cho mô hình đa chi nhánh của người dùng. Quản trị viên có thể gán các vai trò khác nhau cho cùng một người tại các địa điểm khác nhau.
   PHÂN QUYỀN CHO: NGUYỄN THỊ MAI
    Tại Chi nhánh: [ Nhà thuốc ĐH 1 ] -> Vai trò là: [ Dược sĩ Trưởng ] [Xóa]
    Tại Chi nhánh: [ Kho Tổng B2B ] -> Vai trò là: [ Quản lý Kho ] [Xóa]
   [+ Thêm Phân quyền tại Chi nhánh Khác]
   • Cơ chế hoạt động thông minh phía sau:
   o Để hệ thống chạy nhanh và tiết kiệm chi phí, chúng ta sẽ không kiểm tra quyền hạn bằng cách đọc CSDL mỗi lần người dùng nhấp chuột.
   o Thay vào đó, khi một nhân viên đăng nhập, toàn bộ "thẻ bài" quyền hạn của họ sẽ được "đóng dấu" vào "vé vào cửa" (token) của họ. Mỗi lần họ thao tác, hệ thống chỉ cần nhìn vào "vé" này là biết ngay họ được phép làm gì, không cần tra cứu lại, giúp trải nghiệm luôn mượt mà.
   8.2 Cấu hình Nghiệp vụ, Quản lý Mẫu và Nhật ký Hệ thống
1. Giao diện "Cấu hình Nghiệp vụ" - Nơi Thiết lập "Luật chơi"
   Mục đích: Đây là trung tâm cài đặt cho toàn bộ các quy tắc kinh doanh của công ty. Thay vì phải vào từng module để chỉnh sửa, người dùng sẽ có một nơi tập trung để quản lý mọi thứ.
   Truy cập: Cấu Hình Hệ Thống -> Cấu hình Nghiệp vụ
   Giao diện: Sẽ có một thanh menu bên trái liệt kê các nhóm cấu hình, và khu vực bên phải để chỉnh sửa.
   • Menu Cấu hình:
   o Cấu hình Chung: Tên công ty, địa chỉ, logo, thông tin thuế...
   o Cấu hình Tài chính:
    Quản lý các Tài khoản/Quỹ tiền.
    Thiết lập Hệ thống Tài khoản Kế toán.
    Cài đặt các loại Thu/Chi.
   o Cấu hình Kinh doanh:
    Quản lý các Bảng giá (Bán buôn, Bán lẻ).
    Quản lý các Kênh Bán hàng (Shopee, Lazada...).
    Thiết lập các Chính sách Chiết khấu NCC.
   o Cấu hình Vận hành:
    Quản lý danh sách Kho hàng, Chi nhánh.
   o Cấu hình Nhân sự:
    Thiết lập các Chính sách Lương, KPIs.
    Quản lý các loại Hợp đồng.
   Ví dụ: Khi người dùng cần thêm một nhà kho mới, người dùng chỉ cần vào đây, chọn Cấu hình Vận hành -> Quản lý Kho hàng và nhấn [+ Thêm Kho mới]. Kho mới này sẽ ngay lập tức xuất hiện trong các dropdown lựa chọn ở module Nhập hàng, Chuyển hàng...

---

2. Giao diện "Quản lý Mẫu & Biểu mẫu" - Đồng bộ Hóa Nhận diện Thương hiệu
   Mục đích: Đây là "xưởng thiết kế", nơi người dùng có thể tùy chỉnh giao diện của tất cả các tài liệu sẽ được in ra hoặc gửi đi từ hệ thống, đảm bảo tính chuyên nghiệp và đồng bộ.
   Truy cập: Cấu Hình Hệ Thống -> Quản lý Mẫu & Biểu mẫu
   Giao diện: Một danh sách các loại mẫu có trong hệ thống.
   Tên Mẫu Áp dụng cho Module Hành động
   Mẫu Hóa đơn Bán lẻ (POS) Bán hàng POS [Sửa] [Xem trước]
   Mẫu Báo giá B2B Bán Buôn [Sửa] [Xem trước]
   Mẫu Phiếu lương Nhân viên Quản lý Nhân sự [Sửa] [Xem trước]
   Mẫu Email Nhắc nợ Tự động Tài Chính & Kế Toán [Sửa] [Xem trước]

• Trình chỉnh sửa Mẫu: Khi người dùng nhấn [Sửa], một trình soạn thảo văn bản trực quan (WYSIWYG) sẽ hiện ra. Tại đây người dùng có thể:
o Tải lên logo của công ty.
o Thay đổi bố cục, font chữ, màu sắc.
o Chèn các "biến" thông minh: Ví dụ, trong mẫu Hóa đơn, người dùng có thể kéo thả các biến như {TenKhachHang}, {DiaChi}, {TongTienBangChu} vào đúng vị trí người dùng muốn.

---

3. Giao diện "Nhật ký Hệ thống" (Audit Log) - "Hộp đen" Của Hệ thống
   Mục đích: Đây là công cụ giám sát và an ninh quan trọng nhất. Nó ghi lại mọi hành động quan trọng diễn ra trên toàn bộ hệ thống một cách không thể thay đổi, không thể xóa.
   Truy cập: Cấu Hình Hệ Thống -> Nhật ký Hệ thống
   Giao diện:
   • Bộ lọc Cực mạnh: Cho phép truy vết và điều tra mọi vấn đề.
   o Lọc theo Người dùng, Hành động (Tạo, Sửa, Xóa, Phê duyệt...), Đối tượng (Đơn hàng, Sản phẩm, Khách hàng...), Khoảng thời gian.
   • Bảng Nhật ký Chi tiết:
   Thời gian Người dùng Hành động Đối tượng Bị tác động Chi tiết Thay đổi
   30/08/25 10:15:22 Quản lý A HỦY Đơn hàng DH00126 Trạng thái: Hoàn tất -> Đã hủy. Lý do: Khách báo hủy.
   30/08/25 09:30:10 Kế toán B SỬA Khách hàng B2B-001 Hạn mức Công nợ: 500tr -> 700tr
   29/08/25 17:00:05 Bác sĩ Minh TẠO Đơn thuốc #DT-00987 Kê đơn Amoxicillin cho BN Nguyễn Văn An

Giá trị: "Hộp đen" này là công cụ tối thượng để đảm bảo sự minh bạch, quy trách nhiệm và điều tra các sai sót hay hành vi bất thường trong hệ thống, giúp người dùng quản trị doanh nghiệp một cách an toàn tuyệt đối.
