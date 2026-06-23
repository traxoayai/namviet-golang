# Tổng quan SePay eInvoice API

## Tổng quan SePay eInvoice API: tích hợp một lần để tạo, phát hành và quản lý hóa đơn điện tử tuân thủ Nghị định 123/2020/NĐ-CP tại Việt Nam.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## Giới thiệu

**SePay eInvoice API** là lớp trung gian giữa hệ thống của doanh nghiệp và cơ quan thuế (CQT), cho phép tạo và phát hành hóa đơn điện tử tuân thủ **Nghị định 123/2020/NĐ-CP** và Thông tư 78/2021/TT-BTC của Bộ Tài chính. Thay vì tích hợp riêng lẻ với từng nhà cung cấp hóa đơn điện tử, doanh nghiệp chỉ cần tích hợp **một lần duy nhất** với SePay để phát hành hóa đơn qua bất kỳ nhà cung cấp nào đã cấu hình.

API cung cấp đầy đủ vòng đời hóa đơn: từ tạo nháp, phát hành lên CQT, kiểm tra trạng thái theo thời gian thực, cho đến tải file PDF/XML và tra cứu hạn mức sử dụng — tất cả thông qua giao diện RESTful HTTP chuẩn.

<ButtonLink href="/vi/einvoice-demo" variant="primary">Xem hóa đơn demo</ButtonLink>

---

## Đối tượng sử dụng

eInvoice API phù hợp cho các tổ chức và cá nhân cần tự động hóa quy trình xuất hóa đơn điện tử:

<Features
items={[
{ icon: "package", title: "Nền tảng SaaS & ERP", description: "Tích hợp phát hành hóa đơn điện tử trực tiếp vào quy trình bán hàng, kế toán hoặc quản lý đơn hàng của phần mềm." },
{ icon: "trending-up", title: "Doanh nghiệp xuất hóa đơn số lượng lớn", description: "Tự động hóa hoàn toàn việc tạo và phát hành hóa đơn theo lô, giảm thiểu thao tác thủ công và sai sót." },
{ icon: "sliders", title: "Phần mềm kế toán", description: "Kết nối trực tiếp với CQT để phát hành và đồng bộ trạng thái hóa đơn, hỗ trợ đối soát và lưu trữ theo quy định." },
{ icon: "store", title: "Sàn thương mại điện tử", description: "Tự động xuất hóa đơn cho từng đơn hàng hoàn thành, đáp ứng yêu cầu xuất hóa đơn theo giao dịch." },
{ icon: "code", title: "Developer xây dựng giải pháp", description: "Xây dựng tính năng hóa đơn điện tử cho khách hàng doanh nghiệp mà không cần đàm phán trực tiếp với từng nhà cung cấp." }
]}
/>

---

## Tính năng chính

<Features
items={[
{ icon: "zap", title: "Xuất hóa đơn điện tử", description: "Tạo hóa đơn nháp hoặc phát hành trực tiếp qua POST v1/invoices/create, hỗ trợ nhiều mẫu và ký hiệu hóa đơn." },
{ icon: "shield", title: "Phát hành lên cơ quan thuế", description: "Gửi hóa đơn đến CQT qua nhà cung cấp hóa đơn điện tử đã cấu hình bằng POST v1/invoices/issue." },
{ icon: "refresh", title: "Theo dõi trạng thái bất đồng bộ", description: "Kiểm tra kết quả xử lý create/issue theo thời gian thực thông qua API /check/{tracking_code}." },
{ icon: "database", title: "Tra cứu và tải hóa đơn", description: "Lấy chi tiết hóa đơn đã phát hành kèm URL tải file PDF, XML theo chuẩn CQT." },
{ icon: "clock", title: "Kiểm tra hạn mức sử dụng", description: "Theo dõi số lượt phát hành còn lại qua GET v1/usage để lên kế hoạch sử dụng dịch vụ." },
{ icon: "sliders", title: "Quản lý tài khoản nhà cung cấp", description: "Xem danh sách và cấu hình chi tiết của các tài khoản nhà cung cấp hóa đơn điện tử đã đăng ký." }
]}
/>

---

## Luồng xử lý

<Mermaid title="Luồng xử lý eInvoice">
sequenceDiagram
  participant App as Merchant App
  participant API as SePay eInvoice API
  participant CQT as Cơ quan thuế (CQT)

App->>API: POST v1/token
API-->>App: access_token

App->>API: GET v1/provider-accounts
API-->>App: Danh sách tài khoản nhà cung cấp

App->>API: GET v1/provider-accounts/{id}
API-->>App: Chi tiết tài khoản (mẫu/ký hiệu HĐ)

App->>API: POST v1/invoices/create
API-->>App: tracking_code (tạo hóa đơn)

App->>API: GET v1/invoices/create/check/{tracking_code}
API-->>App: status, message (tạo hóa đơn)

App->>API: POST v1/invoices/issue
API-->>App: tracking_code (phát hành)

App->>API: GET v1/invoices/issue/check/{tracking_code}
API-->>App: status, message (phát hành)

API->>CQT: Gửi hóa đơn lên cơ quan thuế
CQT-->>API: Xác nhận tiếp nhận

App->>API: GET v1/invoices/{reference_code}
API-->>App: Chi tiết hóa đơn + URL file PDF/XML

App->>API: GET v1/usage
API-->>App: quota_remaining
</Mermaid>

Luồng xử lý eInvoice gồm các bước tuần tự từ xác thực, kiểm tra tài khoản đến tạo và phát hành hóa đơn:

1. **Lấy access token** — Gọi `POST v1/token` để lấy `access_token` dùng cho tất cả các API tiếp theo.

2. **Danh sách tài khoản nhà cung cấp** — Gọi `GET v1/provider-accounts` để xem các tài khoản hóa đơn điện tử khả dụng và trạng thái từng tài khoản.

3. **Chi tiết tài khoản** — Gọi `GET v1/provider-accounts/{id}` để lấy cấu hình chi tiết: mẫu hóa đơn, ký hiệu, trạng thái hoạt động.

4. **Tạo hóa đơn (Create)** — Gửi dữ liệu hóa đơn qua `POST v1/invoices/create`. API trả về `tracking_code` để theo dõi quá trình xử lý.

5. **Kiểm tra trạng thái tạo hóa đơn** — Gọi `GET v1/invoices/create/check/{tracking_code}` để xác nhận hóa đơn được tạo thành công hay thất bại.

6. **Phát hành hóa đơn (Issue)** — Gửi yêu cầu phát hành qua `POST v1/invoices/issue`. API trả về `tracking_code` riêng cho bước phát hành.

7. **Kiểm tra trạng thái phát hành** — Gọi `GET v1/invoices/issue/check/{tracking_code}` để xác nhận kết quả phát hành lên CQT.

8. **Lấy chi tiết hóa đơn** — Sau khi phát hành thành công, gọi `GET v1/invoices/{reference_code}` để nhận thông tin đầy đủ và URL tải file PDF, XML.

9. **Kiểm tra hạn ngạch** — Gọi `GET v1/usage` để theo dõi số lượt phát hành còn lại.

10. **Danh sách hóa đơn** — Gọi `GET v1/invoices` để lấy danh sách hóa đơn có phân trang phục vụ đối soát và quản lý.

<Callout type="info" title="Xử lý bất đồng bộ">
Các bước 
Create
 và 
Issue
 được xử lý bất đồng bộ. Sau khi gọi mỗi bước, bạn phải gọi API 
`/check`
 tương ứng để xác nhận trạng thái trước khi chuyển sang bước tiếp theo.
</Callout>

---

## Môi trường

| Môi trường     | Base URL                                |
| -------------- | --------------------------------------- |
| **Production** | `https://einvoice-api.sepay.vn`         |
| **Sandbox**    | `https://einvoice-api-sandbox.sepay.vn` |

Xác thực bằng Bearer token trong header: `Authorization: Bearer <ACCESS_TOKEN>`

<Callout type="info" title="Gợi ý">
Nếu bạn mới bắt đầu, hãy sử dụng môi trường 
Sandbox
 để thử nghiệm trước khi chuyển sang Production.
</Callout>

---

## Bước tiếp theo

Để bắt đầu tích hợp eInvoice API, thực hiện theo thứ tự sau:

1. **[Xác thực API hóa đơn điện tử (Bearer Token)](/vi/einvoice-api/v1/tao-token)** — Lấy Bearer token để xác thực các API tiếp theo
2. **[Danh sách nhà cung cấp hóa đơn điện tử](/vi/einvoice-api/v1/danh-sach-tai-khoan)** — Xem các tài khoản nhà cung cấp hóa đơn điện tử khả dụng
3. **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** — Bắt đầu tạo hóa đơn đầu tiên

# Bắt đầu nhanh với SePay eInvoice API

## Phát hành hóa đơn điện tử đầu tiên với SePay eInvoice API trong 4 bước. Lấy token, chọn nhà cung cấp, tạo và phát hành hóa đơn lên cơ quan thuế.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

<Callout type="info" title="Trước khi bắt đầu">
Bạn cần có:
client_id
 và 
client_secret
 từ tài khoản SePay eInvoice
Sử dụng môi trường 
Sandbox
 để thử nghiệm: 
`https://einvoice-api-sandbox.sepay.vn`
Tất cả API calls phải thực hiện từ 
server-side
 — không gọi trực tiếp từ client/browser
</Callout>

---

## Bước 1: Lấy Access Token

Mọi API eInvoice đều yêu cầu xác thực bằng Bearer token. Gọi endpoint `/v1/token` với **Basic Authentication** để lấy `access_token`.

<Endpoint>
  <Method>POST</Method>

<Path>https://einvoice-api.sepay.vn/v1/token</Path>

  <Description>
    Tạo token xác thực
  </Description>

  <Authentication>
    basicAuth
  </Authentication>
</Endpoint>

<Callout type="warning" title="Bảo mật">
KHÔNG
 gọi API này từ browser hay mobile app. 
`client_secret`
 phải được giữ tuyệt mật trên server của bạn.
