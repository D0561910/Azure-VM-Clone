# Azure VM Clone with Terraform

這個 Terraform 配置可以將 Azure VM 從資源群組 A 複製到資源群組 B，包括 OS 磁碟和兩個資料磁碟。

## 功能特色

- 複製 OS 磁碟和兩個資料磁碟
- 從快照創建新的受管磁碟
- 創建完整的網路基礎設施（VNet、Subnet、NSG、Public IP）
- 支援 Rocky Linux 8.10
- 使用 Standard D4 v5 VM 大小
- 自動附加所有磁碟到新的 VM

## 前置需求

1. **Azure CLI** - 已安裝並已登入
2. **Terraform** - 已安裝（版本 >= 1.0）
3. **Azure 訂閱** - 具有適當權限
4. **來源 VM** - 在資源群組 A 中已存在的 VM

## 使用步驟

### 1. 準備配置檔案

```bash
# 複製範例變數檔案
cp terraform.tfvars.example terraform.tfvars

# 編輯變數檔案，填入您的實際值
nano terraform.tfvars
```

### 2. 取得來源磁碟名稱

在 Azure Portal 中：
1. 前往來源 VM
2. 點選「磁碟」
3. 記錄 OS 磁碟和資料磁碟的名稱
4. 將這些名稱填入 `terraform.tfvars` 檔案

### 3. 執行 Terraform

```bash
# 初始化 Terraform
terraform init

# 檢查執行計畫
terraform plan

# 執行部署
terraform apply
```

### 4. 驗證部署

部署完成後，您可以：
1. 在 Azure Portal 中檢查新的資源群組 B
2. 確認新的 VM 已創建並運行
3. 檢查所有磁碟都已正確附加

## 重要配置說明

### 變數說明

| 變數名稱 | 描述 | 範例值 |
|---------|------|--------|
| `source_resource_group` | 來源資源群組名稱 | `"rg-production-a"` |
| `target_resource_group` | 目標資源群組名稱 | `"rg-staging-b"` |
| `location` | Azure 區域 | `"East Asia"` |
| `source_vm_name` | 來源 VM 名稱 | `"vm-web-server"` |
| `target_vm_name` | 目標 VM 名稱 | `"vm-web-server-clone"` |
| `source_os_disk_name` | 來源 OS 磁碟名稱 | `"vm-web-server_OsDisk_1"` |
| `source_data_disk_1_name` | 來源資料磁碟 1 名稱 | `"vm-web-server_DataDisk_0"` |
| `source_data_disk_2_name` | 來源資料磁碟 2 名稱 | `"vm-web-server_DataDisk_1"` |
| `admin_username` | 管理員使用者名稱 | `"azureuser"` |
| `admin_password` | 管理員密碼 | `"P@ssw0rd123!"` |

### 網路配置

- **VNet 地址空間**: 10.0.0.0/16
- **子網路地址空間**: 10.0.2.0/24
- **NSG 規則**: 允許 SSH (Port 22)
- **公用 IP**: 靜態分配

### 磁碟配置

- 所有磁碟都會保持與來源相同的儲存帳戶類型
- 磁碟大小會自動匹配來源磁碟
- 資料磁碟會附加到 LUN 1 和 LUN 2

## 故障排除

### 常見問題

1. **權限錯誤**
   ```
   Error: insufficient privileges to complete the operation
   ```
   確保您的 Azure 帳戶具有以下權限：
   - 在來源資源群組中的讀取權限
   - 在目標資源群組中的貢獻者權限

2. **磁碟名稱錯誤**
   ```
   Error: A resource with the ID "..." was not found
   ```
   檢查 `terraform.tfvars` 中的磁碟名稱是否正確

3. **VM 大小不可用**
   ```
   Error: The requested VM size is not available in the current region
   ```
   確認 Standard_D4_v5 在您選擇的區域中可用

### 清理資源

如果您需要刪除所有創建的資源：

```bash
terraform destroy
```

## 安全考量

1. **密碼安全**: 請使用強密碼並考慮使用 SSH 金鑰驗證
2. **網路安全**: 根據需要調整 NSG 規則
3. **存取控制**: 確保適當的 RBAC 設定

## 自訂選項

您可以根據需要修改以下設定：

- VM 大小（在 `azurerm_linux_virtual_machine` 資源中）
- 網路地址空間
- NSG 規則
- 磁碟快取設定
- 標籤

## 輸出值

部署完成後，Terraform 會輸出：

- `cloned_vm_public_ip`: 複製 VM 的公用 IP 地址
- `cloned_vm_private_ip`: 複製 VM 的私人 IP 地址
- `cloned_vm_id`: 複製 VM 的 Azure 資源 ID
- `resource_group_name`: 目標資源群組名稱

## 支援

如果您遇到問題，請檢查：
1. Azure CLI 是否已正確設定
2. Terraform 版本是否相容
3. Azure 訂閱權限是否足夠
4. 來源資源是否存在且可存取
