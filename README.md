# Mini E-Commerce Frontend App

Ứng dụng **Mini E-Commerce Frontend** được xây dựng bằng **Flutter** và **Dart**, hỗ trợ chạy trên **Mobile** và **Web**. Dự án phục vụ các chức năng chính của một app thương mại điện tử mini: xem sản phẩm, tìm kiếm, danh mục, giỏ hàng, đặt hàng, thanh toán, đánh giá sản phẩm, quản lý cửa hàng, quản lý đơn của seller, quản lý người dùng và quản trị hệ thống.

Ứng dụng hiện có 3 nhóm người dùng chính:

- **USER**: khách hàng mua sản phẩm, quản lý giỏ hàng, địa chỉ, đơn hàng, đánh giá và thông tin cá nhân.
- **SELLER**: người bán, đăng ký/quản lý cửa hàng, quản lý sản phẩm, biến thể sản phẩm và đơn hàng của shop.
- **ADMIN**: quản trị viên, quản lý người dùng, duyệt cửa hàng và xem các màn hình quản trị.

---

## Trạng thái giao diện và chức năng hiện tại

Dự án đang được tổ chức theo mô hình Flutter kết hợp **Provider Pattern**:

- `models/` định nghĩa dữ liệu nhận/trả với backend.
- `providers/` quản lý state, loading, error và gọi service.
- `service/` tập trung gọi API qua `Dio` và `ApiClient`.
- `screens/` chứa các màn hình theo từng nhóm chức năng.
- `widgets/` chứa các widget tái sử dụng.
- `theme/` chứa cấu hình giao diện chung của app.
- `utils/` chứa hằng số cấu hình, đặc biệt là base URL và endpoint API.

Các chức năng nổi bật hiện có:

- Đăng nhập, đăng ký, xác minh tài khoản, quên mật khẩu, reset OTP, đổi mật khẩu và đăng xuất.
- Trang chủ hiển thị sản phẩm, tìm kiếm/chuyển sang trang danh mục, xem chi tiết sản phẩm.
- Popup chọn biến thể sản phẩm dùng chung qua `product_cart_action_sheet.dart`.
- Giỏ hàng, checkout, thanh toán QR, kết quả thanh toán và danh sách đơn hàng.
- Quản lý địa chỉ giao hàng, chọn địa chỉ Việt Nam và chọn vị trí bằng OpenStreetMap.
- Đánh giá sản phẩm, hiển thị section review trong chi tiết sản phẩm và màn hình xem tất cả đánh giá.
- Quản lý shop cho seller: đăng ký shop, quản lý shop, danh sách sản phẩm, danh sách đơn hàng và chi tiết đơn hàng.
- Quản trị admin: dashboard, quản lý user, chi tiết user, quản lý shop và duyệt shop.
- Giao diện dùng `app_theme.dart`, các widget chung như `custom_button`, `loading_indicator`, `product_card`, `review_card`.

---

## Cấu trúc thư mục hiện tại