</Callout>

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request POST \
      --url https://einvoice-api.sepay.vn/v1/token \
      --header 'Authorization: Basic REPLACE_BASIC_AUTH'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/token",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "POST",
      CURLOPT_HTTPHEADER => [
        "Authorization: Basic REPLACE_BASIC_AUTH"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Basic REPLACE_BASIC_AUTH" }
    
    conn.request("POST", "/v1/token", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "POST",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/token",
      "headers": {
        "Authorization": "Basic REPLACE_BASIC_AUTH"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/token")
      .post(null)
      .addHeader("Authorization", "Basic REPLACE_BASIC_AUTH")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/token")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = 'Basic REPLACE_BASIC_AUTH'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/token"
    
    	req, _ := http.NewRequest("POST", url, nil)
    
    	req.Header.Add("Authorization", "Basic REPLACE_BASIC_AUTH")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Post,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/token"),
        Headers =
        {
            { "Authorization", "Basic REPLACE_BASIC_AUTH" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Basic REPLACE_BASIC_AUTH"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/token")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/token")
      .post(null)
      .addHeader("Authorization", "Basic REPLACE_BASIC_AUTH")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

<Responses>
  <Response status="200">
    <Description>
      Token tạo thành công
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
          "token_type": "Bearer",
          "expires_in": 86400
        }
      }
    </Example>

  </Response>

</Responses>

<Callout type="info" title="Quản lý token">
Token có hiệu lực 
86400 giây (24 giờ)
. Nên lưu vào cache và tái sử dụng thay vì gọi lại mỗi request. Khi nhận lỗi 
`401`
, tự động lấy token mới.
</Callout>

---

## Bước 2: Lấy danh sách tài khoản nhà cung cấp

Trước khi tạo hóa đơn, bạn cần biết `provider_account_id` — ID tài khoản nhà cung cấp hóa đơn điện tử đã được cấu hình trong hệ thống. Gọi endpoint `/v1/provider-accounts` để lấy danh sách.

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/provider-accounts</Path>

  <Description>
    Danh sách tài khoản nhà cung cấp
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url 'https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20' \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/provider-accounts?page=1&per_page=20", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/provider-accounts?page=1&per_page=20",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

<Responses>
  <Response status="200">
    <Description>
      Danh sách tài khoản
    </Description>

    <Example>
      {
        "data": {
          "paging": {
            "per_page": 20,
            "total": 1,
            "has_more": false,
            "current_page": 1,
            "page_count": 1
          },
          "items": [
            {
              "id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
              "provider": "matbao",
              "active": true,
              "tax_authority_approved_date": "2026-04-20"
            }
          ]
        }
      }
    </Example>

  </Response>

</Responses>

<Callout type="info" title="Chọn tài khoản đúng">
Chỉ sử dụng tài khoản có 
`active: true`
. Nếu bạn có nhiều tài khoản từ nhiều nhà cung cấp khác nhau, hãy gọi 
API chi tiết tài khoản
 để xem mẫu hóa đơn và ký hiệu được phép dùng cho từng tài khoản.
</Callout>

---

## Bước 3: Tạo và phát hành hóa đơn

Gọi endpoint `/v1/invoices/create` với `is_draft: false` để tạo và phát hành hóa đơn trực tiếp (không qua bước nháp). API xử lý bất đồng bộ và trả về `tracking_code` để theo dõi kết quả ở bước tiếp theo.

<Endpoint>
  <Method>POST</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/create</Path>

  <Description>
    Xuất hóa đơn điện tử
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

<Params>
  <RequestBody>
    <Fields>
      <Field name="template_code" type="string" required="true">
        Mã mẫu hóa đơn (lấy từ API chi tiết tài khoản)
      </Field>
      <Field name="invoice_series" type="string" required="true">
        Ký hiệu hóa đơn (lấy từ API chi tiết tài khoản)
      </Field>
      <Field name="issued_date" type="string" required="true">
        Ngày phát hành (YYYY-MM-DD HH:mm:ss)
      </Field>
      <Field name="currency" type="enum: VND, USD, CAD" required="true">
        Đơn vị tiền tệ:
- VND: Việt Nam Đồng
- USD: Đô la Mỹ
- CAD: Đô la Canada

      </Field>
      <Field name="provider_account_id" type="string" required="true">
        ID tài khoản nhà cung cấp (UUID)
      </Field>
      <Field name="reference_code" type="string" required="false">
        Mã tham chiếu hóa đơn, phải là duy nhất. Nếu không truyền, hệ thống tự sinh UUID.
      </Field>
      <Field name="payment_method" type="enum: TM, CK, TM/CK, KHAC" required="false">
        Phương thức thanh toán:

- TM: Tiền mặt (Cash)
- CK: Chuyển khoản (Bank transfer)
- TM/CK: Tiền mặt và chuyển khoản (Cash and bank transfer)
- KHAC: Khác (Other)

      </Field>
      <Field name="is_draft" type="boolean" required="false">
        - `true`: Xuất nháp (cần phát hành sau, không tính vào hạn ngạch)

- `false`: Xuất và phát hành luôn

      </Field>
      <Field name="buyer" type="object" required="true">
        <Fields>
          <Field name="type" type="enum: personal, company" required="false">
            Loại người mua (personal, company)
          </Field>
          <Field name="name" type="string" required="false">
            Tên người/đơn vị mua
          </Field>
          <Field name="legal_name" type="string" required="false">
            Tên pháp lý (dùng khi buyer.type là company)
          </Field>
          <Field name="tax_code" type="string" required="false">
            Mã số thuế
          </Field>
          <Field name="address" type="string" required="false">
            Địa chỉ
          </Field>
          <Field name="email" type="string (email)" required="false">
            Email nhận hóa đơn
          </Field>
          <Field name="phone" type="string" required="false">
            Số điện thoại
          </Field>
          <Field name="buyer_code" type="string" required="false">
            Mã khách hàng (mã người mua hàng)
          </Field>
          <Field name="national_id" type="string" required="false">
            Căn cước công dân / Số CCCD / Số định danh cá nhân
          </Field>
        </Fields>
      </Field>
      <Field name="items" type="array" required="true">
        <Description>Danh sách hàng hóa/dịch vụ</Description>
        <ArrayItems>
          <Fields>
            <Field name="line_number" type="integer" required="true">
              Số thứ tự dòng
            </Field>
            <Field name="line_type" type="enum: 1, 2, 3, 4" required="true">
              Loại dòng hàng:

- 1: Hàng hóa/dịch vụ bình thường
- 2: Hàng khuyến mại
- 3: Chiết khấu thương mại
- 4: Ghi chú

            </Field>
            <Field name="item_code" type="string" required="false">
              Mã hàng hóa/dịch vụ
            </Field>
            <Field name="item_name" type="string" required="true">
              Tên hàng hóa/dịch vụ
            </Field>
            <Field name="unit" type="string" required="false">
              Đơn vị tính
            </Field>
            <Field name="quantity" type="number" required="false">
              Số lượng
            </Field>
            <Field name="unit_price" type="number" required="false">
              Đơn giá
            </Field>
            <Field name="tax_rate" type="enum: -2, -1, 0, 5, 8, 10" required="false">
              Thuế suất (%):

- -2: Không chịu thuế
- -1: Không kê khai, tính nộp thuế GTGT
- 0: 0%
- 5: 5%
- 8: 8%
- 10: 10%

            </Field>
            <Field name="discount_tax" type="number" required="false">
              Phần trăm chiết khấu trên sản phẩm (%)
            </Field>
            <Field name="discount_amount" type="number" required="false">
              Số tiền chiết khấu trên sản phẩm
            </Field>
            <Field name="before_discount_and_tax_amount" type="number" required="false">
              Số tiền trước chiết khấu và thuế (dùng cho line_type=3)
            </Field>
          </Fields>
        </ArrayItems>
      </Field>
      <Field name="notes" type="string" required="false">
        Ghi chú nội bộ
      </Field>
      <Field name="total_amount" type="integer" required="false">
        Tổng tiền thanh toán cuối cùng của hóa đơn (đã gồm thuế). **Không bắt buộc.** Nếu truyền thì phải là **số nguyên** (không có phần thập phân).

- **Không truyền:** hệ thống tự tính từ các dòng hàng (tiền hàng sau chiết khấu + thuế) và làm tròn về số nguyên.
- **Có truyền:** bạn tự tính và **tự làm tròn** về số nguyên; hệ thống dùng **đúng giá trị bạn gửi**, **KHÔNG kiểm tra / đối chiếu** với các dòng hàng. Gửi giá trị có phần thập phân (ví dụ `100000.5`) sẽ bị từ chối với lỗi `400`.

**Cảnh báo (khi có truyền):** Bạn tự chịu trách nhiệm về giá trị này. Nếu không khớp tiền hàng + thuế, hóa đơn sẽ hiển thị sai và cơ quan thuế có thể từ chối.

      </Field>
    </Fields>

    <Example>
      {
        "template_code": "2",
        "invoice_series": "C25HTV",
        "issued_date": "2025-12-11 08:00:00",
        "currency": "VND",
        "provider_account_id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
        "buyer": {
          "name": "Công ty ABC",
          "tax_code": "0101234567",
          "address": "123 Đường A, Quận B, Hà Nội",
          "email": "buyer@example.com",
          "phone": "0900000000"
        },
        "items": [
          {
            "line_number": 1,
            "line_type": 1,
            "item_code": "SP001",
            "item_name": "Sản phẩm A",
            "unit": "cái",
            "quantity": 1,
            "unit_price": 4500000
          }
        ],
        "notes": "Ghi chú hóa đơn",
        "is_draft": true
      }
    </Example>

  </RequestBody>
</Params>

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request POST \
      --url https://einvoice-api.sepay.vn/v1/invoices/create \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN' \
      --header 'content-type: application/json' \
      --data '{"template_code":"1","invoice_series":"C26TSE","issued_date":"2026-01-26 00:00:00","currency":"VND","provider_account_id":"0aea3134-da40-11f0-aef4-52c7e9b4f41b","reference_code":"0aea3134-da40-11f0-aef4-52c7e9b4f41b","payment_method":"TM","is_draft":false,"buyer":{"type":"personal","name":"Công ty TNHH ABC","legal_name":"CÔNG TY CỔ PHẦN ABC","tax_code":"0123456789","address":"123 Đường ABC, Quận 1, TP.HCM","email":"contact@abc.com","phone":"0901234567","buyer_code":"KH-001","national_id":"001234567890"},"items":[{"line_number":1,"line_type":1,"item_code":"SP001","item_name":"Sản phẩm A","unit":"cái","quantity":10,"unit_price":100000,"tax_rate":10,"discount_tax":10,"discount_amount":100000,"before_discount_and_tax_amount":4500000}],"notes":"Ghi chú nội bộ","total_amount":4950000}'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/create",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "POST",
      CURLOPT_POSTFIELDS => "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN",
        "content-type: application/json"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    payload = "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}"
    
    headers = {
        'Authorization': "Bearer REPLACE_BEARER_TOKEN",
        'content-type': "application/json"
        }
    
    conn.request("POST", "/v1/invoices/create", payload, headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "POST",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/create",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN",
        "content-type": "application/json"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.write(JSON.stringify({
      template_code: '1',
      invoice_series: 'C26TSE',
      issued_date: '2026-01-26 00:00:00',
      currency: 'VND',
      provider_account_id: '0aea3134-da40-11f0-aef4-52c7e9b4f41b',
      reference_code: '0aea3134-da40-11f0-aef4-52c7e9b4f41b',
      payment_method: 'TM',
      is_draft: false,
      buyer: {
        type: 'personal',
        name: 'Công ty TNHH ABC',
        legal_name: 'CÔNG TY CỔ PHẦN ABC',
        tax_code: '0123456789',
        address: '123 Đường ABC, Quận 1, TP.HCM',
        email: 'contact@abc.com',
        phone: '0901234567',
        buyer_code: 'KH-001',
        national_id: '001234567890'
      },
      items: [
        {
          line_number: 1,
          line_type: 1,
          item_code: 'SP001',
          item_name: 'Sản phẩm A',
          unit: 'cái',
          quantity: 10,
          unit_price: 100000,
          tax_rate: 10,
          discount_tax: 10,
          discount_amount: 100000,
          before_discount_and_tax_amount: 4500000
        }
      ],
      notes: 'Ghi chú nội bộ',
      total_amount: 4950000
    }));
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    MediaType mediaType = MediaType.parse("application/json");
    RequestBody body = RequestBody.create(mediaType, "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}");
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create")
      .post(body)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .addHeader("content-type", "application/json")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/create")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    request["content-type"] = 'application/json'
    request.body = "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}"
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"strings"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/create"
    
    	payload := strings.NewReader("{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}")
    
    	req, _ := http.NewRequest("POST", url, payload)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    	req.Header.Add("content-type", "application/json")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Post,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/create"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
        Content = new StringContent("{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}")
        {
            Headers =
            {
                ContentType = new MediaTypeHeaderValue("application/json")
            }
        }
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = [
      "Authorization": "Bearer REPLACE_BEARER_TOKEN",
      "content-type": "application/json"
    ]
    let parameters = [
      "template_code": "1",
      "invoice_series": "C26TSE",
      "issued_date": "2026-01-26 00:00:00",
      "currency": "VND",
      "provider_account_id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
      "reference_code": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
      "payment_method": "TM",
      "is_draft": false,
      "buyer": [
        "type": "personal",
        "name": "Công ty TNHH ABC",
        "legal_name": "CÔNG TY CỔ PHẦN ABC",
        "tax_code": "0123456789",
        "address": "123 Đường ABC, Quận 1, TP.HCM",
        "email": "contact@abc.com",
        "phone": "0901234567",
        "buyer_code": "KH-001",
        "national_id": "001234567890"
      ],
      "items": [
        [
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 10,
          "unit_price": 100000,
          "tax_rate": 10,
          "discount_tax": 10,
          "discount_amount": 100000,
          "before_discount_and_tax_amount": 4500000
        ]
      ],
      "notes": "Ghi chú nội bộ",
      "total_amount": 4950000
    ] as [String : Any]
    
    let postData = JSONSerialization.data(withJSONObject: parameters, options: [])
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/create")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val mediaType = MediaType.parse("application/json")
    val body = RequestBody.create(mediaType, "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}")
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create")
      .post(body)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .addHeader("content-type", "application/json")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

<Responses>
  <Response status="200">
    <Description>
      Yêu cầu xuất hóa đơn đã được tiếp nhận
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "tracking_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "tracking_url": "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "message": "Đã tạo yêu cầu xuất bán hóa đơn điện tử"
        }
      }
    </Example>

  </Response>

</Responses>

<Callout type="warning" title="Xử lý bất đồng bộ">
API trả về 
`tracking_code`
 ngay lập tức, nhưng hóa đơn 
chưa được phát hành
 tại thời điểm này. Bạn 
bắt buộc
 phải thực hiện Bước 4 để xác nhận kết quả phát hành.
</Callout>

---

## Bước 4: Kiểm tra trạng thái tạo hóa đơn

Gọi endpoint `/v1/invoices/create/check/{tracking_code}` để kiểm tra kết quả tạo hóa đơn. Khi `is_draft: false`, bước tạo đã bao gồm ký số và nộp lên cơ quan thuế — endpoint này xác nhận toàn bộ kết quả đó. Thực hiện polling với khoảng cách 2-3 giây, tối đa 10 lần.

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/create/check/{tracking_code}</Path>

  <Description>
    Theo dõi trạng thái xuất hóa đơn
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

<Responses>
  <Response status="200">
    <Description>
      Trạng thái xử lý
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "status": "Success",
          "message": "Xuất hóa đơn điện tử thành công",
          "invoice": {
            "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
            "invoice_number": "0",
            "issued_date": "2025-12-15",
            "pdf_url": "https://beta-portalv2.mifi.vn/DownloadPDFCA.aspx?kk=1434747710&keyinv=...",
            "xml_url": null,
            "status": "draft",
            "buyer": {
              "name": "Công ty ABC",
              "tax_code": "0101234567",
              "address": "123 Đường A, Quận B, Hà Nội",
              "email": "buyer@example.com",
              "phone": "0900000000"
            },
            "total_before_tax": 200000,
            "tax_amount": 20000,
            "total_amount": 220000,
            "notes": "Ghi chú hóa đơn",
            "source": "api"
          }
        }
      }
    </Example>

  </Response>

</Responses>

<Callout type="warning" title="Xử lý trạng thái Failed">
Nếu 
`status`
 trả về 
`"Failed"`
, kiểm tra trường 
`message`
 để biết nguyên nhân cụ thể (sai thông tin người mua, ký hiệu hóa đơn không hợp lệ, hết hạn mức...). Sau khi sửa dữ liệu, gọi lại 
API Xuất hóa đơn
 để tạo hóa đơn mới.
</Callout>

---

## Bước tiếp theo

Sau khi phát hành hóa đơn thành công:

