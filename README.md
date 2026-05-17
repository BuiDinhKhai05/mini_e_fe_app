# Mini E-Commerce Frontend App

Ứng dụng **Mini E-Commerce Frontend** được xây dựng bằng **Flutter**, hỗ trợ chạy trên **Mobile** và **Web**. Dự án phục vụ các chức năng mua bán sản phẩm, quản lý cửa hàng, giỏ hàng, đơn hàng, thanh toán, thông tin cá nhân và quản trị hệ thống.

Ứng dụng hiện hỗ trợ 3 nhóm người dùng chính:

- **USER**: khách hàng mua sản phẩm.
- **SELLER**: người bán, quản lý cửa hàng và sản phẩm.
- **ADMIN**: quản trị viên, duyệt cửa hàng và quản lý người dùng.

---

## Cập nhật giao diện hiện tại

Dự án đã được chỉnh giao diện theo phong cách **Mochi mobile UI**:

- Tông màu hồng nhẹ, trắng, bo góc mềm.
- Các màn hình Auth dùng ảnh minh họa trong `assets/images/mochi/`.
- Home screen có giao diện mobile thân thiện hơn.
- Product detail đã đồng bộ giao diện với Home.
- Popup chọn phân loại sản phẩm được tách theo từng nhóm biến thể như `màu sắc`, `size`.
- Trang chi tiết sản phẩm chỉ hiển thị phân loại để xem; khi bấm **Thêm giỏ** hoặc **Mua ngay** sẽ mở popup chọn biến thể.
- Đã thêm màn hình **đổi mật khẩu**: `change_password_screen.dart`.

---

## Cấu trúc thư mục hiện tại

```txt
mini_e_fe_app/
│   pubspec.yaml
│   README.md
│   .gitignore
│
├── assets/
│   └── images/
│       └── mochi/
│           ├── basket_chick.png
│           ├── bunny_bear_original.png
│           ├── forgot_password_search.png
│           ├── login_bunny_bear.png
│           ├── new_password_lock.png
│           ├── otp_phone.png
│           ├── register_bunny_gift.png
│           ├── restore_bunny_bear.png
│           ├── restore_shield.png
│           ├── restore_success_heart.png
│           └── verify_envelope.png
│
└── lib/
    │   main.dart
    │
    ├── models/
    │       address_model.dart
    │       cart_model.dart
    │       category_model.dart
    │       order_model.dart
    │       product_model.dart
    │       review_model.dart
    │       shop_model.dart
    │       user_model.dart
    │       vietnam_units.dart
    │
    ├── providers/
    │       address_provider.dart
    │       auth_provider.dart
    │       cart_provider.dart
    │       category_provider.dart
    │       order_provider.dart
    │       product_provider.dart
    │       review_provider.dart
    │       shop_provider.dart
    │       user_provider.dart
    │
    ├── screens/
    │   │   home_screen.dart
    │   │   main_tab_container.dart
    │   │   profile_screen.dart
    │   │
    │   ├── address/
    │   │       address_list_screen.dart
    │   │       add_address_screen.dart
    │   │
    │   ├── admins/
    │   │       admin_dashboard_screen.dart
    │   │       admin_home_screen.dart
    │   │       admin_shops_screen.dart
    │   │       admin_shop_approval_screen.dart
    │   │       admin_users_screen.dart
    │   │       admin_user_detail_screen.dart
    │   │
    │   ├── auths/
    │   │       change_password_screen.dart
    │   │       forgot_password_screen.dart
    │   │       login_screen.dart
    │   │       logout_screen.dart
    │   │       register_screen.dart
    │   │       reset_otp_screen.dart
    │   │       verify_account_screen.dart
    │   │
    │   ├── carts/
    │   │       cart_screen.dart
    │   │
    │   ├── oders_payments/
    │   │       checkout_screen.dart
    │   │       my_orders_screen.dart
    │   │       payment_qr_screen.dart
    │   │       payment_result_screen.dart
    │   │
    │   ├── products/
    │   │       add_product_screen.dart
    │   │       add_variant_screen.dart
    │   │       edit_product_screen.dart
    │   │       product_detail_screen.dart
    │   │
    │   ├── shops/
    │   │       seller_product_list_screen.dart
    │   │       shop_detail_screen.dart
    │   │       shop_list_screen.dart
    │   │       shop_management_screen.dart
    │   │       shop_register_screen.dart
    │   │
    │   └── users/
    │           edit_personal_info_screen.dart
    │           personal_info_screen.dart
    │
    ├── service/
    │       address_service.dart
    │       api_client.dart
    │       auth_service.dart
    │       cart_service.dart
    │       category_service.dart
    │       order_service.dart
    │       product_service.dart
    │       review_service.dart
    │       shop_service.dart
    │       user_service.dart
    │
    ├── utils/
    │       app_constants.dart
    │
    └── widgets/
            custom_button.dart
            loading_indicator.dart
            osm_location_picker.dart
            product_card.dart
            review_card.dart
            vietnam_address_selector.dart
```