```txt
mini_e_fe_app/
│   pubspec.yaml
│   README.md
│   .gitignore
│
├── lib/
│   │   main.dart
│   │
│   ├── models/
│   │       address_model.dart
│   │       cart_model.dart
│   │       category_model.dart
│   │       order_model.dart
│   │       product_model.dart
│   │       review_model.dart
│   │       shop_model.dart
│   │       user_model.dart
│   │       vietnam_units.dart
│   │
│   ├── providers/
│   │       address_provider.dart
│   │       auth_provider.dart
│   │       cart_provider.dart
│   │       category_provider.dart
│   │       order_provider.dart
│   │       product_provider.dart
│   │       review_provider.dart
│   │       shop_provider.dart
│   │       user_provider.dart
│   │
│   ├── screens/
│   │   │   home_screen.dart
│   │   │   profile_screen.dart
│   │   │
│   │   ├── address/
│   │   │       address_list_screen.dart
│   │   │       add_address_screen.dart
│   │   │
│   │   ├── admins/
│   │   │       admin_dashboard_screen.dart
│   │   │       admin_home_screen.dart
│   │   │       admin_shops_screen.dart
│   │   │       admin_shop_approval_screen.dart
│   │   │       admin_users_screen.dart
│   │   │       admin_user_detail_screen.dart
│   │   │
│   │   ├── auths/
│   │   │       change_password_screen.dart
│   │   │       forgot_password_screen.dart
│   │   │       login_screen.dart
│   │   │       logout_screen.dart
│   │   │       register_screen.dart
│   │   │       reset_otp_screen.dart
│   │   │       verify_account_screen.dart
│   │   │
│   │   ├── carts/
│   │   │       cart_screen.dart
│   │   │
│   │   ├── categories/
│   │   │       category_screen.dart
│   │   │
│   │   ├── orders_payments/
│   │   │       checkout_screen.dart
│   │   │       my_orders_screen.dart
│   │   │       payment_qr_screen.dart
│   │   │       payment_result_screen.dart
│   │   │
│   │   ├── products/
│   │   │   │   add_product_screen.dart
│   │   │   │   add_variant_screen.dart
│   │   │   │   edit_product_screen.dart
│   │   │   │   product_detail_screen.dart
│   │   │   │   product_reviews_screen.dart
│   │   │   │
│   │   │   └── widgets/
│   │   │           product_cart_action_sheet.dart
│   │   │           product_review_section.dart
│   │   │
│   │   ├── shops/
│   │   │       seller_order_detail_screen.dart
│   │   │       seller_order_list_screen.dart
│   │   │       seller_product_list_screen.dart
│   │   │       shop_detail_screen.dart
│   │   │       shop_list_screen.dart
│   │   │       shop_management_screen.dart
│   │   │       shop_register_screen.dart
│   │   │
│   │   └── users/
│   │           edit_personal_info_screen.dart
│   │           personal_info_screen.dart
│   │
│   ├── service/
│   │       address_service.dart
│   │       api_client.dart
│   │       auth_service.dart
│   │       cart_service.dart
│   │       category_service.dart
│   │       order_service.dart
│   │       product_service.dart
│   │       review_service.dart
│   │       shop_service.dart
│   │       user_service.dart
│   │
│   ├── theme/
│   │       app_theme.dart
│   │
│   ├── utils/
│   │       app_constants.dart
│   │
│   └── widgets/
│           custom_button.dart
│           loading_indicator.dart
│           osm_location_picker.dart
│           product_card.dart
│           review_card.dart
│           vietnam_address_selector.dart
│
└── assets/
    └── images/
        └── mochi/
            ├── basket_chick.png
            ├── bunny_bear_original.png
            ├── forgot_password_search.png
            ├── login_bunny_bear.png
            ├── new_password_lock.png
            ├── otp_phone.png
            ├── register_bunny_gift.png
            ├── restore_bunny_bear.png
            ├── restore_shield.png
            ├── restore_success_heart.png
            └── verify_envelope.png
```

> Ghi chú: cây thư mục trên đã cập nhật theo trạng thái hiện tại, dùng `orders_payments/`, có `theme/app_theme.dart`, có `categories/category_screen.dart`, có màn hình review sản phẩm và có widget riêng cho popup chọn biến thể sản phẩm.

---

## Chi tiết các thư mục chính

### 1. `lib/main.dart`

File khởi tạo chính của app.

Chức năng chính:

- Khởi tạo Flutter app.
- Khởi tạo `ApiClient`.
- Đăng ký các Provider bằng `MultiProvider`.
- Cấu hình `MaterialApp` và theme.
- Khai báo route hoặc điều hướng giữa các màn hình.
- Điều hướng theo vai trò người dùng như `USER`, `SELLER`, `ADMIN`.
- Load dữ liệu cần thiết sau khi đăng nhập.

Provider chính đang dùng:

```dart
AuthProvider
UserProvider
ProductProvider
ShopProvider
CartProvider
AddressProvider
OrderProvider
CategoryProvider
ReviewProvider
```

---

### 2. `lib/models/`

Chứa các class model dùng để parse dữ liệu từ backend sang object Dart.

| File | Chức năng |
|---|---|
| `address_model.dart` | Model địa chỉ giao hàng. |
| `cart_model.dart` | Model giỏ hàng, item trong giỏ, biến thể được chọn. |
| `category_model.dart` | Model danh mục sản phẩm, hỗ trợ danh mục cha/con. |
| `order_model.dart` | Model đơn hàng, trạng thái đơn hàng, thanh toán. |
| `product_model.dart` | Model sản phẩm, ảnh, biến thể, option schema, giá và tồn kho. |
| `review_model.dart` | Model đánh giá sản phẩm, sao, nội dung, user snapshot nếu backend trả về. |
| `shop_model.dart` | Model cửa hàng, trạng thái shop và thông tin seller. |
| `user_model.dart` | Model người dùng, role, thông tin cá nhân, avatar. |
| `vietnam_units.dart` | Dữ liệu tỉnh/thành, quận/huyện, phường/xã Việt Nam. |