1. **[Xác thực Bearer Token](/vi/einvoice-api/v1/tao-token)** — Chi tiết về xác thực và quản lý token
2. **[Danh sách nhà cung cấp](/vi/einvoice-api/v1/danh-sach-tai-khoan)** — Xem và chọn tài khoản nhà cung cấp
3. **[Chi tiết nhà cung cấp](/vi/einvoice-api/v1/chi-tiet-tai-khoan)** — Lấy cấu hình mẫu và ký hiệu hóa đơn
4. **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** — Tham số đầy đủ khi tạo hóa đơn
5. **[Trạng thái xuất hóa đơn](/vi/einvoice-api/v1/theo-doi-trang-thai-xuat-hoa-don)** — Chi tiết về polling trạng thái
6. **[Phát hành hóa đơn từ nháp](/vi/einvoice-api/v1/phat-hanh-hoa-don-dien-tu)** — Luồng tạo nháp rồi phát hành
7. **[Chi tiết hóa đơn](/vi/einvoice-api/v1/chi-tiet-hoa-don)** — Lấy thông tin hóa đơn sau phát hành
8. **[Tải hóa đơn](/vi/einvoice-api/v1/tai-hoa-don)** — Tải file PDF/XML của hóa đơn
9. **[Kiểm tra hạn mức](/vi/einvoice-api/v1/kiem-tra-han-ngach)** — Theo dõi số lượt phát hành còn lại

# API tạo Token xác thực

## Tạo Bearer token để xác thực các request API SePay E-Invoice. Bước bắt buộc đầu tiên trước khi gọi bất kỳ endpoint hóa đơn nào. Token có hiệu lực 24 giờ.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>POST</Method>

<Path>https://einvoice-api.sepay.vn/v1/token</Path>

  <Description>
    Tạo token xác thực
  </Description>

  <Authentication>
    basicAuth
  </Authentication>
</Endpoint>

## Xác thực

API này sử dụng **Basic Authentication** với thông tin đăng nhập:

- **Username:** `client_id` (được cấp khi đăng ký)
- **Password:** `client_secret` (được cấp khi đăng ký)

<Callout type="info" title="Lưu ý">
Gửi yêu cầu với body rỗng (không cần request body)
Token có hiệu lực 
86400 giây (24 giờ)
Sử dụng token này cho header 
`Authorization: Bearer {access_token}`
 trong các API tiếp theo
</Callout>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Token tạo thành công
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
          "token_type": "Bearer",
          "expires_in": 86400
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="access_token" type="string" required="true">
            Bearer token để xác thực API calls
          </Field>
          <Field name="token_type" type="enum: Bearer" required="true">
          </Field>
          <Field name="expires_in" type="integer" required="true">
            Thời gian hết hạn token (giây) - 24 giờ
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "Thiếu hoặc sai định dạng tham số." },
{ code: 401, name: "Unauthorized", description: "Sai thông tin client_id hoặc client_secret." }
]}
/>

<Responses>
  <Response status="400">
    <Description>
      Bad Request - Thiếu hoặc sai định dạng tham số
    </Description>

    <Example>
      {
        "success": false,
        "error": {
          "code": "BAD_REQUEST",
          "message": "Thiếu hoặc sai định dạng trường bắt buộc."
        }
      }
    </Example>

  </Response>

  <Response status="401">
    <Description>
      Unauthorized - Sai thông tin client_id hoặc client_secret
    </Description>

    <Example>
      {
        "success": false,
        "error": {
          "code": "UNAUTHORIZED",
          "message": "Sai thông tin client_id hoặc client_secret."
        }
      }
    </Example>

  </Response>

