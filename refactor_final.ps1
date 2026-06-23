# --- SCRIPT REFACTOR NAM VIET ERP (FSD LITE FINAL) ---

Write-Host "BAT DAU TAI CAU TRUC DU AN..." -ForegroundColor Green

# 1. TAO BO KHUNG THU MUC CHUAN
$features = @("auth", "inventory", "sales", "purchasing", "finance", "marketing", "partners", "crm", "settings")
$subfolders = @("api", "hooks", "stores", "types", "components")

# Tao folder App & Pages (Neu chua co)
New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
New-Item -ItemType Directory -Force -Path "src/pages" | Out-Null

# Tao folder Shared
New-Item -ItemType Directory -Force -Path "src/shared/ui" | Out-Null
New-Item -ItemType Directory -Force -Path "src/shared/lib" | Out-Null
New-Item -ItemType Directory -Force -Path "src/shared/hooks" | Out-Null
New-Item -ItemType Directory -Force -Path "src/shared/utils" | Out-Null
New-Item -ItemType Directory -Force -Path "src/shared/types" | Out-Null
New-Item -ItemType Directory -Force -Path "src/shared/constants" | Out-Null

# Tao folder Features
foreach ($feat in $features) {
    New-Item -ItemType Directory -Force -Path "src/features/$feat" | Out-Null
    foreach ($sub in $subfolders) {
        New-Item -ItemType Directory -Force -Path "src/features/$feat/$sub" | Out-Null
    }
}

# 2. DI CHUYEN: APP & CONFIG
Write-Host "-> Di chuyen App config..." -ForegroundColor Cyan
Move-Item "src/router" "src/app/" -ErrorAction SilentlyContinue
Move-Item "src/contexts" "src/app/" -ErrorAction SilentlyContinue
Move-Item "src/theme.ts" "src/app/" -ErrorAction SilentlyContinue

# 3. DI CHUYEN: SHARED (DUNG CHUNG)
Write-Host "-> Di chuyen Shared..." -ForegroundColor Cyan
# UI Components
Move-Item "src/components/common/*" "src/shared/ui/" -ErrorAction SilentlyContinue
Move-Item "src/components/layouts" "src/shared/" -ErrorAction SilentlyContinue
Move-Item "src/components/shared/listing/*" "src/shared/ui/" -ErrorAction SilentlyContinue
# Libs & Utils & Constants
Move-Item "src/lib/*" "src/shared/lib/" -ErrorAction SilentlyContinue
Move-Item "src/utils/*" "src/shared/utils/" -ErrorAction SilentlyContinue
Move-Item "src/constants/*" "src/shared/constants/" -ErrorAction SilentlyContinue
# Generic Hooks
Move-Item "src/hooks/useDebounce.ts" "src/shared/hooks/" -ErrorAction SilentlyContinue
Move-Item "src/hooks/useCameraScan.ts" "src/shared/hooks/" -ErrorAction SilentlyContinue
Move-Item "src/hooks/useVoiceInput.ts" "src/shared/hooks/" -ErrorAction SilentlyContinue
Move-Item "src/hooks/useListingLogic.ts" "src/shared/hooks/" -ErrorAction SilentlyContinue

# 4. DI CHUYEN: FEATURE INVENTORY (KHO & SAN PHAM)
Write-Host "-> Di chuyen Inventory..." -ForegroundColor Cyan
# API
Move-Item "src/services/productService.ts" "src/features/inventory/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/inventoryService.ts" "src/features/inventory/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/warehouseService.ts" "src/features/inventory/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/storageService.ts" "src/features/inventory/api/" -ErrorAction SilentlyContinue
# Stores
Move-Item "src/stores/productStore.ts" "src/features/inventory/stores/" -ErrorAction SilentlyContinue
Move-Item "src/stores/warehouseStore.ts" "src/features/inventory/stores/" -ErrorAction SilentlyContinue
# Types
Move-Item "src/types/product.ts" "src/features/inventory/types/productTypes.ts" -ErrorAction SilentlyContinue
Move-Item "src/types/warehouse.ts" "src/features/inventory/types/warehouseTypes.ts" -ErrorAction SilentlyContinue
# Hooks (Logic cu)
Move-Item "src/hooks/useWarehouseTools.ts" "src/features/inventory/hooks/" -ErrorAction SilentlyContinue