---

### 3. `lib/providers/`

Quản lý state bằng Provider Pattern. Provider là lớp trung gian giữa UI và service.

| File | Chức năng |
|---|---|
| `auth_provider.dart` | Đăng nhập, đăng ký, xác minh OTP, quên mật khẩu, reset mật khẩu, đổi mật khẩu, đăng xuất. |
| `user_provider.dart` | Lấy thông tin cá nhân, cập nhật thông tin user. |
| `product_provider.dart` | Lấy danh sách sản phẩm, chi tiết sản phẩm, sản phẩm seller, thêm/sửa sản phẩm và biến thể. |
| `shop_provider.dart` | Đăng ký shop, lấy shop của seller, cập nhật shop, lấy danh sách shop. |
| `cart_provider.dart` | Lấy giỏ hàng, thêm sản phẩm vào giỏ, cập nhật số lượng, xóa item. |
| `category_provider.dart` | Lấy danh mục, cây danh mục, hỗ trợ lọc/tìm kiếm theo danh mục. |
| `order_provider.dart` | Tạo đơn hàng, lấy đơn hàng của user, lấy đơn hàng của seller/shop. |
| `address_provider.dart` | Thêm, sửa, xóa, lấy danh sách địa chỉ giao hàng. |
| `review_provider.dart` | Lấy review theo sản phẩm, hiển thị review, hỗ trợ dữ liệu đánh giá sản phẩm. |

Đặc điểm chung:

- Gọi API thông qua các file trong `service/`.
- Quản lý `loading`, `error`, dữ liệu local.
- Gọi `notifyListeners()` để UI tự cập nhật.
- Nên có hàm clear/reset dữ liệu khi logout hoặc đổi tài khoản.

---

### 4. `lib/service/`

Chứa lớp gọi API backend. Service không xử lý UI, chỉ gửi request và trả dữ liệu về cho provider.

| File | Chức năng |
|---|---|
| `api_client.dart` | Cấu hình Dio, base URL, header, interceptor, token/cookie nếu có. |
| `auth_service.dart` | API auth: login, register, verify account, forgot password, reset password, change password, logout. |
| `user_service.dart` | API user: lấy/cập nhật thông tin cá nhân, thông tin người dùng. |
| `product_service.dart` | API sản phẩm: danh sách, chi tiết, sản phẩm shop/seller, thêm/sửa/xóa, biến thể. |
| `shop_service.dart` | API shop: đăng ký shop, lấy shop, cập nhật shop, danh sách shop, duyệt shop nếu có. |
| `cart_service.dart` | API giỏ hàng: lấy giỏ, thêm item, cập nhật số lượng, xóa item. |
| `category_service.dart` | API danh mục: lấy danh sách, cây danh mục, tạo/sửa/xóa nếu role được phép. |
| `order_service.dart` | API đơn hàng: checkout, tạo đơn, lấy đơn của user/seller, cập nhật trạng thái nếu có. |
| `address_service.dart` | API địa chỉ: CRUD địa chỉ giao hàng. |
| `review_service.dart` | API đánh giá sản phẩm: lấy review theo product, lấy danh sách review. |

---

### 5. `lib/screens/`

Chứa toàn bộ giao diện của ứng dụng, chia theo nhóm chức năng.

#### 5.1 Màn hình chung

| File | Chức năng |
|---|---|
| `home_screen.dart` | Trang chủ, hiển thị sản phẩm, danh mục, tìm kiếm, mở chi tiết sản phẩm hoặc popup chọn biến thể. |
| `profile_screen.dart` | Trang hồ sơ, menu cá nhân, điều hướng đến thông tin cá nhân, đơn hàng, shop, đổi mật khẩu, đăng xuất. |

#### 5.2 `screens/auths/`

| File | Chức năng |
|---|---|
| `login_screen.dart` | Đăng nhập bằng email và mật khẩu. |
| `register_screen.dart` | Đăng ký tài khoản mới. |
| `forgot_password_screen.dart` | Nhập email để lấy OTP quên mật khẩu. |
| `reset_otp_screen.dart` | Nhập OTP và mật khẩu mới. |
| `verify_account_screen.dart` | Xác minh tài khoản bằng OTP. |
| `change_password_screen.dart` | Đổi mật khẩu cho tài khoản đang đăng nhập. |
| `logout_screen.dart` | Xác nhận đăng xuất. |