</Responses>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request POST \
      --url https://einvoice-api.sepay.vn/v1/token \
      --header 'Authorization: Basic REPLACE_BASIC_AUTH'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/token",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "POST",
      CURLOPT_HTTPHEADER => [
        "Authorization: Basic REPLACE_BASIC_AUTH"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Basic REPLACE_BASIC_AUTH" }
    
    conn.request("POST", "/v1/token", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "POST",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/token",
      "headers": {
        "Authorization": "Basic REPLACE_BASIC_AUTH"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/token")
      .post(null)
      .addHeader("Authorization", "Basic REPLACE_BASIC_AUTH")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/token")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = 'Basic REPLACE_BASIC_AUTH'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/token"
    
    	req, _ := http.NewRequest("POST", url, nil)
    
    	req.Header.Add("Authorization", "Basic REPLACE_BASIC_AUTH")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Post,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/token"),
        Headers =
        {
            { "Authorization", "Basic REPLACE_BASIC_AUTH" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Basic REPLACE_BASIC_AUTH"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/token")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/token")
      .post(null)
      .addHeader("Authorization", "Basic REPLACE_BASIC_AUTH")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Sử dụng token

Sau khi lấy được `access_token`, sử dụng nó trong header của các API eInvoice khác:

<Node title="Sử dụng Bearer Token">
```js
// Thêm token vào header Authorization
const headers = {
'Authorization': 'Bearer ' + access_token,
'Content-Type': 'application/json'
};

// Gọi API eInvoice khác
const response = await fetch('https://einvoice-api.sepay.vn/v1/invoices', {
method: 'GET',
headers: headers
});

```
</Node>

## Bước tiếp theo

Sau khi có access token, bạn có thể:

1. **[Xem danh sách tài khoản](/vi/einvoice-api/v1/danh-sach-tai-khoan)** - Lấy danh sách tài khoản nhà cung cấp hóa đơn điện tử để chọn tài khoản sử dụng
2. **[Kiểm tra hạn ngạch](/vi/einvoice-api/v1/kiem-tra-han-ngach)** - Xem số lượt phát hành hóa đơn còn lại trong gói dịch vụ
3. **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** - Bắt đầu tạo hóa đơn điện tử đầu tiên
```

# API lấy danh sách tài khoản nhà cung cấp

## Lấy danh sách tất cả tài khoản nhà cung cấp hóa đơn điện tử đã liên kết trong hệ thống SePay E-Invoice. Trả về danh sách với trạng thái và nhà cung cấp.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/provider-accounts</Path>

  <Description>
    Danh sách tài khoản nhà cung cấp
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <QueryParams>
    <Param name="page" type="integer" required="false">
      Trang hiện tại (mặc định 1)
    </Param>
    <Param name="per_page" type="integer" required="false">
      Số bản ghi trên mỗi trang (mặc định 20)
    </Param>
  </QueryParams>

</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Danh sách tài khoản
    </Description>

    <Example>
      {
        "data": {
          "paging": {
            "per_page": 20,
            "total": 1,
            "has_more": false,
            "current_page": 1,
            "page_count": 1
          },
          "items": [
            {
              "id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
              "provider": "matbao",
              "active": true,
              "tax_authority_approved_date": "2026-04-20"
            }
          ]
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="paging" type="object" required="false">
            <Fields>
              <Field name="per_page" type="integer" required="false">
                Số bản ghi mỗi trang
              </Field>
              <Field name="total" type="integer" required="false">
                Tổng số bản ghi
              </Field>
              <Field name="has_more" type="boolean" required="false">
                Còn dữ liệu ở trang tiếp theo hay không
              </Field>
              <Field name="current_page" type="integer" required="false">
                Trang hiện tại
              </Field>
              <Field name="page_count" type="integer" required="false">
                Tổng số trang
              </Field>
            </Fields>
          </Field>
          <Field name="items" type="array" required="false">
            <ArrayItems>
              <Fields>
                <Field name="id" type="string" required="false">
                  ID tài khoản (UUID)
                </Field>
                <Field name="provider" type="string" required="false">
                  Mã nhà cung cấp (matbao, bkav...)
                </Field>
                <Field name="active" type="boolean" required="false">
                  Trạng thái kích hoạt tài khoản
                </Field>
                <Field name="tax_authority_approved_date" type="string (date)" required="false">
                  Ngày CQT duyệt tờ khai. Hóa đơn có ngày lập trước ngày này sẽ bị từ chối.
Trả `null` khi chưa cập nhật hoặc ở sandbox.

                </Field>
              </Fields>
            </ArrayItems>
          </Field>
        </Fields>
      </Field>
    </Fields>

  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." }
]}
/>

## Lưu ý

<Callout type="info" title="Lưu ý">
Sử dụng 
`id`
 từ danh sách tài khoản nhà cung cấp làm giá trị cho trường 
`provider_account_id`
 khi 
tạo hóa đơn điện tử
.
Hỗ trợ phân trang với tham số 
`page`
 và 
`per_page`
 (tối đa 100 bản ghi mỗi trang).
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url 'https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20' \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/provider-accounts?page=1&per_page=20", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/provider-accounts?page=1&per_page=20",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/provider-accounts?page=1&per_page=20")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi có danh sách tài khoản nhà cung cấp, bạn có thể:

1. **[Xem chi tiết tài khoản](/vi/einvoice-api/v1/chi-tiet-tai-khoan)** - Lấy thông tin chi tiết (mẫu hóa đơn, ký hiệu) của tài khoản cụ thể
2. **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** - Sử dụng `id` tài khoản để tạo hóa đơn với `provider_account_id`

# API lấy chi tiết tài khoản nhà cung cấp

## Lấy thông tin chi tiết tài khoản xuất hóa đơn điện tử qua SePay E-Invoice API. Trả về trạng thái tài khoản, nhà cung cấp liên kết và ký hiệu hóa đơn.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/provider-accounts/{id}</Path>

  <Description>
    Chi tiết tài khoản nhà cung cấp
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <PathParams>
    <Param name="id" type="string" required="true">
      ID tài khoản nhà cung cấp (UUID)
    </Param>
  </PathParams>

</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Chi tiết tài khoản
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
          "provider": "matbao",
          "active": true,
          "tax_authority_approved_date": "2026-04-20",
          "templates": [
            {
              "template_code": "1",
              "invoice_series": "C25TAT",
              "invoice_label": "1 - C25TAT - Hóa đơn giá trị gia tăng"
            },
            {
              "template_code": "2",
              "invoice_series": "C25TMB",
              "invoice_label": "2 - C25TMB - Hóa đơn bán hàng"
            }
          ]
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="id" type="string" required="false">
            ID tài khoản (UUID)
          </Field>
          <Field name="provider" type="string" required="false">
            Mã nhà cung cấp (matbao, bkav...)
          </Field>
          <Field name="active" type="boolean" required="false">
            Trạng thái kích hoạt tài khoản
          </Field>
          <Field name="tax_authority_approved_date" type="string (date)" required="false">
            Ngày CQT duyệt tờ khai. Hóa đơn có ngày lập trước ngày này sẽ bị từ chối.
Trả `null` khi chưa cập nhật hoặc ở sandbox.

          </Field>
          <Field name="templates" type="array" required="false">
            <Description>Danh sách mẫu/ký hiệu được cấp</Description>
            <ArrayItems>
              <Fields>
                <Field name="template_code" type="string" required="false">
                  Mã mẫu hóa đơn
                </Field>
                <Field name="invoice_series" type="string" required="false">
                  Ký hiệu hóa đơn tương ứng
                </Field>
                <Field name="invoice_label" type="string" required="false">
                  Nhãn hiển thị đầy đủ để chọn trong giao diện
                </Field>
              </Fields>
            </ArrayItems>
          </Field>
        </Fields>
      </Field>
    </Fields>

  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 404, name: "Not Found", description: "Không tồn tại tài khoản với ID cung cấp." }
]}
/>

## Lưu ý

<Callout type="info" title="Lưu ý">
Lấy 
`id`
 từ 
API danh sách tài khoản nhà cung cấp
 để tra cứu chi tiết.
Sử dụng 
`template_code`
 và 
`invoice_series`
 từ danh sách 
`templates`
 khi 
tạo hóa đơn điện tử
.
Các mẫu hóa đơn phổ biến:
Hóa đơn giá trị gia tăng
 (VAT invoice)
Hóa đơn bán hàng
 (Sales invoice)
Phiếu xuất kho kiêm vận chuyển nội bộ
Biên lai điện tử
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/provider-accounts/0aea3134-da40-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi có thông tin chi tiết tài khoản (bao gồm `template_code` và `invoice_series`), bạn có thể:

1. **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** - Sử dụng thông tin mẫu hóa đơn và ký hiệu từ tài khoản này để tạo hóa đơn

# API tạo hóa đơn điện tử

## Tạo và ký số hóa đơn điện tử qua SePay E-Invoice API. Nộp dữ liệu hóa đơn lên cơ quan thuế và trả về mã tracking để theo dõi trạng thái xử lý.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

<ButtonLink href="/vi/einvoice-demo" variant="primary">Xem hóa đơn demo</ButtonLink>

## API Endpoint

<Endpoint>
  <Method>POST</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/create</Path>

  <Description>
    Xuất hóa đơn điện tử
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <RequestBody>
    <Fields>
      <Field name="template_code" type="string" required="true">
        Mã mẫu hóa đơn (lấy từ API chi tiết tài khoản)
      </Field>
      <Field name="invoice_series" type="string" required="true">
        Ký hiệu hóa đơn (lấy từ API chi tiết tài khoản)
      </Field>
      <Field name="issued_date" type="string" required="true">
        Ngày phát hành (YYYY-MM-DD HH:mm:ss)
      </Field>
      <Field name="currency" type="enum: VND, USD, CAD" required="true">
        Đơn vị tiền tệ:
- VND: Việt Nam Đồng
- USD: Đô la Mỹ
- CAD: Đô la Canada

      </Field>
      <Field name="provider_account_id" type="string" required="true">
        ID tài khoản nhà cung cấp (UUID)
      </Field>
      <Field name="reference_code" type="string" required="false">
        Mã tham chiếu hóa đơn, phải là duy nhất. Nếu không truyền, hệ thống tự sinh UUID.
      </Field>
      <Field name="payment_method" type="enum: TM, CK, TM/CK, KHAC" required="false">
        Phương thức thanh toán:

- TM: Tiền mặt (Cash)
- CK: Chuyển khoản (Bank transfer)
- TM/CK: Tiền mặt và chuyển khoản (Cash and bank transfer)
- KHAC: Khác (Other)

      </Field>
      <Field name="is_draft" type="boolean" required="false">
        - `true`: Xuất nháp (cần phát hành sau, không tính vào hạn ngạch)

- `false`: Xuất và phát hành luôn

      </Field>
      <Field name="buyer" type="object" required="true">
        <Fields>
          <Field name="type" type="enum: personal, company" required="false">
            Loại người mua (personal, company)
          </Field>
          <Field name="name" type="string" required="false">
            Tên người/đơn vị mua
          </Field>
          <Field name="legal_name" type="string" required="false">
            Tên pháp lý (dùng khi buyer.type là company)
          </Field>
          <Field name="tax_code" type="string" required="false">
            Mã số thuế
          </Field>
          <Field name="address" type="string" required="false">
            Địa chỉ
          </Field>
          <Field name="email" type="string (email)" required="false">
            Email nhận hóa đơn
          </Field>
          <Field name="phone" type="string" required="false">
            Số điện thoại
          </Field>
          <Field name="buyer_code" type="string" required="false">
            Mã khách hàng (mã người mua hàng)
          </Field>
          <Field name="national_id" type="string" required="false">
            Căn cước công dân / Số CCCD / Số định danh cá nhân
          </Field>
        </Fields>
      </Field>
      <Field name="items" type="array" required="true">
        <Description>Danh sách hàng hóa/dịch vụ</Description>
        <ArrayItems>
          <Fields>
            <Field name="line_number" type="integer" required="true">
              Số thứ tự dòng
            </Field>
            <Field name="line_type" type="enum: 1, 2, 3, 4" required="true">
              Loại dòng hàng:

- 1: Hàng hóa/dịch vụ bình thường
- 2: Hàng khuyến mại
- 3: Chiết khấu thương mại
- 4: Ghi chú

            </Field>
            <Field name="item_code" type="string" required="false">
              Mã hàng hóa/dịch vụ
            </Field>
            <Field name="item_name" type="string" required="true">
              Tên hàng hóa/dịch vụ
            </Field>
            <Field name="unit" type="string" required="false">
              Đơn vị tính
            </Field>
            <Field name="quantity" type="number" required="false">
              Số lượng
            </Field>
            <Field name="unit_price" type="number" required="false">
              Đơn giá
            </Field>
            <Field name="tax_rate" type="enum: -2, -1, 0, 5, 8, 10" required="false">
              Thuế suất (%):

- -2: Không chịu thuế
- -1: Không kê khai, tính nộp thuế GTGT
- 0: 0%
- 5: 5%
- 8: 8%
- 10: 10%

            </Field>
            <Field name="discount_tax" type="number" required="false">
              Phần trăm chiết khấu trên sản phẩm (%)
            </Field>
            <Field name="discount_amount" type="number" required="false">
              Số tiền chiết khấu trên sản phẩm
            </Field>
            <Field name="before_discount_and_tax_amount" type="number" required="false">
              Số tiền trước chiết khấu và thuế (dùng cho line_type=3)
            </Field>
          </Fields>
        </ArrayItems>
      </Field>
      <Field name="notes" type="string" required="false">
        Ghi chú nội bộ
      </Field>
      <Field name="total_amount" type="integer" required="false">
        Tổng tiền thanh toán cuối cùng của hóa đơn (đã gồm thuế). **Không bắt buộc.** Nếu truyền thì phải là **số nguyên** (không có phần thập phân).

- **Không truyền:** hệ thống tự tính từ các dòng hàng (tiền hàng sau chiết khấu + thuế) và làm tròn về số nguyên.
- **Có truyền:** bạn tự tính và **tự làm tròn** về số nguyên; hệ thống dùng **đúng giá trị bạn gửi**, **KHÔNG kiểm tra / đối chiếu** với các dòng hàng. Gửi giá trị có phần thập phân (ví dụ `100000.5`) sẽ bị từ chối với lỗi `400`.

**Cảnh báo (khi có truyền):** Bạn tự chịu trách nhiệm về giá trị này. Nếu không khớp tiền hàng + thuế, hóa đơn sẽ hiển thị sai và cơ quan thuế có thể từ chối.

      </Field>
    </Fields>

    <Example>
      {
        "template_code": "2",
        "invoice_series": "C25HTV",
        "issued_date": "2025-12-11 08:00:00",
        "currency": "VND",
        "provider_account_id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
        "buyer": {
          "name": "Công ty ABC",
          "tax_code": "0101234567",
          "address": "123 Đường A, Quận B, Hà Nội",
          "email": "buyer@example.com",
          "phone": "0900000000"
        },
        "items": [
          {
            "line_number": 1,
            "line_type": 1,
            "item_code": "SP001",
            "item_name": "Sản phẩm A",
            "unit": "cái",
            "quantity": 1,
            "unit_price": 4500000
          }
        ],
        "notes": "Ghi chú hóa đơn",
        "is_draft": true
      }
    </Example>

  </RequestBody>
</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Yêu cầu xuất hóa đơn đã được tiếp nhận
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "tracking_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "tracking_url": "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "message": "Đã tạo yêu cầu xuất bán hóa đơn điện tử"
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="tracking_code" type="string" required="true">
            Mã tracking để theo dõi trạng thái
          </Field>
          <Field name="tracking_url" type="string (uri)" required="true">
            URL để check trạng thái xử lý
          </Field>
          <Field name="message" type="string" required="false">
            Thông điệp phản hồi
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "Thiếu hoặc sai định dạng các trường bắt buộc." },
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 403, name: "QUOTA_EXCEEDED", description: "Hết hạn ngạch phát hành hóa đơn điện tử. Nâng cấp gói hoặc liên hệ SePay để mở rộng hạn ngạch." },
{ code: 409, name: "EINVOICE_DOCUMENT_EXISTED", description: "Hệ thống đã ghi nhận hoá đơn cho mã tham chiếu này. reference_code phải là duy nhất." },
{ code: 500, name: "Internal Server Error", description: "Lỗi hệ thống khi ký/gửi hóa đơn." }
]}
/>

## Thông tin thuế suất

- `tax_rate` chỉ bắt buộc truyền khi dùng cho công ty (không cần truyền nếu sử dụng hoá đơn bán hàng)
- Trường `tax_rate` trong `items` truyền dữ liệu theo như bên dưới:
  - `-2` (Không chịu thuế)
  - `-1` (Không kê khai, tính nộp thuế GTGT)
  - `0` (0% thuế suất)
  - `5` (5% thuế suất)
  - `8` (8% thuế suất)
  - `10` (10% thuế suất)

## Số lượng thập phân

- `quantity` chấp nhận giá trị thập phân (tối đa 2 chữ số sau dấu phẩy).
- Phù hợp cho dịch vụ tính giờ (`Giờ`), cân/đo lường (`Kg`, `m`, `Lít`), hoặc đơn vị tính theo phần (`Phần`).
- Ví dụ: `1.5`, `2.75`, `0.25`.

## Lưu ý sử dụng

- Để phát hành, gửi `is_draft=false`. Nếu chỉ lưu nháp để xem trước, gửi `is_draft=true` (Nếu chỉ xuất hóa đơn nháp thì sẽ không bị tính vào hạn ngạch hóa đơn điện tử của bạn).
- `provider_account_id` được cung cấp từ **[API danh sách tài khoản hóa đơn điện tử](/vi/einvoice-api/v1/danh-sach-tai-khoan)**
- Sau khi gửi yêu cầu xuất hóa đơn thành công, sử dụng endpoint được cung cấp qua `tracking_url` để gọi **[api theo dõi trạng thái xuất hóa đơn](/vi/einvoice-api/v1/theo-doi-trang-thai-xuat-hoa-don)**

### Thêm ghi chú trên mẫu hoá đơn

- Nếu bạn muốn hiển thị ghi chú trên hoá đơn thì cần thêm môt item với `line_type:4` vào `items (array)`, định dạng item line như bên dưới

<Response title="json">
```json
{
  "line_number": 3,
  "line_type": 4,
  "item_name": "Hàng tặng không thu tiền (Đây là ghi chú của bạn)"
}
```
</Response>

### Cách tính khuyến mại vào tổng tiền

- Khi truyền một dòng khuyến mại với `line_type = 2`, mặc định giá trị sẽ bằng 0 và không được tính vào tổng tiền hóa đơn.
- Nếu muốn hàng khuyến mại được tính vào tổng tiền, bạn cần truyền vào giá trị unit_price hoặc các field liên quan đến giá khác (giống như `line_type = 1`) lớn hơn 0.

### Tổng tiền hóa đơn (total_amount)

`total_amount` **không bắt buộc**. Nếu truyền thì phải là **số nguyên** (không có phần thập phân). Đây là tổng tiền thanh toán cuối cùng của hóa đơn, **đã bao gồm thuế**.

#### Trường hợp 1: Không truyền (mặc định)

Hệ thống tự tính `total_amount` từ các dòng hàng (tiền hàng sau chiết khấu + thuế) và **làm tròn về số nguyên**.

#### Trường hợp 2: Có truyền

Bạn **tự tính và tự làm tròn** về số nguyên trước khi gửi. Hệ thống dùng **đúng giá trị bạn gửi**, **KHÔNG kiểm tra, KHÔNG đối chiếu** với tổng tính từ các dòng hàng. Gửi giá trị có phần thập phân (ví dụ `100000.5`) sẽ bị từ chối với lỗi `400`.

<Callout type="warning" title="Cảnh báo cho Trường hợp 2 (tự truyền total_amount)">
Bạn hoàn toàn chịu trách nhiệm về giá trị bạn truyền.
 Nếu truyền sai (không khớp tiền hàng + thuế), hóa đơn phát hành sẽ hiển thị tổng tiền sai và 
cơ quan thuế có thể từ chối
. Hãy tự tính và làm tròn chắc chắn trước khi gửi.
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request POST \
      --url https://einvoice-api.sepay.vn/v1/invoices/create \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN' \
      --header 'content-type: application/json' \
      --data '{"template_code":"1","invoice_series":"C26TSE","issued_date":"2026-01-26 00:00:00","currency":"VND","provider_account_id":"0aea3134-da40-11f0-aef4-52c7e9b4f41b","reference_code":"0aea3134-da40-11f0-aef4-52c7e9b4f41b","payment_method":"TM","is_draft":false,"buyer":{"type":"personal","name":"Công ty TNHH ABC","legal_name":"CÔNG TY CỔ PHẦN ABC","tax_code":"0123456789","address":"123 Đường ABC, Quận 1, TP.HCM","email":"contact@abc.com","phone":"0901234567","buyer_code":"KH-001","national_id":"001234567890"},"items":[{"line_number":1,"line_type":1,"item_code":"SP001","item_name":"Sản phẩm A","unit":"cái","quantity":10,"unit_price":100000,"tax_rate":10,"discount_tax":10,"discount_amount":100000,"before_discount_and_tax_amount":4500000}],"notes":"Ghi chú nội bộ","total_amount":4950000}'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/create",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "POST",
      CURLOPT_POSTFIELDS => "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN",
        "content-type: application/json"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    payload = "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}"
    
    headers = {
        'Authorization': "Bearer REPLACE_BEARER_TOKEN",
        'content-type': "application/json"
        }
    
    conn.request("POST", "/v1/invoices/create", payload, headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "POST",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/create",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN",
        "content-type": "application/json"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.write(JSON.stringify({
      template_code: '1',
      invoice_series: 'C26TSE',
      issued_date: '2026-01-26 00:00:00',
      currency: 'VND',
      provider_account_id: '0aea3134-da40-11f0-aef4-52c7e9b4f41b',
      reference_code: '0aea3134-da40-11f0-aef4-52c7e9b4f41b',
      payment_method: 'TM',
      is_draft: false,
      buyer: {
        type: 'personal',
        name: 'Công ty TNHH ABC',
        legal_name: 'CÔNG TY CỔ PHẦN ABC',
        tax_code: '0123456789',
        address: '123 Đường ABC, Quận 1, TP.HCM',
        email: 'contact@abc.com',
        phone: '0901234567',
        buyer_code: 'KH-001',
        national_id: '001234567890'
      },
      items: [
        {
          line_number: 1,
          line_type: 1,
          item_code: 'SP001',
          item_name: 'Sản phẩm A',
          unit: 'cái',
          quantity: 10,
          unit_price: 100000,
          tax_rate: 10,
          discount_tax: 10,
          discount_amount: 100000,
          before_discount_and_tax_amount: 4500000
        }
      ],
      notes: 'Ghi chú nội bộ',
      total_amount: 4950000
    }));
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    MediaType mediaType = MediaType.parse("application/json");
    RequestBody body = RequestBody.create(mediaType, "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}");
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create")
      .post(body)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .addHeader("content-type", "application/json")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/create")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    request["content-type"] = 'application/json'
    request.body = "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}"
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"strings"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/create"
    
    	payload := strings.NewReader("{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}")
    
    	req, _ := http.NewRequest("POST", url, payload)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    	req.Header.Add("content-type", "application/json")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Post,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/create"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
        Content = new StringContent("{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}")
        {
            Headers =
            {
                ContentType = new MediaTypeHeaderValue("application/json")
            }
        }
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = [
      "Authorization": "Bearer REPLACE_BEARER_TOKEN",
      "content-type": "application/json"
    ]
    let parameters = [
      "template_code": "1",
      "invoice_series": "C26TSE",
      "issued_date": "2026-01-26 00:00:00",
      "currency": "VND",
      "provider_account_id": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
      "reference_code": "0aea3134-da40-11f0-aef4-52c7e9b4f41b",
      "payment_method": "TM",
      "is_draft": false,
      "buyer": [
        "type": "personal",
        "name": "Công ty TNHH ABC",
        "legal_name": "CÔNG TY CỔ PHẦN ABC",
        "tax_code": "0123456789",
        "address": "123 Đường ABC, Quận 1, TP.HCM",
        "email": "contact@abc.com",
        "phone": "0901234567",
        "buyer_code": "KH-001",
        "national_id": "001234567890"
      ],
      "items": [
        [
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 10,
          "unit_price": 100000,
          "tax_rate": 10,
          "discount_tax": 10,
          "discount_amount": 100000,
          "before_discount_and_tax_amount": 4500000
        ]
      ],
      "notes": "Ghi chú nội bộ",
      "total_amount": 4950000
    ] as [String : Any]
    
    let postData = JSONSerialization.data(withJSONObject: parameters, options: [])
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/create")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val mediaType = MediaType.parse("application/json")
    val body = RequestBody.create(mediaType, "{\"template_code\":\"1\",\"invoice_series\":\"C26TSE\",\"issued_date\":\"2026-01-26 00:00:00\",\"currency\":\"VND\",\"provider_account_id\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"reference_code\":\"0aea3134-da40-11f0-aef4-52c7e9b4f41b\",\"payment_method\":\"TM\",\"is_draft\":false,\"buyer\":{\"type\":\"personal\",\"name\":\"Công ty TNHH ABC\",\"legal_name\":\"CÔNG TY CỔ PHẦN ABC\",\"tax_code\":\"0123456789\",\"address\":\"123 Đường ABC, Quận 1, TP.HCM\",\"email\":\"contact@abc.com\",\"phone\":\"0901234567\",\"buyer_code\":\"KH-001\",\"national_id\":\"001234567890\"},\"items\":[{\"line_number\":1,\"line_type\":1,\"item_code\":\"SP001\",\"item_name\":\"Sản phẩm A\",\"unit\":\"cái\",\"quantity\":10,\"unit_price\":100000,\"tax_rate\":10,\"discount_tax\":10,\"discount_amount\":100000,\"before_discount_and_tax_amount\":4500000}],\"notes\":\"Ghi chú nội bộ\",\"total_amount\":4950000}")
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create")
      .post(body)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .addHeader("content-type", "application/json")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

---

## Tham số mẫu cho các loại hoá đơn

### Mẫu hoá đơn bán hàng

<Response title="json">
```json
  {
      "template_code": "2",
      "invoice_series": "C25HTV",
      "issued_date": "2025-12-11 08:00:00",
      "currency": "VND",
      "provider_account_id": "{{your-provider-account-id}}",
      "buyer": {
          "name": "Công ty ABC",
          "tax_code": "0101234567",
          "address": "123 Đường A, Quận B, Hà Nội",
          "email": "buyer@example.com",
          "phone": "0900000000",
          "buyer_code": "KH-001",
          "national_id": "001234567890"
      },
      "items": [
          {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000
          }
      ],
      "notes": "Ghi chú hóa đơn",
      "is_draft": true
  }
```
</Response>

### Mẫu hóa đơn bán hàng có chiết khấu trên tổng đơn

<Response title="json">
```json
{
  "template_code": "2",
  "invoice_series": "C26TSP",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000
      },
      {
          "line_number": 2,
          "line_type": 3,
          "item_name": "Chiết khấu thương mại",
          "before_discount_and_tax_amount": 4500000
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "TM/CK",
  "is_draft": false
}
```
</Response>

### Mẫu hóa đơn bán hàng có chiết khấu trên sản phẩm (theo phần trăm giảm giá - discount_tax)

<Response title="json">
```json
{
  "template_code": "2",
  "invoice_series": "C26TSP",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000,
          "discount_tax": 2
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "TM",
  "is_draft": false
}
```
</Response>

### Mẫu hóa đơn bán hàng có chiết khấu trên sản phẩm (theo số tiền giảm giá - discount_amount)

<Response title="json">
```json
{
  "template_code": "2",
  "invoice_series": "C26TSP",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000,
          "discount_amount": 100000
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "CK",
  "is_draft": false
}
```
</Response>

### Mẫu hóa đơn bán hàng có khuyến mãi

<Response title="json">
```json
{
  "template_code": "2",
  "invoice_series": "C25HTV",
  "issued_date": "2025-12-11 08:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "name": "Công ty ABC",
      "tax_code": "0101234567",
      "address": "123 Đường A, Quận B, Hà Nội",
      "email": "buyer@example.com",
      "phone": "0900000000"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000
      },
      {
          "line_number": 2,
          "line_type": 2,
          "item_code": "KM001",
          "item_name": "Hàng KM",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 0
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "TM",
  "is_draft": true
}
```
</Response>

### Mẫu hóa đơn giá trị gia tăng

<Response title="json">
```json
{
  "template_code": "1",
  "invoice_series": "C26TSE",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000,
          "tax_rate": 10
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "CK",
  "is_draft": false
}
```
</Response>

### Mẫu hóa đơn giá trị gia tăng có chiết khấu trên tổng đơn

<Response title="json">
```json
{
  "template_code": "1",
  "invoice_series": "C26TSE",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000,
          "tax_rate": 10
      },
      {
          "line_number": 1,
          "line_type": 3,
          "item_name": "Chiết khấu thương mại",
          "tax_rate": 10,
          "before_discount_and_tax_amount": 100000
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "TM/CK",
  "is_draft": false
}
```
</Response>

### Mẫu hóa đơn giá trị gia tăng có chiết khấu trên sản phẩm (theo phần trăm giảm giá - discount_tax)

<Response title="json">
```json
{
  "template_code": "1",
  "invoice_series": "C26TSE",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000,
          "tax_rate": 10,
          "discount_tax": 10
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "CK",
  "is_draft": false
}
```
</Response>

### Mẫu hóa đơn giá trị gia tăng có chiết khấu trên sản phẩm (theo số tiền giảm giá - discount_amount)

<Response title="json">
```json
{
  "template_code": "1",
  "invoice_series": "C26TSE",
  "issued_date": "2026-01-26 00:00:00",
  "currency": "VND",
  "provider_account_id": "{{your-provider-account-id}}",
  "buyer": {
      "type": "personal",
      "name": "Buyer Name Demo",
      "tax_code": "0317887567",
      "address": "Số 88 Đường Ánh Sao, Phường Bình An, Quận 9, TP Hồ Chí Minh, Việt Nam",
      "email": "buyeremaildemo@gmail.com"
  },
  "items": [
      {
          "line_number": 1,
          "line_type": 1,
          "item_code": "SP001",
          "item_name": "Sản phẩm A",
          "unit": "cái",
          "quantity": 1,
          "unit_price": 4500000,
          "tax_rate": 10,
          "discount_amount": 100000
      }
  ],
  "notes": "Ghi chú hóa đơn",
  "payment_method": "KHAC",
  "is_draft": false
}
```
</Response>

---

## Bước tiếp theo

Sau khi gửi yêu cầu tạo hóa đơn thành công và nhận được `tracking_code`:

1. **[Theo dõi trạng thái xuất hóa đơn](/vi/einvoice-api/v1/theo-doi-trang-thai-xuat-hoa-don)** - Sử dụng `tracking_code` để kiểm tra kết quả xử lý (bắt buộc)

<Callout type="info" title="Sau khi xác nhận trạng thái thành công">
Nếu xuất hóa đơn 
nháp
 (
`is_draft=true`
): Tiếp tục 
Phát hành hóa đơn
 để phát hành chính thức
Nếu xuất hóa đơn 
chính thức
 (
`is_draft=false`
): Có thể 
Tải hóa đơn
 hoặc 
Xem chi tiết hóa đơn
</Callout>

# API theo dõi trạng thái xuất hóa đơn

## Theo dõi trạng thái xử lý yêu cầu xuất hóa đơn điện tử trong SePay E-Invoice theo mã tracking. Xác nhận ký số và nộp lên cơ quan thuế thành công.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/create/check/{tracking_code}</Path>

  <Description>
    Theo dõi trạng thái xuất hóa đơn
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <PathParams>
    <Param name="tracking_code" type="string" required="true">
      Mã tracking trả về khi gọi API xuất hóa đơn
    </Param>
  </PathParams>

</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Trạng thái xử lý
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "status": "Success",
          "message": "Xuất hóa đơn điện tử thành công",
          "invoice": {
            "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
            "invoice_number": "0",
            "issued_date": "2025-12-15",
            "pdf_url": "https://beta-portalv2.mifi.vn/DownloadPDFCA.aspx?kk=1434747710&keyinv=...",
            "xml_url": null,
            "status": "draft",
            "buyer": {
              "name": "Công ty ABC",
              "tax_code": "0101234567",
              "address": "123 Đường A, Quận B, Hà Nội",
              "email": "buyer@example.com",
              "phone": "0900000000"
            },
            "total_before_tax": 200000,
            "tax_amount": 20000,
            "total_amount": 220000,
            "notes": "Ghi chú hóa đơn",
            "source": "api"
          }
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="reference_code" type="string" required="true">
            Mã tham chiếu yêu cầu xuất hóa đơn
          </Field>
          <Field name="status" type="enum: Pending, Success, Failed" required="true">
            Trạng thái xử lý hóa đơn (Pending, Success, Failed)
          </Field>
          <Field name="message" type="string" required="true">
            Thông điệp mô tả trạng thái
          </Field>
          <Field name="invoice" type="object" required="false">
            <Fields>
              <Field name="reference_code" type="string" required="false">
                Mã tham chiếu hóa đơn
              </Field>
              <Field name="invoice_number" type="string" required="false">
                Số hóa đơn (0 nếu là nháp)
              </Field>
              <Field name="issued_date" type="string" required="false">
                Ngày phát hành hóa đơn
              </Field>
              <Field name="pdf_url" type="string" required="false">
                Link tải PDF hóa đơn
              </Field>
              <Field name="xml_url" type="string" required="false">
                Link tải XML (nếu có)
              </Field>
              <Field name="status" type="enum: draft, issued" required="false">
                Trạng thái hóa đơn (draft, issued)
              </Field>
              <Field name="buyer" type="object" required="false">
                <Fields>
                  <Field name="type" type="enum: personal, company" required="false">
                    Loại người mua (personal, company)
                  </Field>
                  <Field name="name" type="string" required="false">
                    Tên người/đơn vị mua
                  </Field>
                  <Field name="legal_name" type="string" required="false">
                    Tên pháp lý (dùng khi buyer.type là company)
                  </Field>
                  <Field name="tax_code" type="string" required="false">
                    Mã số thuế
                  </Field>
                  <Field name="address" type="string" required="false">
                    Địa chỉ
                  </Field>
                  <Field name="email" type="string (email)" required="false">
                    Email nhận hóa đơn
                  </Field>
                  <Field name="phone" type="string" required="false">
                    Số điện thoại
                  </Field>
                  <Field name="buyer_code" type="string" required="false">
                    Mã khách hàng (mã người mua hàng)
                  </Field>
                  <Field name="national_id" type="string" required="false">
                    Căn cước công dân / Số CCCD / Số định danh cá nhân
                  </Field>
                </Fields>
              </Field>
              <Field name="total_before_tax" type="number" required="false">
                Tổng tiền trước thuế
              </Field>
              <Field name="tax_amount" type="number" required="false">
                Tiền thuế
              </Field>
              <Field name="total_amount" type="number" required="false">
                Tổng thanh toán
              </Field>
              <Field name="notes" type="string" required="false">
                Ghi chú hóa đơn
              </Field>
              <Field name="source" type="enum: manual, api" required="false">
                Nguồn tạo hóa đơn (`manual` = tạo trên giao diện, `api` = tạo qua API)
              </Field>
            </Fields>
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "Thiếu hoặc sai tracking_code." },
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 404, name: "Not Found", description: "Không tìm thấy yêu cầu tương ứng với tracking_code." }
]}
/>

## Lưu ý

<Callout type="info" title="Lưu ý">
Sử dụng 
`tracking_code`
 trả về từ API 
Xuất hóa đơn điện tử
.
Khi 
`status`
 là 
`Success`
, đối tượng 
`invoice`
 sẽ chứa thông tin chi tiết hóa đơn bao gồm 
`pdf_url`
 để tải file PDF.
Nếu 
`status`
 là 
`Failed`
, kiểm tra trường 
`message`
 để biết nguyên nhân lỗi và xử lý phù hợp.
Nên sử dụng cơ chế polling với khoảng thời gian hợp lý (ví dụ: 2-5 giây) để kiểm tra trạng thái.
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/create/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Tùy vào kết quả trạng thái và loại hóa đơn đã tạo:

Nếu `status` là `Success` và hóa đơn nháp (`is_draft=true`):

1. **[Phát hành hóa đơn điện tử](/vi/einvoice-api/v1/phat-hanh-hoa-don-dien-tu)** - Sử dụng `reference_code` để phát hành chính thức

Nếu `status` là `Success` và hóa đơn chính thức (`is_draft=false`):

1. **[Tải hóa đơn](/vi/einvoice-api/v1/tai-hoa-don)** - Tải file PDF hoặc XML của hóa đơn
2. **[Chi tiết hóa đơn](/vi/einvoice-api/v1/chi-tiet-hoa-don)** - Xem thông tin chi tiết hóa đơn đã phát hành
3. **[Danh sách hóa đơn](/vi/einvoice-api/v1/danh-sach-hoa-don)** - Quản lý và tra cứu các hóa đơn đã tạo

Nếu `status` là `Failed`:

- Kiểm tra `message` để biết nguyên nhân lỗi và **[tạo lại hóa đơn](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** với thông tin đã sửa hoặc liên hệ SePay để được hỗ trợ

# API xóa hóa đơn nháp

## Xóa hóa đơn điện tử nháp khỏi SePay eInvoice API theo reference_code, loại bỏ hoàn toàn trước khi phát hành lên cơ quan thuế.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>POST</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/delete/{reference_code}</Path>

  <Description>
    Xóa hóa đơn nháp
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <PathParams>
    <Param name="reference_code" type="string" required="true">
      Mã tham chiếu hóa đơn nháp
    </Param>
  </PathParams>

</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Xóa hóa đơn nháp thành công
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "message": "Hóa đơn nháp đã được xóa thành công"
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="reference_code" type="string" required="true">
            Mã tham chiếu hóa đơn đã xóa
          </Field>
          <Field name="message" type="string" required="false">
            Thông điệp phản hồi
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "reference_code sai hoặc hóa đơn không ở trạng thái nháp." },
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 404, name: "Not Found", description: "Không tìm thấy hóa đơn." },
{ code: 500, name: "Server Error", description: "Không xóa được từ nhà cung cấp." }
]}
/>

## Lưu ý

<Callout type="warning" title="Cảnh báo">
Chỉ xóa được hóa đơn trạng thái 
`draft`
. Hóa đơn đã phát hành không xóa được. Thao tác không thể hoàn tác.
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request POST \
      --url https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "POST",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("POST", "/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "POST",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .post(null)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b"
    
    	req, _ := http.NewRequest("POST", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Post,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/delete/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .post(null)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

# API phát hành hóa đơn từ nháp

## Phát hành hóa đơn điện tử từ mã tham chiếu nháp qua SePay E-Invoice API. Trả về mã tracking để theo dõi trạng thái phát hành với cơ quan thuế.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>POST</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/issue</Path>

  <Description>
    Phát hành hóa đơn điện tử
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <RequestBody>
    <Fields>
      <Field name="reference_code" type="string" required="true">
        Mã tham chiếu hóa đơn nháp đã tạo trước đó
      </Field>
    </Fields>

    <Example>
      {
        "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b"
      }
    </Example>

  </RequestBody>
</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Yêu cầu phát hành đã được tiếp nhận
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "tracking_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "tracking_url": "https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "message": "Đã tạo yêu cầu xuất bán hóa đơn điện tử"
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="tracking_code" type="string" required="true">
            Mã tracking để theo dõi trạng thái phát hành
          </Field>
          <Field name="tracking_url" type="string (uri)" required="true">
            URL tra cứu trạng thái phát hành hóa đơn
          </Field>
          <Field name="message" type="string" required="false">
            Thông điệp phản hồi
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "Thiếu hoặc sai reference_code." },
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 404, name: "Not Found", description: "Không tìm thấy hóa đơn nháp theo reference_code." },
{ code: 422, name: "REGISTRATION_NOT_TAX_APPROVED", description: "Chưa đăng ký HĐĐT hoặc CQT chưa duyệt tờ khai." },
{ code: 422, name: "INVOICE_DATE_BEFORE_TAX_APPROVAL", description: "Ngày hóa đơn trước ngày CQT duyệt. Xem tax_authority_approved_date trong GET /v1/provider-accounts." }
]}
/>

## Lưu ý

<Callout type="info" title="Lưu ý">
Chỉ phát hành đối với những hóa đơn đã xuất nháp trước đó (
`is_draft=true`
)
`reference_code`
 có thể tra cứu qua 
API danh sách hóa đơn
 với những hóa đơn có 
`status`
 là 
`draft`
 hoặc lấy từ 
`reference_code`
 sau khi kiểm tra trạng thái tạo hóa đơn nháp thành công
Sau khi gửi yêu cầu phát hành hóa đơn thành công, sử dụng endpoint được cung cấp qua 
`tracking_url`
 để gọi 
API theo dõi trạng thái phát hành hóa đơn
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request POST \
      --url https://einvoice-api.sepay.vn/v1/invoices/issue \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN' \
      --header 'content-type: application/json' \
      --data '{"reference_code":"084e179d-d95a-11f0-aef4-52c7e9b4f41b"}'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/issue",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "POST",
      CURLOPT_POSTFIELDS => "{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN",
        "content-type: application/json"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    payload = "{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}"
    
    headers = {
        'Authorization': "Bearer REPLACE_BEARER_TOKEN",
        'content-type': "application/json"
        }
    
    conn.request("POST", "/v1/invoices/issue", payload, headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "POST",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/issue",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN",
        "content-type": "application/json"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.write(JSON.stringify({reference_code: '084e179d-d95a-11f0-aef4-52c7e9b4f41b'}));
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    MediaType mediaType = MediaType.parse("application/json");
    RequestBody body = RequestBody.create(mediaType, "{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}");
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/issue")
      .post(body)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .addHeader("content-type", "application/json")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/issue")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    request["content-type"] = 'application/json'
    request.body = "{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}"
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"strings"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/issue"
    
    	payload := strings.NewReader("{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}")
    
    	req, _ := http.NewRequest("POST", url, payload)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    	req.Header.Add("content-type", "application/json")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Post,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/issue"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
        Content = new StringContent("{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}")
        {
            Headers =
            {
                ContentType = new MediaTypeHeaderValue("application/json")
            }
        }
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = [
      "Authorization": "Bearer REPLACE_BEARER_TOKEN",
      "content-type": "application/json"
    ]
    let parameters = ["reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b"] as [String : Any]
    
    let postData = JSONSerialization.data(withJSONObject: parameters, options: [])
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/issue")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val mediaType = MediaType.parse("application/json")
    val body = RequestBody.create(mediaType, "{\"reference_code\":\"084e179d-d95a-11f0-aef4-52c7e9b4f41b\"}")
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/issue")
      .post(body)
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .addHeader("content-type", "application/json")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi gửi yêu cầu phát hành thành công và nhận được `tracking_code`:

1. **[Theo dõi trạng thái phát hành hóa đơn](/vi/einvoice-api/v1/theo-doi-trang-thai-phat-hanh-hoa-don)** - Sử dụng `tracking_code` để kiểm tra kết quả phát hành (bắt buộc)

# API theo dõi trạng thái phát hành hóa đơn

## Theo dõi trạng thái phát hành hóa đơn điện tử theo mã tracking qua SePay E-Invoice API. Xác nhận đăng ký thành công với cơ quan thuế.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/issue/check/{tracking_code}</Path>

  <Description>
    Theo dõi trạng thái phát hành hóa đơn
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <PathParams>
    <Param name="tracking_code" type="string" required="true">
      Mã tracking trả về từ API phát hành hóa đơn
    </Param>
  </PathParams>

</Params>

<Callout type="info" title="Lưu ý">
`tracking_code`
 lấy từ response của API 
Phát hành hóa đơn điện tử
.
Khi 
`status`
 là 
`Success`
, object 
`invoice`
 sẽ chứa đầy đủ thông tin hóa đơn đã phát hành.
Khi 
`status`
 là 
`Pending`
, nên gọi lại API sau vài giây để kiểm tra kết quả.
</Callout>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Trạng thái xử lý
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "status": "Success",
          "message": "Xuất bán hóa đơn điện tử thành công",
          "invoice": {
            "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
            "invoice_number": "589",
            "issued_date": "2025-12-15",
            "pdf_url": "https://beta-portalv2.mifi.vn/DownloadPDFCA.aspx?kk=1434747710&keyinv=...",
            "xml_url": null,
            "status": "issued",
            "buyer": {
              "name": "Công ty ABC",
              "tax_code": "0101234567",
              "address": "123 Đường A, Quận B, Hà Nội",
              "email": "buyer@example.com",
              "phone": "0900000000"
            },
            "total_before_tax": 200000,
            "tax_amount": 20000,
            "total_amount": 220000,
            "notes": "Ghi chú hóa đơn",
            "source": "api"
          }
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="reference_code" type="string" required="true">
            Mã tham chiếu yêu cầu phát hành
          </Field>
          <Field name="status" type="enum: Pending, Success, Failed" required="true">
            Trạng thái xử lý (Pending, Success, Failed)
          </Field>
          <Field name="message" type="string" required="true">
            Thông điệp mô tả trạng thái
          </Field>
          <Field name="invoice" type="object" required="false">
            <Fields>
              <Field name="reference_code" type="string" required="false">
                Mã tham chiếu hóa đơn
              </Field>
              <Field name="invoice_number" type="string" required="false">
                Số hóa đơn (0 nếu là nháp)
              </Field>
              <Field name="issued_date" type="string" required="false">
                Ngày phát hành hóa đơn
              </Field>
              <Field name="pdf_url" type="string" required="false">
                Link tải PDF hóa đơn
              </Field>
              <Field name="xml_url" type="string" required="false">
                Link tải XML (nếu có)
              </Field>
              <Field name="status" type="enum: draft, issued" required="false">
                Trạng thái hóa đơn (draft, issued)
              </Field>
              <Field name="buyer" type="object" required="false">
                <Fields>
                  <Field name="type" type="enum: personal, company" required="false">
                    Loại người mua (personal, company)
                  </Field>
                  <Field name="name" type="string" required="false">
                    Tên người/đơn vị mua
                  </Field>
                  <Field name="legal_name" type="string" required="false">
                    Tên pháp lý (dùng khi buyer.type là company)
                  </Field>
                  <Field name="tax_code" type="string" required="false">
                    Mã số thuế
                  </Field>
                  <Field name="address" type="string" required="false">
                    Địa chỉ
                  </Field>
                  <Field name="email" type="string (email)" required="false">
                    Email nhận hóa đơn
                  </Field>
                  <Field name="phone" type="string" required="false">
                    Số điện thoại
                  </Field>
                  <Field name="buyer_code" type="string" required="false">
                    Mã khách hàng (mã người mua hàng)
                  </Field>
                  <Field name="national_id" type="string" required="false">
                    Căn cước công dân / Số CCCD / Số định danh cá nhân
                  </Field>
                </Fields>
              </Field>
              <Field name="total_before_tax" type="number" required="false">
                Tổng tiền trước thuế
              </Field>
              <Field name="tax_amount" type="number" required="false">
                Tiền thuế
              </Field>
              <Field name="total_amount" type="number" required="false">
                Tổng thanh toán
              </Field>
              <Field name="notes" type="string" required="false">
                Ghi chú hóa đơn
              </Field>
              <Field name="source" type="enum: manual, api" required="false">
                Nguồn tạo hóa đơn (`manual` = tạo trên giao diện, `api` = tạo qua API)
              </Field>
            </Fields>
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "Thiếu hoặc sai tracking_code." },
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 404, name: "Not Found", description: "Không tìm thấy yêu cầu phát hành theo tracking_code." }
]}
/>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/issue/check/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Tùy vào kết quả trạng thái:

Nếu `status` là `Success`:

1. **[Tải hóa đơn](/vi/einvoice-api/v1/tai-hoa-don)** - Tải file PDF hoặc XML của hóa đơn đã phát hành
2. **[Chi tiết hóa đơn](/vi/einvoice-api/v1/chi-tiet-hoa-don)** - Xem thông tin chi tiết hóa đơn (số hóa đơn, ngày phát hành, URL file...)
3. **[Danh sách hóa đơn](/vi/einvoice-api/v1/danh-sach-hoa-don)** - Quản lý và tra cứu các hóa đơn đã phát hành

Nếu `status` là `Failed`:

- Kiểm tra `message` để biết nguyên nhân lỗi, sửa thông tin và thử **[phát hành lại](/vi/einvoice-api/v1/phat-hanh-hoa-don-dien-tu)** hoặc liên hệ SePay để được hỗ trợ

# API lấy danh sách hóa đơn

## Tra cứu danh sách hóa đơn điện tử qua SePay E-Invoice API với phân trang. Trả về thông tin hóa đơn bao gồm trạng thái, số tiền và ngày phát hành.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices</Path>

  <Description>
    Danh sách hóa đơn
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <QueryParams>
    <Param name="page" type="integer" required="false">
      Trang hiện tại (mặc định 1)
    </Param>
    <Param name="per_page" type="integer" required="false">
      Số bản ghi mỗi trang (mặc định 10)
    </Param>
    <Param name="source" type="enum: manual, api" required="false">
      Lọc hóa đơn theo nguồn tạo. Nếu không truyền sẽ trả về tất cả.
- `manual`: Chỉ lấy hóa đơn tạo thủ công trên giao diện
- `api`: Chỉ lấy hóa đơn tạo qua API

    </Param>

  </QueryParams>

</Params>

<Callout type="info" title="Phân trang">
Sử dụng 
`page`
 để chỉ định trang cần lấy (mặc định là 1).
Sử dụng 
`per_page`
 để giới hạn số bản ghi mỗi trang (mặc định là 10, tối đa 100).
Response trả về 
`has_more: true`
 nếu còn dữ liệu ở trang tiếp theo.
</Callout>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Danh sách hóa đơn
    </Description>

    <Example>
      {
        "data": {
          "paging": {
            "per_page": 1,
            "total": 20,
            "has_more": true,
            "current_page": 1,
            "page_count": 20
          },
          "items": [
            {
              "reference_code": "9735f09d-d970-11f0-aef4-52c7e9b4f41b",
              "invoice_number": "0",
              "issued_date": "2025-12-15",
              "pdf_url": "https://beta-portalv2.mifi.vn/DownloadPDFCA.aspx?...",
              "xml_url": null,
              "status": "draft",
              "buyer": {
                "name": "Công ty ABC",
                "tax_code": "0101234567",
                "address": "123 Đường A, Quận B, Hà Nội",
                "email": "buyer@example.com",
                "phone": "0900000000"
              },
              "total_before_tax": 200000,
              "tax_amount": 20000,
              "total_amount": 220000,
              "notes": "Ghi chú hóa đơn",
              "source": "api"
            }
          ]
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="paging" type="object" required="false">
            <Fields>
              <Field name="per_page" type="integer" required="false">
                Số bản ghi mỗi trang
              </Field>
              <Field name="total" type="integer" required="false">
                Tổng số bản ghi
              </Field>
              <Field name="has_more" type="boolean" required="false">
                Còn dữ liệu ở trang tiếp theo hay không
              </Field>
              <Field name="current_page" type="integer" required="false">
                Trang hiện tại
              </Field>
              <Field name="page_count" type="integer" required="false">
                Tổng số trang
              </Field>
            </Fields>
          </Field>
          <Field name="items" type="array" required="false">
            <ArrayItems>
              <Fields>
                <Field name="reference_code" type="string" required="false">
                  Mã tham chiếu hóa đơn
                </Field>
                <Field name="invoice_number" type="string" required="false">
                  Số hóa đơn (0 nếu là nháp)
                </Field>
                <Field name="issued_date" type="string" required="false">
                  Ngày phát hành (yyyy-MM-dd)
                </Field>
                <Field name="pdf_url" type="string" required="false">
                  Link tải PDF
                </Field>
                <Field name="xml_url" type="string" required="false">
                  Link tải XML (nếu có)
                </Field>
                <Field name="status" type="enum: draft, issued, cancelled" required="false">
                  Trạng thái hóa đơn (draft, issued...)
                </Field>
                <Field name="buyer" type="object" required="false">
                  <Fields>
                    <Field name="type" type="enum: personal, company" required="false">
                      Loại người mua (personal, company)
                    </Field>
                    <Field name="name" type="string" required="false">
                      Tên người/đơn vị mua
                    </Field>
                    <Field name="legal_name" type="string" required="false">
                      Tên pháp lý (dùng khi buyer.type là company)
                    </Field>
                    <Field name="tax_code" type="string" required="false">
                      Mã số thuế
                    </Field>
                    <Field name="address" type="string" required="false">
                      Địa chỉ
                    </Field>
                    <Field name="email" type="string (email)" required="false">
                      Email nhận hóa đơn
                    </Field>
                    <Field name="phone" type="string" required="false">
                      Số điện thoại
                    </Field>
                    <Field name="buyer_code" type="string" required="false">
                      Mã khách hàng (mã người mua hàng)
                    </Field>
                    <Field name="national_id" type="string" required="false">
                      Căn cước công dân / Số CCCD / Số định danh cá nhân
                    </Field>
                  </Fields>
                </Field>
                <Field name="total_before_tax" type="number" required="false">
                  Tổng tiền trước thuế
                </Field>
                <Field name="tax_amount" type="number" required="false">
                  Tiền thuế
                </Field>
                <Field name="total_amount" type="number" required="false">
                  Tổng thanh toán
                </Field>
                <Field name="notes" type="string" required="false">
                  Ghi chú hóa đơn
                </Field>
                <Field name="source" type="enum: manual, api" required="false">
                  Nguồn tạo hóa đơn (`manual` = tạo trên giao diện, `api` = tạo qua API)
                </Field>
              </Fields>
            </ArrayItems>
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

<Callout type="warning" title="Lưu ý về invoice_number">
`invoice_number`
 mặc định là 
`"0"`
 khi hóa đơn ở trạng thái nháp (
`"status": "draft"`
). Sau khi phát hành thành công, 
`invoice_number`
 sẽ được cập nhật thành số hóa đơn thực tế do nhà cung cấp cấp phát.
</Callout>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token. Vui lòng kiểm tra lại token trong header Authorization." }
]}
/>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url 'https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual' \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/invoices?page=1&per_page=10&source=manual", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices?page=1&per_page=10&source=manual",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices?page=1&per_page=10&source=manual")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi có danh sách hóa đơn, bạn có thể:

1. **[Chi tiết hóa đơn](/vi/einvoice-api/v1/chi-tiet-hoa-don)** - Sử dụng `reference_code` để xem thông tin chi tiết một hóa đơn cụ thể
2. **[Tải hóa đơn](/vi/einvoice-api/v1/tai-hoa-don)** - Tải file PDF hoặc XML của hóa đơn đã phát hành

<Callout type="info" title="Với hóa đơn nháp">
Nếu hóa đơn có 
`status: "draft"`
, bạn có thể 
Phát hành hóa đơn
 để phát hành chính thức.
</Callout>

# API lấy chi tiết hóa đơn

## Lấy thông tin chi tiết hóa đơn điện tử theo mã tham chiếu qua SePay E-Invoice API. Trả về thông tin người mua, danh mục hàng, thuế và trạng thái hóa đơn.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/{reference_code}</Path>

  <Description>
    Chi tiết hóa đơn
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <PathParams>
    <Param name="reference_code" type="string" required="true">
      Mã tham chiếu hóa đơn
    </Param>
  </PathParams>

</Params>

<Callout type="info" title="Lấy reference_code từ đâu?">
`reference_code`
 là mã tham chiếu duy nhất của hóa đơn, bạn có thể lấy từ:
API Xuất hóa đơn
 - Trả về trong response khi kiểm tra trạng thái xuất hóa đơn (
`/v1/invoices/create/check/{tracking_code}`
)
API Phát hành hóa đơn
 - Trả về trong response khi kiểm tra trạng thái phát hành (
`/v1/invoices/issue/check/{tracking_code}`
)
API Danh sách hóa đơn
 - Mỗi hóa đơn trong danh sách đều có 
`reference_code`
 (
`/v1/invoices`
)
</Callout>

## API Response

<Responses>
  <Response status="200">
    <Description>
      Chi tiết hóa đơn
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "reference_code": "084e179d-d95a-11f0-aef4-52c7e9b4f41b",
          "invoice_number": "589",
          "issued_date": "2025-12-15",
          "pdf_url": "https://beta-portalv2.mifi.vn/DownloadPDFCA.aspx?...",
          "xml_url": null,
          "status": "issued",
          "buyer": {
            "name": "Công ty ABC",
            "tax_code": "0101234567",
            "address": "123 Đường A, Quận B, Hà Nội",
            "email": "buyer@example.com",
            "phone": "0900000000"
          },
          "total_before_tax": 200000,
          "tax_amount": 20000,
          "total_amount": 220000,
          "notes": "Ghi chú hóa đơn",
          "source": "api",
          "items": [
            {
              "line_number": 1,
              "line_type": 1,
              "item_code": "SP001",
              "item_name": "Sản phẩm A",
              "unit": "cái",
              "quantity": "2.00",
              "unit_price": "100000.00",
              "total_amount": "200000.00",
              "tax_rate": "10.00",
              "tax_amount": "20000.00"
            }
          ]
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="reference_code" type="string" required="false">
            Mã tham chiếu hóa đơn
          </Field>
          <Field name="invoice_number" type="string" required="false">
            Số hóa đơn
          </Field>
          <Field name="invoice_series" type="string" required="false">
            Ký hiệu hóa đơn (ví dụ "AA/24E"). Tiền tố theo mẫu hóa đơn.
          </Field>
          <Field name="document_type" type="integer" required="false">
            Loại chứng từ hóa đơn. Giá trị enum:
- `1` - Hóa đơn nháp
- `2` - Hóa đơn mới
- `3` - Hóa đơn đã hủy
- `4` - Hóa đơn thay thế
- `5` - Hóa đơn bị thay thế
- `6` - Hóa đơn điều chỉnh tăng
- `7` - Hóa đơn điều chỉnh giảm
- `8` - Hóa đơn điều chỉnh thông tin
- `9` - Hóa đơn điều chỉnh tăng/giảm
- `10` - Hóa đơn bị điều chỉnh

          </Field>
          <Field name="issued_date" type="string" required="false">
            Ngày phát hành hóa đơn
          </Field>
          <Field name="pdf_url" type="string" required="false">
            Link tải PDF
          </Field>
          <Field name="xml_url" type="string" required="false">
            Link tải XML (nếu có)
          </Field>
          <Field name="status" type="enum: draft, issued, cancelled" required="false">
            Trạng thái hóa đơn
          </Field>
          <Field name="tax_authority_code" type="string" required="false">
            Mã cơ quan thuế. Có giá trị khi hóa đơn đã được đăng ký với cơ quan thuế Việt Nam.
          </Field>
          <Field name="provider_status" type="string" required="false">
            Trạng thái xử lý từ nhà cung cấp hóa đơn điện tử. Khác với trạng thái nội bộ SePay (`status`). Giá trị enum:

- `1` - Nháp
- `2` - Lỗi ký
- `3` - Chưa gửi CQT
- `4` - Đã cấp mã/tiếp nhận
- `5` - CQT chưa phản hồi
- `6` - Không đủ ĐK cấp mã
- `7` - [04/SS] Chưa tạo tờ khai
- `8` - [04/SS] CQT chưa tiếp nhận
- `9` - [04/SS] CQT đã phê duyệt

          </Field>
          <Field name="payment_method" type="string" required="false">
            Phương thức thanh toán của hóa đơn (ví dụ "TM/CK").
          </Field>
          <Field name="buyer" type="object" required="false">
            <Fields>
              <Field name="type" type="enum: personal, company" required="false">
                Loại người mua (personal, company)
              </Field>
              <Field name="name" type="string" required="false">
                Tên người/đơn vị mua
              </Field>
              <Field name="legal_name" type="string" required="false">
                Tên pháp lý (dùng khi buyer.type là company)
              </Field>
              <Field name="tax_code" type="string" required="false">
                Mã số thuế
              </Field>
              <Field name="address" type="string" required="false">
                Địa chỉ
              </Field>
              <Field name="email" type="string (email)" required="false">
                Email nhận hóa đơn
              </Field>
              <Field name="phone" type="string" required="false">
                Số điện thoại
              </Field>
              <Field name="buyer_code" type="string" required="false">
                Mã khách hàng (mã người mua hàng)
              </Field>
              <Field name="national_id" type="string" required="false">
                Căn cước công dân / Số CCCD / Số định danh cá nhân
              </Field>
            </Fields>
          </Field>
          <Field name="total_before_tax" type="number" required="false">
            Tổng tiền trước thuế
          </Field>
          <Field name="tax_amount" type="number" required="false">
            Tiền thuế
          </Field>
          <Field name="total_amount" type="number" required="false">
            Tổng thanh toán
          </Field>
          <Field name="notes" type="string" required="false">
            Ghi chú hóa đơn
          </Field>
          <Field name="source" type="enum: manual, api" required="false">
            Nguồn tạo hóa đơn (`manual` = tạo trên giao diện, `api` = tạo qua API)
          </Field>
          <Field name="items" type="array" required="false">
            <Description>Danh sách dòng hàng</Description>
            <ArrayItems>
              <Fields>
                <Field name="line_number" type="integer" required="false">
                  Số thứ tự dòng
                </Field>
                <Field name="line_type" type="integer" required="false">
                  Loại hàng hóa
                </Field>
                <Field name="item_code" type="string" required="false">
                  Mã hàng
                </Field>
                <Field name="item_name" type="string" required="false">
                  Tên hàng
                </Field>
                <Field name="unit" type="string" required="false">
                  Đơn vị tính
                </Field>
                <Field name="quantity" type="string" required="false">
                  Số lượng
                </Field>
                <Field name="unit_price" type="string" required="false">
                  Đơn giá
                </Field>
                <Field name="total_amount" type="string" required="false">
                  Thành tiền dòng
                </Field>
                <Field name="tax_rate" type="string" required="false">
                  Thuế suất (%)
                </Field>
                <Field name="tax_amount" type="string" required="false">
                  Tiền thuế dòng
                </Field>
              </Fields>
            </ArrayItems>
          </Field>
        </Fields>
      </Field>

    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token. Kiểm tra lại header Authorization." },
{ code: 404, name: "Not Found", description: "Không tìm thấy hóa đơn theo reference_code. Kiểm tra lại mã tham chiếu." }
]}
/>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client
    
    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")
    
    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }
    
    conn.request("GET", "/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b", headers=headers)
    
    res = conn.getresponse()
    data = res.read()
    
    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");
    
    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };
    
    const req = http.request(options, function (res) {
      const chunks = [];
    
      res.on("data", function (chunk) {
        chunks.push(chunk);
      });
    
      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });
    
    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();
    
    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();
    
    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'
    
    url = URI("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'
    
    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main
    
    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )
    
    func main() {
    
    	url := "https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b"
    
    	req, _ := http.NewRequest("GET", url, nil)
    
    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")
    
    	res, _ := http.DefaultClient.Do(req)
    
    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)
    
    	fmt.Println(res)
    	fmt.Println(string(body))
    
    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation
    
    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })
    
    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()
    
    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()
    
    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi có thông tin chi tiết hóa đơn:

1. **[Tải hóa đơn](/vi/einvoice-api/v1/tai-hoa-don)** - Sử dụng `reference_code` để tải file PDF hoặc XML của hóa đơn
2. **[Danh sách hóa đơn](/vi/einvoice-api/v1/danh-sach-hoa-don)** - Quay lại danh sách để tra cứu các hóa đơn khác

# API tải hóa đơn điện tử

## Tải file hóa đơn điện tử dạng PDF hoặc XML theo mã tracking qua SePay E-Invoice API. Trả về nội dung file dạng base64 để lưu trữ hoặc in ấn.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**

- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`

---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

<Path>https://einvoice-api.sepay.vn/v1/invoices/{tracking_code}/download</Path>

  <Description>
    Tải hóa đơn
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

<Params>
  <PathParams>
    <Param name="tracking_code" type="string" required="true">
      Mã tracking của hóa đơn
    </Param>
  </PathParams>

  <QueryParams>
    <Param name="type" type="enum: pdf, xml" required="true">
      Loại file cần tải (pdf hoặc xml)
    </Param>
  </QueryParams>

</Params>

## API Response

<Responses>
  <Response status="200">
    <Description>
      File hóa đơn (base64 encoded)
    </Description>

    <Example>
      {
        "success": true,
        "data": {
          "file_type": "pdf",
          "file_name": "HD_0000589_20251215.pdf",
          "content": "JVBERi0xLjQKJeLjz9MKMyAwIG9iago8PC9UeXBlL1hPYmplY3Q..."
        }
      }
    </Example>

  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="success" type="boolean" required="false">
      </Field>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="file_type" type="enum: pdf, xml" required="true">
            Loại file được tải (pdf hoặc xml)
          </Field>
          <Field name="file_name" type="string" required="true">
            Tên file gợi ý khi lưu
          </Field>
          <Field name="content" type="string" required="true">
            Nội dung file được mã hóa base64. Cần decode để lưu thành file.
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
hiddenHead={true}
rows={[
{ code: 400, name: "Bad Request", description: "Tham số type không hợp lệ (không phải pdf hoặc xml)." },
{ code: 401, name: "Unauthorized", description: "Thiếu hoặc sai Bearer token." },
{ code: 404, name: "Not Found", description: "Không tìm thấy hóa đơn theo tracking_code." }
]}
/>

## Lưu ý

<Callout type="info" title="Lưu ý">
API trả về nội dung file dạng 
base64
. Bạn cần decode base64 để lưu thành file PDF hoặc XML.
Tham số 
`type`
 chỉ chấp nhận hai giá trị: 
`pdf`
 hoặc 
`xml`
.
Đảm bảo hóa đơn đã được phát hành thành công trước khi tải file.
</Callout>

## Xử lý Base64 thành File

Sau khi gọi API thành công, bạn cần decode nội dung base64 và lưu thành file. Dưới đây là ví dụ với PHP:

<Php title="Decode Base64 và lưu file">
```php
<?php
// Giả sử $response là kết quả từ API
$response = json_decode($apiResult, true);

if ($response['success']) {
// Lấy nội dung base64 từ response
$base64Content = $response['data']['content'];
$fileName = $response['data']['file_name'];

// Decode base64 thành binary
$binaryContent = base64_decode($base64Content);

// Kiểm tra decode thành công
if ($binaryContent === false) {
throw new Exception('Lỗi decode base64');
}

// Lưu file
$bytesWritten = file_put_contents($fileName, $binaryContent);

if ($bytesWritten === false) {
throw new Exception('Lỗi ghi file');
}

echo "Đã lưu file: {$fileName} ({$bytesWritten} bytes)";
}

````
</Php>

**Các bước xử lý:**

1. **Parse JSON response** - Chuyển đổi response thành mảng PHP
2. **Lấy nội dung base64** - Truy cập `$response['data']['content']`
3. **Decode base64** - Sử dụng `base64_decode()` để chuyển thành binary
4. **Lưu file** - Sử dụng `file_put_contents()` để ghi ra file

<Callout type="warning" title="Lưu ý quan trọng">
Luôn kiểm tra kết quả
`base64_decode()`
 vì có thể trả về
`false`
 nếu chuỗi base64 không hợp lệ.
Đảm bảo thư mục lưu file có quyền ghi (write permission).
Với file PDF, có thể kiểm tra header
`%PDF`
 sau khi decode để xác nhận file hợp lệ.
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url 'https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf' \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php

    $curl = curl_init();

    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);

    $response = curl_exec($curl);
    $err = curl_error($curl);

    curl_close($curl);

    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client

    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")

    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }

    conn.request("GET", "/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf", headers=headers)

    res = conn.getresponse()
    data = res.read()

    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");

    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };

    const req = http.request(options, function (res) {
      const chunks = [];

      res.on("data", function (chunk) {
        chunks.push(chunk);
      });

      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });

    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();

    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();

    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'

    url = URI("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'

    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main

    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )

    func main() {

    	url := "https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf"

    	req, _ := http.NewRequest("GET", url, nil)

    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")

    	res, _ := http.DefaultClient.Do(req)

    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)

    	fmt.Println(res)
    	fmt.Println(string(body))

    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation

    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]

    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers

    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })

    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()

    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/invoices/084e179d-d95a-11f0-aef4-52c7e9b4f41b/download?type=pdf")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()

    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi tải hóa đơn thành công:

1. **[Kiểm tra hạn ngạch](/vi/einvoice-api/v1/kiem-tra-han-ngach)** — Kiểm tra số lượng hóa đơn còn lại trong gói dịch vụ để tránh gián đoạn khi xuất hóa đơn tiếp theo
2. **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** — Bắt đầu chu trình mới để xuất hóa đơn cho giao dịch tiếp theo

# API kiểm tra hạn ngạch hóa đơn

## Kiểm tra số lượt phát hành hóa đơn điện tử còn lại trong gói dịch vụ hiện tại qua SePay E-Invoice API trước khi phát hành hóa đơn mới.

---

**API Overview:**

API tạo và quản lý hóa đơn điện tử theo quy định của Tổng cục Thuế Việt Nam.

**Base URLs:**
- Production: `https://einvoice-api.sepay.vn`
- Sandbox: `https://einvoice-api-sandbox.sepay.vn`


---

## API Endpoint

<Endpoint>
  <Method>GET</Method>

  <Path>https://einvoice-api.sepay.vn/v1/usage</Path>

  <Description>
    Kiểm tra hạn ngạch
  </Description>

  <Authentication>
    bearerAuth
  </Authentication>
</Endpoint>

## API Request

Endpoint này không yêu cầu tham số request. Chỉ cần gửi Bearer token trong header để xác thực.

## API Response

<Responses>
  <Response status="200">
    <Description>
      Thông tin hạn ngạch
    </Description>

    <Example>
      {
        "data": {
          "quota_remaining": "534"
        }
      }
    </Example>
  </Response>

</Responses>

<ResponseDescriptionFields>
  <ResponseSchema status="200">
    <Fields>
      <Field name="data" type="object" required="false">
        <Fields>
          <Field name="quota_remaining" type="string" required="true">
            Số lượt thao tác hóa đơn còn lại
          </Field>
        </Fields>
      </Field>
    </Fields>
  </ResponseSchema>

</ResponseDescriptionFields>

## Xử lý lỗi

<ErrorCodes
  hiddenHead={true}
  rows={[
  { code: 401, name: "Unauthorized", description: "Thiếu hoặc token không hợp lệ/đã hết hạn." }
]}
/>

## Lưu ý

<Callout type="info" title="Về giá trị quota_remaining">
quota_remaining
 là số lượt phát hành hóa đơn còn lại trong gói dịch vụ hiện tại
Giá trị được cập nhật theo thời gian thực sau mỗi lần phát hành hóa đơn thành công
</Callout>

<Callout type="success" title="Hóa đơn nháp không tính vào hạn ngạch">
Khi xuất hóa đơn với
`is_draft: true`
, hệ thống sẽ không trừ hạn ngạch. Hạn ngạch chỉ bị trừ khi hóa đơn được
phát hành chính thức
 (gọi API phát hành hoặc xuất với
`is_draft: false`
).
</Callout>

## Code mẫu

<CodeSamples>
  <CodeSamplesList>
    <CodeSamplesTrigger value="shell_curl">
      cURL
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="php_curl">
      PHP
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="python_python3">
      Python
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="node_native">
      NodeJS
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="java_okhttp">
      Java
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="ruby_native">
      Ruby
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="go_native">
      Go
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="csharp_httpclient">
      .NET
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="swift_nsurlsession">
      Swift
    </CodeSamplesTrigger>

    <CodeSamplesTrigger value="kotlin_okhttp">
      Kotlin
    </CodeSamplesTrigger>

  </CodeSamplesList>

  <CodeSample value="shell_curl" lang="bash">
    ```bash
    curl --request GET \
      --url https://einvoice-api.sepay.vn/v1/usage \
      --header 'Authorization: Bearer REPLACE_BEARER_TOKEN'
    ```
  </CodeSample>

  <CodeSample value="php_curl" lang="php">
    ```php
    <?php

    $curl = curl_init();

    curl_setopt_array($curl, [
      CURLOPT_URL => "https://einvoice-api.sepay.vn/v1/usage",
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => "",
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 30,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => "GET",
      CURLOPT_HTTPHEADER => [
        "Authorization: Bearer REPLACE_BEARER_TOKEN"
      ],
    ]);

    $response = curl_exec($curl);
    $err = curl_error($curl);

    curl_close($curl);

    if ($err) {
      echo "cURL Error #:" . $err;
    } else {
      echo $response;
    }
    ```
  </CodeSample>

  <CodeSample value="python_python3" lang="python">
    ```python
    import http.client

    conn = http.client.HTTPSConnection("einvoice-api.sepay.vn")

    headers = { 'Authorization': "Bearer REPLACE_BEARER_TOKEN" }

    conn.request("GET", "/v1/usage", headers=headers)

    res = conn.getresponse()
    data = res.read()

    print(data.decode("utf-8"))
    ```
  </CodeSample>

  <CodeSample value="node_native" lang="javascript">
    ```javascript
    const http = require("https");

    const options = {
      "method": "GET",
      "hostname": "einvoice-api.sepay.vn",
      "port": null,
      "path": "/v1/usage",
      "headers": {
        "Authorization": "Bearer REPLACE_BEARER_TOKEN"
      }
    };

    const req = http.request(options, function (res) {
      const chunks = [];

      res.on("data", function (chunk) {
        chunks.push(chunk);
      });

      res.on("end", function () {
        const body = Buffer.concat(chunks);
        console.log(body.toString());
      });
    });

    req.end();
    ```
  </CodeSample>

  <CodeSample value="java_okhttp" lang="java">
    ```java
    OkHttpClient client = new OkHttpClient();

    Request request = new Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/usage")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build();

    Response response = client.newCall(request).execute();
    ```
  </CodeSample>

  <CodeSample value="ruby_native" lang="ruby">
    ```ruby
    require 'uri'
    require 'net/http'
    require 'openssl'

    url = URI("https://einvoice-api.sepay.vn/v1/usage")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["Authorization"] = 'Bearer REPLACE_BEARER_TOKEN'

    response = http.request(request)
    puts response.read_body
    ```
  </CodeSample>

  <CodeSample value="go_native" lang="go">
    ```go
    package main

    import (
    	"fmt"
    	"net/http"
    	"io/ioutil"
    )

    func main() {

    	url := "https://einvoice-api.sepay.vn/v1/usage"

    	req, _ := http.NewRequest("GET", url, nil)

    	req.Header.Add("Authorization", "Bearer REPLACE_BEARER_TOKEN")

    	res, _ := http.DefaultClient.Do(req)

    	defer res.Body.Close()
    	body, _ := ioutil.ReadAll(res.Body)

    	fmt.Println(res)
    	fmt.Println(string(body))

    }
    ```
  </CodeSample>

  <CodeSample value="csharp_httpclient" lang="csharp">
    ```csharp
    var client = new HttpClient();
    var request = new HttpRequestMessage
    {
        Method = HttpMethod.Get,
        RequestUri = new Uri("https://einvoice-api.sepay.vn/v1/usage"),
        Headers =
        {
            { "Authorization", "Bearer REPLACE_BEARER_TOKEN" },
        },
    };
    using (var response = await client.SendAsync(request))
    {
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync();
        Console.WriteLine(body);
    }
    ```
  </CodeSample>

  <CodeSample value="swift_nsurlsession" lang="swift">
    ```swift
    import Foundation

    let headers = ["Authorization": "Bearer REPLACE_BEARER_TOKEN"]

    let request = NSMutableURLRequest(url: NSURL(string: "https://einvoice-api.sepay.vn/v1/usage")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers

    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
        print(error)
      } else {
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse)
      }
    })

    dataTask.resume()
    ```
  </CodeSample>

  <CodeSample value="kotlin_okhttp" lang="kotlin">
    ```kotlin
    val client = OkHttpClient()

    val request = Request.Builder()
      .url("https://einvoice-api.sepay.vn/v1/usage")
      .get()
      .addHeader("Authorization", "Bearer REPLACE_BEARER_TOKEN")
      .build()

    val response = client.newCall(request).execute()
    ```
  </CodeSample>

</CodeSamples>

## Bước tiếp theo

Sau khi kiểm tra hạn ngạch:

* Nếu còn hạn ngạch, bạn có thể **[Xuất hóa đơn điện tử](/vi/einvoice-api/v1/xuat-hoa-don-dien-tu)** để tạo hóa đơn mới
* Nếu hết hạn ngạch, vui lòng liên hệ SePay để nâng cấp gói dịch vụ
````
