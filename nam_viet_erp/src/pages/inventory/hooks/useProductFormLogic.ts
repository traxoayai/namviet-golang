// src/pages/inventory/hooks/useProductFormLogic.ts
import { Form, App as AntApp } from "antd";
import { useState, useEffect, useCallback } from "react";
import { useNavigate, useParams, useLocation } from "react-router-dom";

import type { UploadFile, UploadProps } from "antd/es/upload/interface";

import {
  addProduct,
  updateProduct,
  uploadProductImage,
} from "@/features/product/api/productService";
import { useProductStore } from "@/features/product/stores/productStore";
import { supabase } from "@/shared/lib/supabaseClient";

export const useProductFormLogic = () => {
  const [form] = Form.useForm();
  const watchedUnits = Form.useWatch("units", form);
  const navigate = useNavigate();
  const { id } = useParams();
  const location = useLocation();
  const cloneFromId = location.state?.cloneFromId;
  const isEditing = !!id && !cloneFromId;

  const {
    fetchCommonData,
    currentProduct,
    getProductDetails,
    loadingDetails,
    suppliers,
    warehouses,
  } = useProductStore();
  const { message: antMessage } = AntApp.useApp();

  const [loading, setLoading] = useState(false);
  const [isSupplierModalOpen, setIsSupplierModalOpen] = useState(false);
  const [imageUrl, setImageUrl] = useState("");
  const [fileList, setFileList] = useState<UploadFile[]>([]);
  const [galleryFileList, setGalleryFileList] = useState<UploadFile[]>([]); // Thêm gallery
  const [selectedSupplierName, setSelectedSupplierName] = useState("");
  const [isClassifying, setIsClassifying] = useState(false);

  // --- ANCHOR UNIT LOGIC ---
  const findAnchorUnit = useCallback((units: any[]) => {
    if (!units || units.length === 0) return { conversion_rate: 1 };
    const wholesale = units.find((u) => u.unit_type === "wholesale");
    if (wholesale) return wholesale;
    const logistics = units.find((u) => u.unit_type === "logistics");
    if (logistics) return logistics;
    const sorted = [...units].sort((a, b) => (b.conversion_rate || 1) - (a.conversion_rate || 1));
    return sorted[0];
  }, []);

  // --- PRICING RE-CALCULATION ---
  const recalcPrices = useCallback(() => {
    const allValues = form.getFieldsValue();

    // Form field names use camelCase (actualCost, wholesaleMarginValue, etc.)
    const inputCost = parseFloat(allValues.actualCost) || 0;
    const units = allValues.units || [];

    const wholesaleMarginValue = parseFloat(allValues.wholesaleMarginValue) || 0;
    const wholesaleMarginType = (allValues.wholesaleMarginType === 'percent' || allValues.wholesaleMarginType === '%') ? 'percent' : 'amount';

    const retailMarginValue = parseFloat(allValues.retailMarginValue) || 0;
    const retailMarginType = (allValues.retailMarginType === 'percent' || allValues.retailMarginType === '%') ? 'percent' : 'amount';

    const anchorUnit = findAnchorUnit(units);
    const anchorRate = parseFloat(anchorUnit.conversion_rate) || 1;
    
    // Vốn cơ bản (1 Viên)
    const baseCost = inputCost / anchorRate;

    const updatedUnits = units.map((u: any) => {
      const uRate = parseFloat(u.conversion_rate) || 1;
      const uType = u.unit_type || "base";
      let finalPrice = 0;
      const unitCost = baseCost * uRate;

      if (uType === "wholesale" || uType === "logistics") {
        if (wholesaleMarginType === "amount") {
           // Lãi tiền chia nhỏ ra cho từng viên, rồi nhân với số viên của đơn vị
           const profitPerUnit = (wholesaleMarginValue / anchorRate) * uRate;
           finalPrice = unitCost + profitPerUnit;
        } else {
           finalPrice = unitCost * (1 + wholesaleMarginValue / 100);
        }
      } else {
        if (retailMarginType === "amount") {
           const profitPerUnit = (retailMarginValue / anchorRate) * uRate;
           finalPrice = unitCost + profitPerUnit;
        } else {
           finalPrice = unitCost * (1 + retailMarginValue / 100);
        }
      }

      return {
        ...u,
        price: Math.round(finalPrice), 
      };
    });

    form.setFieldsValue({ units: updatedUnits });
  }, [form, findAnchorUnit]);

  // --- INITIALIZATION ---
  useEffect(() => {
    fetchCommonData();
  }, [fetchCommonData]);

  useEffect(() => {
    if (isEditing && id) {
      getProductDetails(Number(id));
    } else if (cloneFromId) {
      getProductDetails(Number(cloneFromId));
    }
  }, [isEditing, id, cloneFromId, getProductDetails]);

  // --- BIND DATA VÀO FORM (CHUẨN HÓA SNAKE_CASE) ---
  useEffect(() => {
    if ((isEditing || cloneFromId) && currentProduct) {
      const initData: any = { ...currentProduct };
      
      const units = currentProduct.units || currentProduct.product_units || [];
      const anchor = findAnchorUnit(units);
      const anchorRate = Number(anchor.conversion_rate) || 1;

      // Quy đổi Giá vốn DB (Base) -> Giao diện (Anchor)
      const rawCost = currentProduct.actual_cost ?? 0;
      const displayCost = Math.round(Number(rawCost) * anchorRate);

      // Ép Type % hay Tiền để UI select đúng (camelCase cho form fields)
      const retailTypeDB = currentProduct.retail_margin_type;
      initData.retailMarginType = (retailTypeDB === '%' || retailTypeDB === 'percent') ? 'percent' : 'amount';
      initData.retailMarginValue = currentProduct.retail_margin_value ?? 0;

      const wholesaleTypeDB = currentProduct.wholesale_margin_type;
      initData.wholesaleMarginType = (wholesaleTypeDB === '%' || wholesaleTypeDB === 'percent') ? 'percent' : 'amount';
      initData.wholesaleMarginValue = currentProduct.wholesale_margin_value ?? 0;

      // Xử lý Inventory
      if (currentProduct.inventorySettings) {
        const newSettings: any = {};
        Object.keys(currentProduct.inventorySettings).forEach((whKey) => {
          const setting = currentProduct.inventorySettings[whKey];
          if (setting) {
            newSettings[whKey] = {
              min: setting.min ? Math.floor(Number(setting.min) / anchorRate) : 0,
              max: setting.max ? Math.floor(Number(setting.max) / anchorRate) : 0,
            };
          }
        });
        initData.inventorySettings = newSettings;
      }

      if (currentProduct.product_units) {
          initData.units = cloneFromId 
            ? currentProduct.product_units.map((u: any) => ({ ...u, id: undefined, product_id: undefined }))
            : currentProduct.product_units;
      }

      if (cloneFromId) {
        delete initData.id;
        initData.sku = ""; // Clear SKU when cloning
        initData.barcode = ""; // Clear barcode when cloning
      }

      form.resetFields();
      
      setTimeout(() => {
          form.setFieldsValue({
              ...initData,
              actualCost: displayCost,
              name: cloneFromId ? `${currentProduct.name} (Bản sao)` : currentProduct.name,
              barcode: initData.barcode,
              sku: initData.sku,
              registration_number: currentProduct.registration_number,
              packing_spec: currentProduct.packing_spec,
          });
      }, 100);

      const distId = currentProduct.distributor ?? currentProduct.distributor_id;
      if (distId) {
        form.setFieldValue("distributor_id", distId);
        const supplier = suppliers.find((s) => s.id === distId);
        if (supplier) setSelectedSupplierName(supplier.name);
      }

      const img = currentProduct.image_url;
      if (img) {
        setImageUrl(img);
        setFileList([{ uid: "-1", name: "image.png", status: "done", url: img }]);
      }

      // Load Product Images Gallery
      if (currentProduct.product_images && Array.isArray(currentProduct.product_images)) {
        const gallery = currentProduct.product_images.map((url: string, index: number) => ({
          uid: `gallery-${index}`,
          name: `gallery-${index}.png`,
          status: "done" as const,
          url: url,
        }));
        setGalleryFileList(gallery);
      }

      const tags = currentProduct.active_ingredient;
      if (tags && !form.getFieldValue("active_ingredient")) {
        form.setFieldsValue({ active_ingredient: tags });
      }

      // Load Auto-classification & active ingredients list
      if (currentProduct.regulatory) {
        form.setFieldsValue({ regulatory: currentProduct.regulatory });
      }
      if (currentProduct.active_ingredients_list) {
        form.setFieldsValue({ active_ingredients_list: currentProduct.active_ingredients_list });
      }
    }
  }, [isEditing, cloneFromId, currentProduct, form, suppliers, findAnchorUnit]);

  const handleModifyCostOrMargin = () => {
    recalcPrices();
  };

  const handleUpload: UploadProps["customRequest"] = async ({ onSuccess }) => {
    if (onSuccess) onSuccess("ok");
  };

  const onUploadChange: UploadProps["onChange"] = ({ fileList: newFileList }) => {
    setFileList(newFileList);
    if (newFileList.length === 0) setImageUrl("");
  };

  const onGalleryUploadChange: UploadProps["onChange"] = ({ fileList: newFileList }) => {
    setGalleryFileList(newFileList);
  };

  const handleImageSearch = () => {
    const productName = form.getFieldValue("name");
    if (!productName) {
      antMessage.warning("Vui lòng nhập Tên sản phẩm trước khi tìm ảnh.");
      return;
    }
    const query = encodeURIComponent(`${productName} product image`);
    window.open(`https://www.google.com/search?tbm=isch&q=${query}`, "_blank");
  };

  const onFinish = async (values: any) => {
    setLoading(true);
    try {
      let finalImageUrl = imageUrl;
      if (fileList.length > 0 && fileList[0].originFileObj) {
        antMessage.loading({ content: "Đang tải ảnh đại diện lên...", key: "upload" });
        finalImageUrl = await uploadProductImage(fileList[0].originFileObj);
        antMessage.success({ content: "Tải ảnh đại diện thành công!", key: "upload" });
      }

      // Upload gallery
      const finalGalleryUrls: string[] = [];
      for (const file of galleryFileList) {
        if (file.originFileObj) {
          antMessage.loading({ content: `Đang tải ảnh ${file.name}...`, key: `upload-${file.uid}` });
          const url = await uploadProductImage(file.originFileObj);
          finalGalleryUrls.push(url);
          antMessage.success({ content: "Tải ảnh thành công!", key: `upload-${file.uid}` });
        } else if (file.url) {
          finalGalleryUrls.push(file.url); // Giữ nguyên url cũ
        }
      }

      // Đưa Giá Hộp về lại Giá Viên trước khi lưu DB
      const inputCost = parseFloat(values.actualCost) || 0;
      const units = values.units || [];
      const anchor = findAnchorUnit(units);
      const anchorRate = anchor.conversion_rate || 1;
      const baseCost = inputCost / anchorRate;

      const fixedUnits = units.map((u: any) => ({
        ...u,
        price: u.price || 0,
      }));

      const finalValues = {
        ...values,
        actual_cost: baseCost,
        image_url: finalImageUrl,
        product_images: finalGalleryUrls,
        units: fixedUnits,
        // Convert camelCase form fields → snake_case DB fields
        retail_margin_type: values.retailMarginType === 'percent' ? '%' : 'amount',
        retail_margin_value: values.retailMarginValue,
        wholesale_margin_type: values.wholesaleMarginType === 'percent' ? '%' : 'amount',
        wholesale_margin_value: values.wholesaleMarginValue,
      };

      const inventoryPayload = warehouses.map((wh) => {
        const settings = values.inventorySettings?.[wh.key] || {};
        return {
          warehouse_id: wh.id,
          min_stock: (settings.min || 0) * anchorRate, 
          max_stock: (settings.max || 0) * anchorRate, 
        };
      });

      let savedId = Number(id);

      if (isEditing) {
        await updateProduct(savedId, finalValues, inventoryPayload);
        antMessage.success(`Cập nhật sản phẩm thành công!`);
      } else {
        const res: any = await addProduct(finalValues, inventoryPayload);
        if (res?.product_id) {
          savedId = Number(res.product_id);
        }
        antMessage.success(`Tạo sản phẩm thành công!`);
      }

      if (savedId) {
        await getProductDetails(savedId);
      }
    } catch (error: any) {
      console.error(error);
      const msg = error.message || error.details || "Không thể lưu sản phẩm";
      antMessage.error(`Lỗi: ${msg}`);
    } finally {
      setLoading(false);
    }
  };

  const currentAnchor = findAnchorUnit(watchedUnits || []);
  const anchorUnitName = currentAnchor?.unit_name || "Base Unit";

  const handleAutoClassify = async () => {
    const productName = form.getFieldValue("name");
    if (!productName) {
      antMessage.warning("Vui lòng nhập Tên thuốc trước khi phân loại.");
      return;
    }
    
    setIsClassifying(true);
    antMessage.loading({ content: "AI đang phân loại và bóc tách hoạt chất...", key: "ai-classify" });
    
    try {
      const { data, error } = await supabase.functions.invoke('classify-drug', {
        body: { product_name: productName }
      });
      
      if (error) throw error;
      if (data) {
        // Map back to form
        const regulatory = {
          item_type: data.item_type || "drug",
          prescription_class: data.prescription_class,
          special_control_type: data.special_control_type,
          is_essential: data.is_essential,
        };
        
        // Cần tra cứu bảng active_ingredients dựa trên tên để lấy ID
        // Nếu không có, tạo mới luôn (Upsert)
        const ingredientsList = data.active_ingredients || [];
        const processedIngredients = [];
        
        for (const ig of ingredientsList) {
           // Tìm ID
           const { data: found } = await (supabase as any)
             .from("active_ingredients")
             .select("id")
             .ilike("name", `%${ig.name}%`)
             .limit(1);
             
           let igId = found?.[0]?.id;
           
           if (!igId) {
             const { data: inserted } = await (supabase as any)
               .from("active_ingredients")
               .insert({
                 name: ig.name,
                 name_intl: ig.name,
                 slug: ig.name.toLowerCase().replace(/ /g, "-"),
                 status: "active"
               })
               .select("id")
               .single();
             igId = inserted?.id;
           }
           
           if (igId) {
             processedIngredients.push({
               active_ingredient_id: igId,
               strength_value: ig.strength_value,
               strength_unit: ig.strength_unit,
               is_primary: ig.is_primary
             });
           }
        }

        form.setFieldsValue({
          regulatory: regulatory,
          active_ingredients_list: processedIngredients,
        });
        
        antMessage.success({ content: `AI xử lý xong: ${data.reason}`, key: "ai-classify", duration: 5 });
      }
    } catch (e: any) {
      console.error(e);
      antMessage.error({ content: `Lỗi AI: ${e.message}`, key: "ai-classify" });
    } finally {
      setIsClassifying(false);
    }
  };

  return {
    form,
    loading,
    loadingDetails,
    isEditing,
    currentProduct,
    imageUrl,
    setImageUrl,
    fileList,
    galleryFileList,
    handleUpload,
    onUploadChange,
    onGalleryUploadChange,
    handleImageSearch,
    isSupplierModalOpen,
    setIsSupplierModalOpen,
    selectedSupplierName,
    setSelectedSupplierName,
    warehouses,
    onFinish,
    handleModifyCostOrMargin,
    navigate,
    anchorUnitName,
    handleAutoClassify,
    isClassifying,
  };
};