#### 5.3 `screens/categories/`

| File | Chức năng |
|---|---|
| `category_screen.dart` | Hiển thị sản phẩm theo danh mục hoặc kết quả tìm kiếm từ Home. |

Ghi chú:

- Home nên dùng search bar để điều hướng sang `CategoryScreen` khi submit.
- Danh mục cha thường dùng để phân nhóm hiển thị.
- Danh mục con thường dùng cho seller khi chọn danh mục cho sản phẩm.

#### 5.4 `screens/products/`

| File | Chức năng |
|---|---|
| `add_product_screen.dart` | Seller thêm sản phẩm mới. |
| `edit_product_screen.dart` | Seller chỉnh sửa sản phẩm. |
| `add_variant_screen.dart` | Seller thêm biến thể sản phẩm như màu, size, ảnh, giá, tồn kho. |
| `product_detail_screen.dart` | Xem chi tiết sản phẩm, gallery ảnh, mô tả, phân loại, shop, review, thêm giỏ/mua ngay. |
| `product_reviews_screen.dart` | Xem tất cả đánh giá của một sản phẩm. |

Widget con trong `screens/products/widgets/`:

| File | Chức năng |
|---|---|
| `product_cart_action_sheet.dart` | Bottom sheet/popup chọn biến thể, số lượng, thêm giỏ hoặc mua ngay. |
| `product_review_section.dart` | Section đánh giá sản phẩm hiển thị trong `product_detail_screen.dart`. |

Ghi chú sản phẩm:

- `product_detail_screen.dart` dùng để xem chi tiết và hiển thị phân loại.
- Khi bấm **Thêm giỏ** hoặc **Mua ngay**, app mở `product_cart_action_sheet.dart` để chọn biến thể.
- `product_cart_action_sheet.dart` nên được dùng lại ở Home và Product Detail để tránh trùng code.
- Khi chọn biến thể, ảnh/giá/tồn kho nên đồng bộ theo variant đang chọn.

#### 5.5 `screens/carts/`

| File | Chức năng |
|---|---|
| `cart_screen.dart` | Hiển thị giỏ hàng, chọn item, cập nhật số lượng, xóa sản phẩm, chuyển sang checkout. |

#### 5.6 `screens/orders_payments/`

| File | Chức năng |
|---|---|
| `checkout_screen.dart` | Kiểm tra địa chỉ, sản phẩm, tổng tiền trước khi đặt hàng/thanh toán. |
| `my_orders_screen.dart` | Danh sách đơn hàng của người dùng. |
| `payment_qr_screen.dart` | Hiển thị QR/thông tin thanh toán. |
| `payment_result_screen.dart` | Hiển thị kết quả thanh toán thành công/thất bại. |

#### 5.7 `screens/address/`

| File | Chức năng |
|---|---|
| `address_list_screen.dart` | Danh sách địa chỉ giao hàng. |
| `add_address_screen.dart` | Thêm hoặc sửa địa chỉ giao hàng. |

Widget liên quan:

| File | Chức năng |
|---|---|
| `vietnam_address_selector.dart` | Chọn tỉnh/thành, quận/huyện, phường/xã. |
| `osm_location_picker.dart` | Chọn vị trí trên bản đồ OpenStreetMap. |

#### 5.8 `screens/shops/`

| File | Chức năng |
|---|---|
| `shop_register_screen.dart` | Đăng ký mở cửa hàng. |
| `shop_management_screen.dart` | Quản lý cửa hàng của seller. |
| `seller_product_list_screen.dart` | Danh sách sản phẩm của seller. |
| `seller_order_list_screen.dart` | Danh sách đơn hàng của shop/seller. |
| `seller_order_detail_screen.dart` | Chi tiết đơn hàng của seller. |
| `shop_list_screen.dart` | Danh sách cửa hàng cho user xem. |
| `shop_detail_screen.dart` | Chi tiết cửa hàng, thông tin shop, sản phẩm trong shop. |

#### 5.9 `screens/users/`

| File | Chức năng |
|---|---|
| `personal_info_screen.dart` | Xem thông tin cá nhân. |
| `edit_personal_info_screen.dart` | Chỉnh sửa thông tin cá nhân. |

#### 5.10 `screens/admins/`

