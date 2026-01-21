# Grid Balanced Trading V1 - MetaTrader 5

## 📋 Mô tả

**Grid Balanced Trading V1** là phiên bản đầu tiên của Expert Advisor (EA) cho MetaTrader 5 được thiết kế để thực hiện chiến lược giao dịch lưới (Grid Trading) với hệ thống cân bằng lưới tự động. EA tự động đặt các lệnh pending (Buy Limit, Buy Stop, Sell Limit, Sell Stop) tại các mức giá được xác định trước dựa trên khoảng cách lưới.

## 📌 Thông tin phiên bản

- **Tên file**: `GridBalancedTradingV1.mq5`
- **Phiên bản**: 1.00
- **Ngôn ngữ**: MQL5 (MetaTrader 5)
- **Trạng thái**: Phiên bản đầu tiên

## ✨ Tính năng chính

- **Hệ thống lưới tự động**: Tự động tạo và quản lý các lệnh tại các mức giá được tính toán sẵn
- **Cân bằng lưới**: Đảm bảo mỗi mức giá chỉ có tối đa 1 lệnh Buy và 1 lệnh Sell để tránh mất cân bằng
- **Lệnh đa hướng**: Hỗ trợ cả lệnh Buy và Sell đồng thời
- **Tự động bổ sung lệnh**: Tùy chọn tự động tạo lại lệnh khi lệnh cũ bị đóng
- **Quản lý rủi ro**: Hỗ trợ Stop Loss và Take Profit có thể cấu hình
- **Magic Number**: Quản lý lệnh riêng biệt với Magic Number

## 🛠️ Cài đặt

1. Sao chép file `GridBalancedTradingV1.mq5` vào thư mục `MQL5/Experts/` của MetaTrader 5
2. Khởi động lại MetaTrader 5 hoặc làm mới Navigator (F5)
3. Kéo và thả EA vào biểu đồ mong muốn
4. Cấu hình các tham số theo nhu cầu
5. Bật chế độ AutoTrading

## ⚙️ Tham số cấu hình

### Cài đặt lưới

| Tham số | Mô tả | Giá trị mặc định |
|---------|-------|------------------|
| `GridDistancePips` | Khoảng cách giữa các mức giá trong lưới (pips) | 20.0 |
| `MaxGridLevels` | Số lượng mức lưới tối đa mỗi phía (trên và dưới giá cơ sở) | 10 |
| `AutoRefillOrders` | Tự động bổ sung lệnh khi lệnh cũ bị đóng | true |

### Cài đặt lệnh

| Tham số | Mô tả | Giá trị mặc định |
|---------|-------|------------------|
| `LotSize` | Khối lượng giao dịch cho mỗi lệnh | 0.01 |
| `StopLossPips` | Stop Loss tính bằng pips (0 = tắt) | 50.0 |
| `TakeProfitPips` | Take Profit tính bằng pips (0 = tắt) | 30.0 |

### Cài đặt chung

| Tham số | Mô tả | Giá trị mặc định |
|---------|-------|------------------|
| `MagicNumber` | Magic Number để nhận diện lệnh của EA | 123456 |
| `CommentOrder` | Comment được gắn vào mỗi lệnh | "Grid Balanced" |
| `EnableBuyOrders` | Cho phép đặt lệnh Buy | true |
| `EnableSellOrders` | Cho phép đặt lệnh Sell | true |

## 📊 Cách hoạt động

1. **Khởi tạo lưới**: Khi EA được khởi động, nó sẽ:
   - Lấy giá hiện tại (BID) làm giá cơ sở
   - Tạo một mảng các mức giá cố định dựa trên `GridDistancePips` và `MaxGridLevels`
   - Tổng số mức = `MaxGridLevels * 2 + 1` (bao gồm cả trên và dưới giá cơ sở)

2. **Quản lý lệnh**: Trên mỗi tick:
   - EA kiểm tra tất cả các mức giá trong lưới
   - Đối với mỗi mức giá:
     - Nếu mức giá ở **phía trên** giá hiện tại:
       - Đặt lệnh **Buy Stop** (nếu bật Buy)
       - Đặt lệnh **Sell Limit** (nếu bật Sell)
     - Nếu mức giá ở **phía dưới** giá hiện tại:
       - Đặt lệnh **Buy Limit** (nếu bật Buy)
       - Đặt lệnh **Sell Stop** (nếu bật Sell)

3. **Cân bằng lưới**: 
   - EA đảm bảo mỗi mức giá chỉ có tối đa 1 lệnh Buy và 1 lệnh Sell
   - Tránh đặt lệnh trùng lặp tại cùng một mức giá
   - Bỏ qua các mức giá quá gần giá hiện tại (nhỏ hơn 5 pips)

## ⚠️ Cảnh báo rủi ro

- **Giao dịch lưới có rủi ro cao**: Chiến lược này có thể tạo ra nhiều lệnh đồng thời, làm tăng yêu cầu ký quỹ
- **Thị trường trending**: Lưới có thể hoạt động kém hiệu quả trong thị trường có xu hướng mạnh một chiều
- **Yêu cầu ký quỹ**: Đảm bảo tài khoản có đủ ký quỹ để chịu được nhiều lệnh cùng lúc
- **Kiểm thử kỹ**: Luôn test EA trên tài khoản demo trước khi sử dụng trên tài khoản thật
- **Không có đảm bảo lợi nhuận**: Trading luôn có rủi ro, không có chiến lược nào đảm bảo 100% lợi nhuận

## 📝 Lưu ý kỹ thuật

- **File EA**: `GridBalancedTradingV1.mq5`
- EA được viết cho **MetaTrader 5** (MQL5), không tương thích với MT4
- Sử dụng thư viện `Trade.mqh` để thực hiện giao dịch
- Tất cả giá được chuẩn hóa theo số chữ số thập phân của symbol
- EA tự động tính toán chuyển đổi pips sang giá dựa trên symbol

## 🔍 Ví dụ cấu hình

### Cấu hình thận trọng (Conservative)
```
GridDistancePips = 30.0
MaxGridLevels = 5
LotSize = 0.01
StopLossPips = 50.0
TakeProfitPips = 40.0
```

### Cấu hình tích cực (Aggressive)
```
GridDistancePips = 15.0
MaxGridLevels = 15
LotSize = 0.05
StopLossPips = 100.0
TakeProfitPips = 25.0
```

## 📞 Hỗ trợ

Nếu gặp vấn đề hoặc có câu hỏi về **Grid Balanced Trading V1**, vui lòng:
- Kiểm tra log trong tab "Experts" của MetaTrader 5
- Xác nhận file `GridBalancedTradingV1.mq5` đã được compile thành công (không có lỗi trong tab "Errors")
- Đảm bảo AutoTrading đã được bật
- Kiểm tra Magic Number để đảm bảo không trùng với EA khác

## 📜 Giấy phép

EA này được cung cấp "as-is" không có bất kỳ bảo đảm nào. Sử dụng trên trách nhiệm của bạn.

---

**Lưu ý**: Luôn test kỹ trên tài khoản demo trước khi sử dụng thực tế. Giao dịch có rủi ro, có thể dẫn đến mất vốn.