# 5. DI CHUYEN: FEATURE SALES (BAN HANG & KHACH HANG)
Write-Host "-> Di chuyen Sales..." -ForegroundColor Cyan
# API
Move-Item "src/services/salesService.ts" "src/features/sales/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/b2bService.ts" "src/features/sales/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/customerService.ts" "src/features/sales/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/customerB2BService.ts" "src/features/sales/api/" -ErrorAction SilentlyContinue
# Stores
Move-Item "src/stores/useSalesStore.ts" "src/features/sales/stores/" -ErrorAction SilentlyContinue
Move-Item "src/stores/useCustomerB2BStore.ts" "src/features/sales/stores/" -ErrorAction SilentlyContinue
Move-Item "src/stores/useCustomerB2CStore.ts" "src/features/sales/stores/" -ErrorAction SilentlyContinue
# Types
Move-Item "src/types/customer.ts" "src/features/sales/types/customerTypes.ts" -ErrorAction SilentlyContinue
Move-Item "src/types/customerB2B.ts" "src/features/sales/types/customerB2BTypes.ts" -ErrorAction SilentlyContinue
Move-Item "src/types/b2b*.ts" "src/features/sales/types/" -ErrorAction SilentlyContinue
# Hooks & Components (Tu feature cu)
Move-Item "src/features/b2b/hooks/*" "src/features/sales/hooks/" -ErrorAction SilentlyContinue
Move-Item "src/features/sales-b2b/hooks/*" "src/features/sales/hooks/" -ErrorAction SilentlyContinue
Move-Item "src/features/sales-b2b/create/components/*" "src/features/sales/components/" -ErrorAction SilentlyContinue
# Search UI
Move-Item "src/components/search/CustomerSearchB2B.tsx" "src/features/sales/components/" -ErrorAction SilentlyContinue
Move-Item "src/components/search/ProductSearchB2B.tsx" "src/features/sales/components/" -ErrorAction SilentlyContinue

# 6. DI CHUYEN: FEATURE PURCHASING (MUA HANG & NCC)
Write-Host "-> Di chuyen Purchasing..." -ForegroundColor Cyan
# API
Move-Item "src/services/purchaseOrderService.ts" "src/features/purchasing/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/supplierService.ts" "src/features/purchasing/api/" -ErrorAction SilentlyContinue
# Stores
Move-Item "src/stores/usePurchaseOrderStore.ts" "src/features/purchasing/stores/" -ErrorAction SilentlyContinue
Move-Item "src/stores/supplierStore.ts" "src/features/purchasing/stores/" -ErrorAction SilentlyContinue
# Types
Move-Item "src/types/purchase*.ts" "src/features/purchasing/types/" -ErrorAction SilentlyContinue
Move-Item "src/types/supplier.ts" "src/features/purchasing/types/supplierTypes.ts" -ErrorAction SilentlyContinue
# Components (Tu Pages cu -> tach ra components)
# Note: Doan nay Sep phai tu tach tay vi file dang nam lan trong Pages. Script nay chi chuyen nhung gi dang o folder services/stores.

# 7. DI CHUYEN: FEATURE FINANCE (TAI CHINH)
Write-Host "-> Di chuyen Finance..." -ForegroundColor Cyan
Move-Item "src/services/finance*.ts" "src/features/finance/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/bankService.ts" "src/features/finance/api/" -ErrorAction SilentlyContinue
Move-Item "src/services/invoiceService.ts" "src/features/finance/api/" -ErrorAction SilentlyContinue
Move-Item "src/stores/useFinanceStore.ts" "src/features/finance/stores/" -ErrorAction SilentlyContinue
Move-Item "src/types/finance.ts" "src/features/finance/types/financeTypes.ts" -ErrorAction SilentlyContinue

# 8. DI CHUYEN: FEATURE AUTH (DANG NHAP)
Write-Host "-> Di chuyen Auth..." -ForegroundColor Cyan
Move-Item "src/services/authService.ts" "src/features/auth/api/" -ErrorAction SilentlyContinue
Move-Item "src/stores/authStore.ts" "src/features/auth/stores/" -ErrorAction SilentlyContinue
Move-Item "src/types/auth.ts" "src/features/auth/types/authTypes.ts" -ErrorAction SilentlyContinue
Move-Item "src/types/user.ts" "src/features/auth/types/userTypes.ts" -ErrorAction SilentlyContinue

# 9. DON DEP RAC
Write-Host "-> Don dep..." -ForegroundColor Cyan
Remove-Item "src/components/common" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "src/components/search" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "src/features/b2b" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "src/features/sales-b2b" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "HOAN TAT! Cau truc moi da san sang." -ForegroundColor Green
Write-Host "Buoc tiep theo: Su dung VS Code 'Search & Replace' de sua duong dan Import." -ForegroundColor Yellow