## Khai báo assets trong `pubspec.yaml`

Để các ảnh trong `assets/images/mochi/` hiển thị đúng, trong `pubspec.yaml` cần có:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/mochi/
```

Sau khi thêm hoặc thay đổi ảnh, chạy lại:

```bash
flutter clean
flutter pub get
flutter run
```

Nếu chạy Flutter Web và bị lỗi kiểu:

```txt
Flutter Web engine failed to fetch "assets/assets/images/mochi/...png"
```

hãy kiểm tra:

- Thư mục `assets` nằm ngang hàng với `lib`, không nằm trong `lib`.
- Đường dẫn trong code là `assets/images/mochi/tên_file.png`.
- `pubspec.yaml` đã khai báo đúng `assets/images/mochi/`.
- Đã tắt app và chạy lại, không chỉ hot reload.

---

## Mapping ảnh Mochi theo màn hình

| Màn hình | Ảnh sử dụng |
|---|---|
| `home_screen.dart` | `basket_chick.png` |
| `login_screen.dart` | `login_bunny_bear.png` |
| `register_screen.dart` | `register_bunny_gift.png` |
| `forgot_password_screen.dart` | `forgot_password_search.png` |
| `reset_otp_screen.dart` | `otp_phone.png` hoặc `new_password_lock.png` |
| `verify_account_screen.dart` | `verify_envelope.png` |
| `logout_screen.dart` | `restore_bunny_bear.png` hoặc `restore_success_heart.png` |
| `change_password_screen.dart` | `new_password_lock.png` |

Ví dụ dùng ảnh trong Flutter:

```dart
Image.asset(
  'assets/images/mochi/login_bunny_bear.png',
)
```

---

## Chi tiết các thư mục chính

### 1. `lib/main.dart`

File khởi tạo chính của app.

Chức năng chính:

- Khởi tạo Flutter binding.
- Khởi tạo `ApiClient`.
- Đăng ký các Provider bằng `MultiProvider`.
- Cấu hình `MaterialApp`.
- Khai báo named routes.
- Điều hướng theo role như `USER`, `SELLER`, `ADMIN`.
- Tải dữ liệu cần thiết sau khi đăng nhập như category tree, product list.

Các nhóm Provider đang dùng:

```dart
AuthProvider
UserProvider
ProductProvider
ShopProvider
CartProvider
AddressProvider
OrderProvider
CategoryProvider
```

---

### 2. `lib/models/`

Chứa các class model dùng để parse dữ liệu từ backend.

| File | Chức năng |
|---|---|
| `address_model.dart` | Model địa chỉ giao hàng. |
| `cart_model.dart` | Model giỏ hàng và sản phẩm trong giỏ. |
| `category_model.dart` | Model danh mục sản phẩm, có thể hỗ trợ cây danh mục cha/con. |
| `order_model.dart` | Model đơn hàng, trạng thái đơn, thanh toán. |
| `product_model.dart` | Model sản phẩm, ảnh, option schema và variants. |
| `review_model.dart` | Model đánh giá sản phẩm. |
| `shop_model.dart` | Model cửa hàng. |
| `user_model.dart` | Model người dùng. |
| `vietnam_units.dart` | Dữ liệu tỉnh, quận, phường/xã Việt Nam. |

---

### 3. `lib/providers/`

Quản lý state bằng Provider Pattern.

| File | Chức năng |
|---|---|
| `auth_provider.dart` | Đăng nhập, đăng ký, xác minh OTP, quên mật khẩu, reset mật khẩu, đổi mật khẩu, đăng xuất. |
| `user_provider.dart` | Lấy và cập nhật thông tin user. |
| `product_provider.dart` | Lấy sản phẩm, chi tiết sản phẩm, quản lý sản phẩm và biến thể. |
| `shop_provider.dart` | Đăng ký shop, lấy shop, quản lý shop. |
| `cart_provider.dart` | Lấy giỏ hàng, thêm/xóa/sửa số lượng sản phẩm. |
| `category_provider.dart` | Lấy danh mục và cây danh mục. |
| `order_provider.dart` | Tạo đơn hàng, lấy danh sách đơn hàng. |
| `address_provider.dart` | Quản lý địa chỉ giao hàng. |
| `review_provider.dart` | Quản lý đánh giá sản phẩm. |

Đặc điểm chung:

- Gọi API thông qua các file trong `service/`.
- Quản lý loading, error, dữ liệu local.
- Gọi `notifyListeners()` để cập nhật UI.
- Một số provider có hàm clear cache khi logout hoặc đổi tài khoản.

---

### 4. `lib/screens/`

Chứa toàn bộ giao diện của ứng dụng.

#### 4.1 Màn hình chung

| File | Chức năng |
|---|---|
| `home_screen.dart` | Trang chủ, tìm kiếm sản phẩm, lọc danh mục, hiển thị card sản phẩm, popup chọn phân loại. |
| `main_tab_container.dart` | Container tab chính của app. |
| `profile_screen.dart` | Trang hồ sơ, menu cá nhân, điều hướng đến thông tin cá nhân, đơn hàng, shop, logout. |

#### 4.2 `screens/auths/`

| File | Chức năng |
|---|---|
| `login_screen.dart` | Đăng nhập bằng email và mật khẩu. |
| `register_screen.dart` | Đăng ký tài khoản mới. |
| `forgot_password_screen.dart` | Nhập email để lấy OTP quên mật khẩu. |
| `reset_otp_screen.dart` | Nhập OTP và mật khẩu mới. |
| `verify_account_screen.dart` | Xác minh tài khoản bằng OTP. |
| `logout_screen.dart` | Xác nhận đăng xuất. |
| `change_password_screen.dart` | Đổi mật khẩu cho user đang đăng nhập. |

#### 4.3 `screens/products/`

| File | Chức năng |
|---|---|
| `add_product_screen.dart` | Seller thêm sản phẩm mới. |
| `edit_product_screen.dart` | Seller chỉnh sửa sản phẩm. |
| `add_variant_screen.dart` | Seller thêm biến thể sản phẩm như màu, size. |
| `product_detail_screen.dart` | Xem chi tiết sản phẩm, gallery ảnh, mô tả, phân loại, thêm giỏ/mua ngay. |

Ghi chú giao diện sản phẩm:

- Phân loại trong trang chi tiết chỉ để xem.
- Khi bấm **Thêm giỏ** hoặc **Mua ngay**, app mở popup chọn biến thể giống Home.
- Popup chia biến thể theo từng nhóm cụ thể, ví dụ `màu sắc`, `size`.

#### 4.4 `screens/shops/`

| File | Chức năng |
|---|---|
| `shop_register_screen.dart` | Đăng ký mở cửa hàng. |
| `shop_management_screen.dart` | Quản lý cửa hàng của seller. |
| `seller_product_list_screen.dart` | Danh sách sản phẩm của seller. |
| `shop_list_screen.dart` | Danh sách cửa hàng cho khách xem. |
| `shop_detail_screen.dart` | Chi tiết cửa hàng và sản phẩm trong shop. |

#### 4.5 `screens/carts/`

| File | Chức năng |
|---|---|
| `cart_screen.dart` | Hiển thị giỏ hàng, chỉnh số lượng, xóa sản phẩm, chuyển checkout. |

#### 4.6 `screens/oders_payments/`

| File | Chức năng |
|---|---|
| `checkout_screen.dart` | Kiểm tra đơn hàng trước khi đặt hàng/thanh toán. |
| `my_orders_screen.dart` | Danh sách đơn hàng của người dùng. |
| `payment_qr_screen.dart` | Hiển thị mã QR/thông tin thanh toán. |
| `payment_result_screen.dart` | Hiển thị kết quả thanh toán. |

#### 4.7 `screens/address/`

| File | Chức năng |
|---|---|
| `address_list_screen.dart` | Danh sách địa chỉ giao hàng. |
| `add_address_screen.dart` | Thêm hoặc sửa địa chỉ giao hàng. |

#### 4.8 `screens/users/`

| File | Chức năng |
|---|---|
| `personal_info_screen.dart` | Xem thông tin cá nhân. |
| `edit_personal_info_screen.dart` | Chỉnh sửa thông tin cá nhân. |

#### 4.9 `screens/admins/`

| File | Chức năng |
|---|---|
| `admin_home_screen.dart` | Trang chủ admin. |
| `admin_dashboard_screen.dart` | Dashboard thống kê. |
| `admin_shops_screen.dart` | Quản lý danh sách shop. |
| `admin_shop_approval_screen.dart` | Phê duyệt cửa hàng. |
| `admin_users_screen.dart` | Quản lý người dùng. |
| `admin_user_detail_screen.dart` | Chi tiết người dùng. |

---

### 5. `lib/service/`

Chứa lớp gọi API backend.

| File | Chức năng |
|---|---|
| `api_client.dart` | Cấu hình Dio, base URL, interceptor, token. |
| `auth_service.dart` | API auth: login, register, verify, forgot/reset password, logout, change password. |
| `user_service.dart` | API user: lấy/cập nhật thông tin người dùng. |
| `product_service.dart` | API sản phẩm và variants. |
| `shop_service.dart` | API cửa hàng. |
| `cart_service.dart` | API giỏ hàng. |
| `category_service.dart` | API danh mục. |
| `order_service.dart` | API đơn hàng. |
| `address_service.dart` | API địa chỉ. |
| `review_service.dart` | API đánh giá. |

---

### 6. `lib/utils/`

| File | Chức năng |
|---|---|
| `app_constants.dart` | Khai báo base URL và endpoint API. |

Ví dụ:

```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:3000/api';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  // Nếu backend đã có API đổi mật khẩu riêng:
  static const String changePasswordEndpoint = '/users/me/change-password';
}
```

Khi chạy Android Emulator, `localhost` của máy thật thường cần đổi thành:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

---

### 7. `lib/widgets/`

| File | Chức năng |
|---|---|
| `custom_button.dart` | Button tái sử dụng. |
| `loading_indicator.dart` | Loading spinner hoặc loading widget. |
| `osm_location_picker.dart` | Chọn vị trí trên bản đồ OpenStreetMap. |
| `product_card.dart` | Card sản phẩm dùng lại trong danh sách. |
| `review_card.dart` | Card hiển thị đánh giá. |
| `vietnam_address_selector.dart` | Chọn tỉnh/quận/phường Việt Nam. |

---

## Luồng chức năng chính

### 1. Đăng ký và xác minh tài khoản

```txt
RegisterScreen
→ AuthProvider.register()
→ AuthService.register()
→ Backend tạo tài khoản
→ VerifyAccountScreen
→ AuthProvider.verifyAccount()
→ Vào Home/Admin tùy role
```

### 2. Đăng nhập

```txt
LoginScreen
→ AuthProvider.login()
→ AuthService.login()
→ Lưu access_token vào SharedPreferences
→ Load dữ liệu session
→ Điều hướng theo role
```

### 3. Quên mật khẩu

```txt
ForgotPasswordScreen
→ AuthProvider.forgotPassword(email)
→ Backend gửi OTP
→ ResetOtpScreen
→ AuthProvider.resetPassword(otp, password, confirmPassword)
→ Quay về LoginScreen
```

### 4. Đổi mật khẩu

```txt
ChangePasswordScreen
→ AuthProvider.changePassword(currentPassword, newPassword, confirmPassword)
→ AuthService.changePassword(...)
→ Backend đổi mật khẩu
→ Thông báo thành công
```

Khuyến nghị backend nên có API riêng:

```txt
PATCH /users/me/change-password
```

Backend nên lấy user từ access token và kiểm tra `currentPassword` trước khi đổi sang `newPassword`.

### 5. Xem và mua sản phẩm

```txt
HomeScreen
→ ProductProvider.fetchPublicProducts()
→ CategoryProvider.fetchTree()
→ Chọn sản phẩm
→ ProductDetailScreen
→ Bấm Thêm giỏ/Mua ngay
→ Popup chọn variant
→ CartProvider.addToCart()
→ CartScreen/CheckoutScreen
```

### 6. Seller quản lý sản phẩm

```txt
ShopManagementScreen
→ SellerProductListScreen
→ AddProductScreen/EditProductScreen
→ AddVariantScreen
→ ProductProvider gọi API sản phẩm
```

### 7. Đặt hàng và thanh toán

```txt
CartScreen
→ CheckoutScreen
→ OrderProvider.createOrder()
→ PaymentQrScreen
→ PaymentResultScreen
→ MyOrdersScreen
```

---

## Công nghệ sử dụng

| Công nghệ/Thư viện | Mục đích |
|---|---|
| Flutter | Framework chính để xây app mobile/web. |
| Dart | Ngôn ngữ lập trình. |
| Provider | State management. |
| Dio | Gọi API backend. |
| SharedPreferences | Lưu token/local data đơn giản. |
| CachedNetworkImage | Hiển thị và cache ảnh từ URL. |
| ImagePicker | Chọn ảnh từ thiết bị. |
| Flutter Map / OSM | Chọn vị trí bản đồ. |
| Intl | Định dạng ngày tháng, tiền tệ. |

---

## Hướng dẫn chạy project

### 1. Cài dependency

```bash
flutter pub get
```

### 2. Kiểm tra môi trường

```bash
flutter doctor
```

### 3. Cấu hình backend URL

Mở file:

```txt
lib/utils/app_constants.dart
```

Cấu hình theo môi trường:

```dart
// Web hoặc desktop local
static const String baseUrl = 'http://localhost:3000/api';

// Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Điện thoại thật cùng mạng Wi-Fi
static const String baseUrl = 'http://192.168.x.x:3000/api';
```

### 4. Chạy app

```bash
flutter run
```

Chạy trên Chrome:

```bash
flutter run -d chrome
```

Chạy trên Edge:

```bash
flutter run -d edge
```

---

## Lệnh thường dùng

```bash
# Cài package
flutter pub get

# Dọn build/cache
flutter clean

# Phân tích lỗi Dart/Flutter
flutter analyze

# Format code
flutter format lib/

# Chạy test
flutter test

# Build APK Android
flutter build apk --release

# Build Web
flutter build web --release
```

---

## Git workflow gợi ý

Khi đã sửa giao diện, thêm assets và cập nhật README:

```bash
git status

git add .

git status

git commit -m "Update mobile UI assets and README"

git push origin main
```

Nếu muốn commit theo từng nhóm:

```bash
# Nhóm assets + pubspec + gitignore
git add assets/images/mochi/ pubspec.yaml .gitignore README.md
git commit -m "Add Mochi assets and update project docs"

# Nhóm auth UI
git add lib/screens/auths/ lib/providers/auth_provider.dart lib/service/auth_service.dart lib/utils/app_constants.dart lib/main.dart
git commit -m "Update auth UI and add change password screen"

