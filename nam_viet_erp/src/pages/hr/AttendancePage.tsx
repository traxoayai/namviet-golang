import React, { useState } from "react";
import { Layout, Typography, Card, Form, Input, Button, DatePicker, TimePicker, Space, Alert, Modal } from "antd";
import { EnvironmentOutlined } from "@ant-design/icons";
import { useRegisterShift, useCheckIn } from "@/features/hr/hooks/useShifts";

const { Content } = Layout;
const { Title, Text } = Typography;

const AttendancePage: React.FC = () => {
  const [form] = Form.useForm();
  const { mutate: registerShift, isPending: isRegistering } = useRegisterShift();
  const { mutate: checkIn, isPending: isCheckingIn } = useCheckIn();
  
  const [showGeoAlert, setShowGeoAlert] = useState(false);

  const onFinishRegister = (values: any) => {
    registerShift({
      shift_name: values.shift_name,
      date: values.date.format("YYYY-MM-DD"),
      start_time: values.start_time.format("HH:mm:ss"),
      end_time: values.end_time.format("HH:mm:ss"),
    });
  };

  const handleCheckIn = () => {
    if (!navigator.geolocation) {
      Modal.error({
        title: "Lỗi thiết bị",
        content: "Trình duyệt của bạn không hỗ trợ định vị GPS.",
      });
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setShowGeoAlert(false);
        // Giả sử lấy shiftId = 1 để test, thực tế sẽ lấy từ shift hiện tại của user
        checkIn({
          shiftId: 1, 
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        });
      },
      (error) => {
        if (error.code === error.PERMISSION_DENIED) {
          setShowGeoAlert(true);
        } else {
          Modal.error({
            title: "Lỗi định vị",
            content: "Không thể lấy vị trí hiện tại. Vui lòng kiểm tra lại mạng hoặc GPS.",
          });
        }
      },
      { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
    );
  };

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 800, margin: "0 auto", width: "100%" }}>
        <Title level={3}>Chấm công & Ca làm</Title>

        {showGeoAlert && (
          <Alert
            message="Quyền truy cập vị trí bị từ chối"
            description={
              <div>
                <p>Hệ thống không thể lấy vị trí để chấm công. Để tiếp tục, vui lòng:</p>
                <ol>
                  <li>Bấm vào biểu tượng <strong>ổ khóa</strong> trên thanh địa chỉ của trình duyệt.</li>
                  <li>Tìm mục <strong>Vị trí (Location)</strong> và chuyển thành <strong>Cho phép (Allow)</strong>.</li>
                  <li>Tải lại trang (F5) và thử chấm công lại.</li>
                </ol>
              </div>
            }
            type="error"
            showIcon
            closable
            onClose={() => setShowGeoAlert(false)}
            style={{ marginBottom: 24 }}
          />
        )}

        <Card title="Chấm công (Check-in)" style={{ marginBottom: 24 }}>
          <Space direction="vertical" align="center" style={{ width: "100%" }}>
            <Button
              type="primary"
              shape="circle"
              icon={<EnvironmentOutlined />}
              size="large"
              style={{ width: 120, height: 120, fontSize: 32 }}
              onClick={handleCheckIn}
              loading={isCheckingIn}
            />
            <Text type="secondary">Bấm vào đây để chấm công tại vị trí hiện tại</Text>
          </Space>
        </Card>

        <Card title="Đăng ký ca làm mới">
          <Form form={form} layout="vertical" onFinish={onFinishRegister}>
            <Form.Item name="shift_name" label="Tên ca" rules={[{ required: true }]}>
              <Input placeholder="VD: Ca Sáng" />
            </Form.Item>
            <Form.Item name="date" label="Ngày làm việc" rules={[{ required: true }]}>
              <DatePicker style={{ width: "100%" }} format="YYYY-MM-DD" />
            </Form.Item>
            <Space style={{ display: "flex", gap: 16 }}>
              <Form.Item name="start_time" label="Giờ bắt đầu" rules={[{ required: true }]}>
                <TimePicker format="HH:mm:ss" />
              </Form.Item>
              <Form.Item name="end_time" label="Giờ kết thúc" rules={[{ required: true }]}>
                <TimePicker format="HH:mm:ss" />
              </Form.Item>
            </Space>
            <Form.Item>
              <Button type="primary" htmlType="submit" loading={isRegistering}>
                Đăng ký ca
              </Button>
            </Form.Item>
          </Form>
        </Card>
      </Content>
    </Layout>
  );
};

export default AttendancePage;