| File | Chức năng |
|---|---|
| `admin_home_screen.dart` | Trang chủ admin. |
| `admin_dashboard_screen.dart` | Dashboard thống kê. |
| `admin_shops_screen.dart` | Quản lý danh sách shop. |
| `admin_shop_approval_screen.dart` | Phê duyệt cửa hàng. |
| `admin_users_screen.dart` | Quản lý người dùng. |
| `admin_user_detail_screen.dart` | Xem chi tiết người dùng. |

---

### 6. `lib/widgets/`

Chứa các widget dùng chung ở nhiều màn hình.

| File | Chức năng |
|---|---|
| `custom_button.dart` | Button tái sử dụng theo style chung. |
| `loading_indicator.dart` | Widget loading/spinner. |
| `osm_location_picker.dart` | Màn/chức năng chọn vị trí bản đồ. |
| `product_card.dart` | Card sản phẩm dùng trong Home, Category, Shop Detail. |
| `review_card.dart` | Card hiển thị đánh giá sản phẩm. |
| `vietnam_address_selector.dart` | Widget chọn tỉnh/quận/phường Việt Nam. |

---

### 7. `lib/theme/`

| File | Chức năng |
|---|---|
| `app_theme.dart` | Cấu hình theme chung: màu sắc, `ColorScheme`, `AppBar`, `Card`, `Button`, input, text style nếu có. |

---

### 8. `lib/utils/`

| File | Chức năng |
|---|---|
| `app_constants.dart` | Khai báo base URL, endpoint API và các hằng số dùng chung. |

Ví dụ cấu hình base URL:

```dart
class AppConstants {
  // Web hoặc desktop local
  static const String baseUrl = 'http://localhost:3000/api';

  // Android Emulator thường dùng:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Điện thoại thật cùng mạng Wi-Fi:
  // static const String baseUrl = 'http://192.168.x.x:3000/api';
}
```

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
→ Điều hướng theo role USER / SELLER / ADMIN
```

### 2. Đăng nhập

```txt
LoginScreen
→ AuthProvider.login()
→ AuthService.login()
→ Lưu token/session
→ Load thông tin user
→ Load dữ liệu cần thiết
→ Điều hướng theo role
```

### 3. Quên mật khẩu và reset mật khẩu

```txt
ForgotPasswordScreen
→ AuthProvider.forgotPassword(email)
→ AuthService.forgotPassword(email)
→ Backend gửi OTP
→ ResetOtpScreen
→ AuthProvider.resetPassword(...)
→ AuthService.resetPassword(...)
→ Quay về LoginScreen
```

### 4. Đổi mật khẩu

```txt
ChangePasswordScreen
→ AuthProvider.changePassword(currentPassword, newPassword, confirmPassword)
→ AuthService.changePassword(...)
→ Backend kiểm tra mật khẩu hiện tại
→ Backend cập nhật mật khẩu mới
→ Thông báo thành công/thất bại
```

Backend nên có endpoint riêng cho tài khoản đang đăng nhập:

```txt
PATCH /users/me/change-password
```

### 5. Xem sản phẩm và thêm vào giỏ

```txt
HomeScreen / CategoryScreen / ShopDetailScreen
→ ProductProvider lấy danh sách sản phẩm
→ User chọn sản phẩm hoặc bấm thêm giỏ
→ ProductDetailScreen hoặc ProductCartActionSheet
→ Chọn variant + số lượng
→ CartProvider.addToCart()
→ CartService gọi backend
→ Cập nhật CartScreen
```

### 6. Mua ngay và checkout

```txt
ProductDetailScreen hoặc ProductCartActionSheet
→ Bấm Mua ngay
→ Chọn variant + số lượng
→ CheckoutScreen
→ Chọn địa chỉ giao hàng
→ OrderProvider.createOrder()
→ PaymentQrScreen
→ PaymentResultScreen
→ MyOrdersScreen
```

### 7. Quản lý địa chỉ giao hàng

```txt
ProfileScreen / CheckoutScreen
→ AddressListScreen
→ AddAddressScreen
→ AddressProvider
→ AddressService
→ Backend lưu địa chỉ
```

### 8. Đánh giá sản phẩm

```txt
ProductDetailScreen
→ ProductReviewSection
→ ReviewProvider.fetchProductReviews(productId)
→ ReviewService gọi API review
→ Hiển thị review ngắn trong chi tiết sản phẩm
→ Bấm xem tất cả
→ ProductReviewsScreen
```

### 9. Seller quản lý shop và sản phẩm

```txt
ProfileScreen
→ ShopManagementScreen
→ SellerProductListScreen
→ AddProductScreen / EditProductScreen / AddVariantScreen
→ ProductProvider
→ ProductService
→ Backend xử lý sản phẩm và biến thể
```

### 10. Seller quản lý đơn hàng

```txt
ShopManagementScreen
→ SellerOrderListScreen
→ SellerOrderDetailScreen
→ OrderProvider
→ OrderService
→ Backend trả đơn hàng của shop/seller
```

### 11. Admin quản trị hệ thống

```txt
AdminHomeScreen
→ AdminDashboardScreen / AdminUsersScreen / AdminShopsScreen
→ AdminUserDetailScreen hoặc AdminShopApprovalScreen
→ Provider/Service tương ứng
→ Backend kiểm tra quyền ADMIN
```

---

## Công nghệ và thư viện sử dụng

| Công nghệ/Thư viện | Mục đích |
|---|---|
| Flutter | Framework chính để xây app mobile/web. |
| Dart | Ngôn ngữ lập trình. |
| Provider | State management. |
| Dio | Gọi API backend. |
| SharedPreferences | Lưu token/session/local data đơn giản. |
| CachedNetworkImage | Hiển thị và cache ảnh từ URL. |
| ImagePicker | Chọn ảnh từ thiết bị nếu màn hình có chức năng upload ảnh. |
| Flutter Map / OSM | Chọn vị trí trên bản đồ. |
| Intl | Định dạng ngày tháng, tiền tệ. |

---

## Khai báo assets trong `pubspec.yaml`

Nếu sử dụng ảnh trong `assets/images/mochi/`, cần khai báo trong `pubspec.yaml`:

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

Sau khi cập nhật README:

```bash
git status