# Nhóm home/product detail
git add lib/screens/home_screen.dart lib/screens/products/product_detail_screen.dart
git commit -m "Update home and product detail UI"

# Push
git push origin main
```

---

## Lỗi thường gặp

### 1. Ảnh Mochi không hiển thị

Kiểm tra:

```txt
assets/images/mochi/tên_file.png
```

và `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/mochi/
```

Sau đó chạy:

```bash
flutter clean
flutter pub get
flutter run
```

### 2. Không kết nối được backend

Kiểm tra:

- Backend đã chạy chưa.
- `baseUrl` trong `app_constants.dart` đúng chưa.
- Nếu chạy Android Emulator thì không dùng `localhost`, hãy dùng `10.0.2.2`.
- Nếu chạy điện thoại thật thì dùng IP LAN của máy chạy backend.

### 3. Lỗi quyền khi đổi mật khẩu

Nếu FE gọi `PATCH /users/:id` và bị lỗi không có quyền, nên tạo API riêng ở backend:

```txt
PATCH /users/me/change-password
```

Sau đó FE gọi endpoint này bằng access token, không truyền `userId` từ client.

### 4. Folder `oders_payments`

Tên folder hiện tại đang là:

```txt
lib/screens/oders_payments/
```

Nếu đổi tên thành `orders_payments`, cần sửa tất cả import trong `main.dart` và các file liên quan.

---

## Ghi chú quan trọng

- Không đưa `assets/` vào `.gitignore`, vì ảnh Mochi cần được commit lên GitHub.
- Không đưa `.env`, key, certificate, keystore thật lên GitHub.
- `build/`, `.dart_tool/`, `.idea/`, `.vscode/` không cần commit.
- `pubspec.yaml` phải commit sau khi thêm assets.
- Nếu sửa `pubspec.yaml`, nên chạy lại `flutter pub get`.

---

## Cập nhật lần cuối

18/05/2026
