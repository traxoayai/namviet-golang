import React, { useState } from "react";
import { Layout, Typography, Card, Table, Button, Form, Input, Modal } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import { useSurveys, useCreateSurvey } from "@/features/marketing/hooks/useMarketing";

const { Content } = Layout;
const { Title } = Typography;

const SurveyPage: React.FC = () => {
  const { data: surveys, isLoading } = useSurveys();
  const { mutate: createSurvey, isPending } = useCreateSurvey();
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  const handleCreate = (values: any) => {
    // Demo: Câu hỏi mặc định dạng JSONB
    const questions = {
      q1: "Bạn đánh giá dịch vụ của chúng tôi thế nào?",
      q2: "Bạn có góp ý gì thêm không?"
    };

    createSurvey(
      {
        title: values.title,
        description: values.description,
        questions: questions
      },
      {
        onSuccess: () => {
          setIsModalVisible(false);
          form.resetFields();
        }
      }
    );
  };

  const columns = [
    { title: "ID", dataIndex: "id" },
    { title: "Tiêu đề", dataIndex: "title" },
    { title: "Mô tả", dataIndex: "description" },
    { title: "Ngày tạo", dataIndex: "created_at" },
  ];

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 1200, margin: "0 auto", width: "100%" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>Quản lý Form Khảo Sát</Title>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setIsModalVisible(true)}>
            Tạo Khảo Sát
          </Button>
        </div>

        <Card>
          <Table
            dataSource={surveys || []}
            columns={columns}
            rowKey="id"
            loading={isLoading}
          />
        </Card>

        <Modal
          title="Tạo Khảo Sát Mới"
          visible={isModalVisible}
          onCancel={() => setIsModalVisible(false)}
          onOk={() => form.submit()}
          confirmLoading={isPending}
        >
          <Form form={form} layout="vertical" onFinish={handleCreate}>
            <Form.Item name="title" label="Tiêu đề" rules={[{ required: true }]}>
              <Input placeholder="VD: Khảo sát mức độ hài lòng" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea placeholder="Mô tả chi tiết khảo sát..." />
            </Form.Item>
          </Form>
        </Modal>
      </Content>
    </Layout>
  );
};

export default SurveyPage;
