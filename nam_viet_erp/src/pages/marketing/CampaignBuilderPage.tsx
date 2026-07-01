import React from "react";
import { Layout, Typography, Card, Form, Input, InputNumber, Button, Select, Space, Divider } from "antd";
import { PlusOutlined, MinusCircleOutlined } from "@ant-design/icons";
import { useCreateCampaign } from "@/features/marketing/hooks/useMarketing";
import { useNavigate } from "react-router-dom";

const { Content } = Layout;
const { Title, Text } = Typography;

const CampaignBuilderPage: React.FC = () => {
  const [form] = Form.useForm();
  const { mutate: createCampaign, isPending } = useCreateCampaign();
  const navigate = useNavigate();

  const onFinish = (values: any) => {
    // Chuyển đổi Form thành flow_config
    const nodes = values.steps?.map((step: any, index: number) => ({
      id: index + 1,
      type: step.action_type,
      config: step.config
    })) || [];

    const flowConfig = JSON.stringify({ nodes, edges: [] });

    createCampaign(
      {
        name: values.name,
        budget: values.budget,
        flow_config: flowConfig,
      },
      {
        onSuccess: () => navigate("/marketing/dashboard"),
      }
    );
  };

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 800, margin: "0 auto", width: "100%" }}>
        <Title level={3}>Tạo Chiến dịch Mới (Campaign Builder)</Title>
        <Card>
          <Form form={form} layout="vertical" onFinish={onFinish} initialValues={{ steps: [{}] }}>
            <Form.Item name="name" label="Tên chiến dịch" rules={[{ required: true }]}>
              <Input placeholder="VD: Khuyến mãi Sinh Nhật Tháng 6" />
            </Form.Item>
            <Form.Item name="budget" label="Ngân sách (VNĐ)" rules={[{ required: true }]}>
              <InputNumber style={{ width: "100%" }} min={0} placeholder="VD: 5000000" />
            </Form.Item>

            <Divider>Luồng thực thi (Flow Config)</Divider>
            <Text type="secondary" style={{ display: "block", marginBottom: 16 }}>
              Cấu hình các bước tự động cho chiến dịch. Backend sẽ đọc cấu hình này để tạo Job.
            </Text>

            <Form.List name="steps">
              {(fields, { add, remove }) => (
                <>
                  {fields.map(({ key, name, ...restField }, index) => (
                    <Card key={key} size="small" style={{ marginBottom: 16, background: "#f2f7fc" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                        <Text strong>Bước {index + 1}</Text>
                        <Button type="text" danger icon={<MinusCircleOutlined />} onClick={() => remove(name)} />
                      </div>
                      <Space style={{ display: "flex", marginTop: 12 }} align="baseline">
                        <Form.Item
                          {...restField}
                          name={[name, "action_type"]}
                          label="Loại Hành động"
                          rules={[{ required: true }]}
                        >
                          <Select style={{ width: 200 }} placeholder="Chọn hành động">
                            <Select.Option value="trigger_date">Trigger theo ngày</Select.Option>
                            <Select.Option value="zalo_zns">Gửi Zalo ZNS</Select.Option>
                            <Select.Option value="email">Gửi Email</Select.Option>
                          </Select>
                        </Form.Item>
                        <Form.Item
                          {...restField}
                          name={[name, "config"]}
                          label="Thông số (Tùy chọn)"
                        >
                          <Input placeholder="VD: template_id=123" style={{ width: 300 }} />
                        </Form.Item>
                      </Space>
                    </Card>
                  ))}
                  <Form.Item>
                    <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                      Thêm bước
                    </Button>
                  </Form.Item>
                </>
              )}
            </Form.List>

            <Form.Item style={{ marginTop: 24 }}>
              <Button type="primary" htmlType="submit" loading={isPending} block size="large">
                Lưu và Tạo Chiến Dịch
              </Button>
            </Form.Item>
          </Form>
        </Card>
      </Content>
    </Layout>
  );
};

export default CampaignBuilderPage;