git add README.md

git status

git commit -m "Update README for current Flutter app structure"

git push origin main
```

Nếu muốn commit chung với các file đã thay đổi gần đây:

```bash
git add lib/models/ lib/providers/ lib/screens/ lib/service/ lib/theme/ lib/utils/ lib/widgets/ README.md

git commit -m "Update app features and documentation"

git push origin main
```

---

## Lỗi thường gặp

### 1. Không kết nối được backend

Kiểm tra:

- Backend đã chạy chưa.
- `baseUrl` trong `app_constants.dart` đúng chưa.
- Nếu chạy Android Emulator thì không dùng `localhost`, hãy dùng `10.0.2.2`.
- Nếu chạy điện thoại thật thì dùng IP LAN của máy chạy backend.

### 2. Ảnh không hiển thị

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

### 3. Lỗi import do đổi tên folder

Folder hiện tại là:

```txt
lib/screens/orders_payments/
```

Nếu trước đó code còn import nhầm `oders_payments`, cần sửa lại toàn bộ import sang `orders_payments`.

### 4. Lỗi Provider không cập nhật UI

Kiểm tra:

- Provider đã được đăng ký trong `MultiProvider` chưa.
- Hàm xử lý đã gọi `notifyListeners()` chưa.
- UI có dùng `Consumer`, `context.watch`, hoặc `Provider.of(..., listen: true)` đúng chưa.
- Có clear dữ liệu khi logout hoặc đổi tài khoản không.

### 5. Lỗi gọi API sau khi logout hoặc màn hình bị dispose

Nếu gặp lỗi kiểu widget đã dispose/deactivated:

- Không dùng `context` sau `await` nếu widget đã unmounted.
- Kiểm tra `if (!mounted) return;` trong `StatefulWidget`.
- Không gọi `Provider.of(context)` trong `dispose()` nếu chưa lưu reference từ trước.

---

## Ghi chú quan trọng

- Không đưa `.env`, key, certificate, keystore thật lên GitHub.
- Không commit thư mục `build/`, `.dart_tool/`.
- Có thể không commit `.idea/`, `.vscode/` nếu đó là cấu hình cá nhân.
- Nếu thêm assets, cần commit cả `assets/` và `pubspec.yaml`.
- Nếu sửa `pubspec.yaml`, nên chạy lại `flutter pub get`.
- Khi thêm màn hình mới, nhớ kiểm tra import trong `main.dart` hoặc file router tương ứng.
- Khi thêm provider/service mới, nhớ đăng ký provider và inject service nếu cần.

---

## Cập nhật lần cuối

26/05/2026
