# Mini E-Commerce Frontend App

Ứng dụng **Mini E-Commerce Frontend** được xây dựng bằng **Flutter** và **Dart**, hỗ trợ chạy trên **Mobile** và **Web**. Dự án phục vụ các chức năng chính của một app thương mại điện tử mini: đăng nhập/đăng ký, xem sản phẩm, tìm kiếm, danh mục, yêu thích sản phẩm, gợi ý sản phẩm, giỏ hàng, đặt hàng, thanh toán, đánh giá sản phẩm, quản lý cửa hàng, quản lý đơn của seller và quản trị hệ thống.

Ứng dụng hiện có 3 nhóm người dùng chính:

- **USER**: khách hàng mua sản phẩm, quản lý giỏ hàng, địa chỉ, đơn hàng, sản phẩm yêu thích, đánh giá và thông tin cá nhân.
- **SELLER**: người bán, đăng ký/quản lý cửa hàng, quản lý sản phẩm, biến thể sản phẩm và đơn hàng của shop.
- **ADMIN**: quản trị viên, quản lý người dùng, quản lý danh mục, duyệt cửa hàng và xem các màn hình quản trị.

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
- Danh mục sản phẩm cho user và màn hình quản lý danh mục cho admin.
- Sản phẩm yêu thích thông qua `favorite_product_screen.dart`.
- Gợi ý sản phẩm thông qua `recommendation_provider.dart`, `recommendation_service.dart` và `recommendation_event_type.dart`.
- Ghi nhận tương tác người dùng như xem chi tiết, thêm giỏ, yêu thích, bỏ yêu thích, mua hàng để phục vụ gợi ý sản phẩm.
- Popup chọn biến thể sản phẩm dùng chung qua `product_cart_action_sheet.dart`.
- Giỏ hàng, checkout, thanh toán QR, kết quả thanh toán và danh sách đơn hàng.
- Quản lý địa chỉ giao hàng, chọn địa chỉ Việt Nam và chọn vị trí bằng OpenStreetMap.
- Đánh giá sản phẩm, hiển thị section review trong chi tiết sản phẩm và màn hình xem tất cả đánh giá.
- Quản lý shop cho seller: đăng ký shop, quản lý shop, danh sách sản phẩm, danh sách đơn hàng và chi tiết đơn hàng.
- Quản trị admin: dashboard, quản lý user, chi tiết user, quản lý shop, duyệt shop và quản lý danh mục.
- Cấu hình Dio riêng cho nền tảng Web/IO thông qua `dio_platform_config.dart`, `dio_platform_config_io.dart`, `dio_platform_config_web.dart`.
- Giao diện dùng `app_theme.dart`, các widget chung như `custom_button`, `loading_indicator`, `product_card`, `review_card`.

---

## Cấu trúc thư mục hiện tại

```txt
lib/
│   main.dart
│
├── models/
│       address_model.dart
│       cart_model.dart
│       category_model.dart
│       order_model.dart
│       product_model.dart
│       recommendation_event_type.dart
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
│       recommendation_provider.dart
│       review_provider.dart
│       shop_provider.dart
│       user_provider.dart
│
├── screens/
│   │   home_screen.dart
│   │   profile_screen.dart
│   │
│   ├── address/
│   │       address_list_screen.dart
│   │       add_address_screen.dart
│   │
│   ├── admins/
│   │       admin_categories_screen.dart
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
│   ├── categories/
│   │       category_screen.dart
│   │
│   ├── favorites/
│   │       favorite_product_screen.dart
│   │
│   ├── orders_payments/
│   │       checkout_screen.dart
│   │       my_orders_screen.dart
│   │       payment_qr_screen.dart
│   │       payment_result_screen.dart
│   │
│   ├── products/
│   │   │   add_product_screen.dart
│   │   │   add_variant_screen.dart
│   │   │   edit_product_screen.dart
│   │   │   product_detail_screen.dart
│   │   │   product_reviews_screen.dart
│   │   │
│   │   └── widgets/
│   │           product_cart_action_sheet.dart
│   │           product_review_section.dart
│   │
│   ├── shops/
│   │       seller_order_detail_screen.dart
│   │       seller_order_list_screen.dart
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
│       dio_platform_config.dart
│       dio_platform_config_io.dart
│       dio_platform_config_web.dart
│       order_service.dart
│       product_service.dart
│       recommendation_service.dart
│       review_service.dart
│       shop_service.dart
│       user_service.dart
│
├── theme/
│       app_theme.dart
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

> Ghi chú: cấu trúc trên là trạng thái mới nhất của thư mục `lib/`. Folder đơn hàng/thanh toán hiện dùng đúng tên `orders_payments/`. App hiện đã có thêm module `favorites`, `recommendation`, màn hình quản lý danh mục admin và cấu hình Dio riêng cho Web/IO.

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
- Kết nối các provider mới như `RecommendationProvider` nếu app đã đăng ký trong `MultiProvider`.

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
RecommendationProvider
```

---

### 2. `lib/models/`

Chứa các class model dùng để parse dữ liệu từ backend sang object Dart.

| File | Chức năng |
|---|---|
| `address_model.dart` | Model địa chỉ giao hàng. |
| `cart_model.dart` | Model giỏ hàng, item trong giỏ, biến thể được chọn. |
| `category_model.dart` | Model danh mục sản phẩm, hỗ trợ danh mục cha/con. |
| `order_model.dart` | Model đơn hàng, trạng thái đơn hàng, thanh toán và thông tin item trong đơn. |
| `product_model.dart` | Model sản phẩm, ảnh, biến thể, option schema, giá và tồn kho. |
| `recommendation_event_type.dart` | Enum/kiểu dữ liệu cho các loại sự kiện tương tác dùng trong hệ thống gợi ý. |
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
| `recommendation_provider.dart` | Gọi API gợi ý, lấy danh sách sản phẩm gợi ý và gửi sự kiện tương tác của user. |

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
| `api_client.dart` | Cấu hình Dio, base URL, header, interceptor, access token, refresh token nếu có. |
| `dio_platform_config.dart` | File cấu hình chung/abstract để tách xử lý Dio theo nền tảng. |
| `dio_platform_config_io.dart` | Cấu hình Dio cho Mobile/Desktop IO. |
| `dio_platform_config_web.dart` | Cấu hình Dio cho Flutter Web, tránh cấu hình không phù hợp như `sendTimeout` khi request không có body. |
| `auth_service.dart` | API auth: login, register, verify, forgot/reset password, logout, change password. |
| `user_service.dart` | API user: lấy/cập nhật thông tin người dùng. |
| `product_service.dart` | API sản phẩm, biến thể sản phẩm, sản phẩm public và sản phẩm seller. |
| `shop_service.dart` | API cửa hàng, đăng ký shop, duyệt/trạng thái shop nếu có. |
| `cart_service.dart` | API giỏ hàng. |
| `category_service.dart` | API danh mục sản phẩm. |
| `order_service.dart` | API đơn hàng user và đơn hàng seller. |
| `address_service.dart` | API địa chỉ giao hàng. |
| `review_service.dart` | API đánh giá sản phẩm. |
| `recommendation_service.dart` | API gợi ý sản phẩm và ghi nhận sự kiện tương tác. |

---

### 5. `lib/screens/`

Chứa toàn bộ giao diện của ứng dụng.

#### 5.1 Màn hình chung

| File | Chức năng |
|---|---|
| `home_screen.dart` | Trang chủ, hiển thị sản phẩm, tìm kiếm, sản phẩm gợi ý nếu có, card sản phẩm và popup chọn phân loại. |
| `profile_screen.dart` | Trang hồ sơ, menu cá nhân, điều hướng đến thông tin cá nhân, đơn hàng, shop, yêu thích, đổi mật khẩu, logout. |

#### 5.2 `screens/auths/`

| File | Chức năng |
|---|---|
| `login_screen.dart` | Đăng nhập bằng email và mật khẩu. |
| `register_screen.dart` | Đăng ký tài khoản mới. |
| `forgot_password_screen.dart` | Nhập email để lấy OTP quên mật khẩu. |
| `reset_otp_screen.dart` | Nhập OTP và mật khẩu mới. |
| `verify_account_screen.dart` | Xác minh tài khoản bằng OTP. |
| `logout_screen.dart` | Xác nhận đăng xuất. |
| `change_password_screen.dart` | Đổi mật khẩu cho user đang đăng nhập. |

#### 5.3 `screens/products/`

| File | Chức năng |
|---|---|
| `add_product_screen.dart` | Seller thêm sản phẩm mới, bao gồm thông tin sản phẩm và danh mục. |
| `edit_product_screen.dart` | Seller chỉnh sửa sản phẩm, thông tin sản phẩm, ảnh, danh mục và trạng thái nếu có. |
| `add_variant_screen.dart` | Seller thêm biến thể sản phẩm như màu, size, giá, tồn kho và ảnh biến thể. |
| `product_detail_screen.dart` | Xem chi tiết sản phẩm, gallery ảnh, mô tả, phân loại, đánh giá, thêm giỏ/mua ngay. |
| `product_reviews_screen.dart` | Màn hình xem tất cả đánh giá của một sản phẩm. |

Widget con trong `screens/products/widgets/`:

| File | Chức năng |
|---|---|
| `product_cart_action_sheet.dart` | Bottom sheet chọn biến thể sản phẩm, dùng chung cho Home và Product Detail khi bấm thêm giỏ/mua ngay. |
| `product_review_section.dart` | Section đánh giá hiển thị trong trang chi tiết sản phẩm. |

Ghi chú giao diện sản phẩm:

- Phân loại trong trang chi tiết có thể dùng để xem nhanh biến thể.
- Khi bấm **Thêm giỏ** hoặc **Mua ngay**, app mở popup chọn biến thể dùng chung.
- Popup chia biến thể theo từng nhóm cụ thể, ví dụ `màu sắc`, `size`.
- Khi chọn biến thể có ảnh riêng, UI nên đổi ảnh tương ứng với biến thể đó.

#### 5.4 `screens/categories/`

| File | Chức năng |
|---|---|
| `category_screen.dart` | Hiển thị sản phẩm theo danh mục, kết quả tìm kiếm, lọc/sắp xếp sản phẩm nếu có. |

#### 5.5 `screens/favorites/`

| File | Chức năng |
|---|---|
| `favorite_product_screen.dart` | Hiển thị danh sách sản phẩm user đã yêu thích, cho phép mở chi tiết sản phẩm hoặc bỏ yêu thích nếu UI hỗ trợ. |

#### 5.6 `screens/shops/`

| File | Chức năng |
|---|---|
| `shop_register_screen.dart` | Đăng ký mở cửa hàng. |
| `shop_management_screen.dart` | Quản lý thông tin cửa hàng của seller. |
| `seller_product_list_screen.dart` | Danh sách sản phẩm của seller. |
| `seller_order_list_screen.dart` | Danh sách đơn hàng thuộc shop của seller. |
| `seller_order_detail_screen.dart` | Chi tiết đơn hàng seller, sản phẩm trong đơn, trạng thái và thông tin giao hàng nếu có. |
| `shop_list_screen.dart` | Danh sách cửa hàng cho khách xem. |
| `shop_detail_screen.dart` | Chi tiết cửa hàng và sản phẩm trong shop. |

#### 5.7 `screens/carts/`

| File | Chức năng |
|---|---|
| `cart_screen.dart` | Hiển thị giỏ hàng, chọn item, đổi phân loại nếu có, chỉnh số lượng, xóa sản phẩm, chuyển checkout. |

#### 5.8 `screens/orders_payments/`

| File | Chức năng |
|---|---|
| `checkout_screen.dart` | Kiểm tra đơn hàng trước khi đặt hàng/thanh toán. |
| `my_orders_screen.dart` | Danh sách đơn hàng của người dùng, hiển thị tên sản phẩm và biến thể trong đơn. |
| `payment_qr_screen.dart` | Hiển thị mã QR/thông tin thanh toán. |
| `payment_result_screen.dart` | Hiển thị kết quả thanh toán. |

#### 5.9 `screens/address/`

| File | Chức năng |
|---|---|
| `address_list_screen.dart` | Danh sách địa chỉ giao hàng. |
| `add_address_screen.dart` | Thêm hoặc sửa địa chỉ giao hàng. |

#### 5.10 `screens/users/`

| File | Chức năng |
|---|---|
| `personal_info_screen.dart` | Xem thông tin cá nhân. |
| `edit_personal_info_screen.dart` | Chỉnh sửa thông tin cá nhân. |

#### 5.11 `screens/admins/`

| File | Chức năng |
|---|---|
| `admin_home_screen.dart` | Trang chủ admin. |
| `admin_dashboard_screen.dart` | Dashboard thống kê. |
| `admin_categories_screen.dart` | Quản lý danh mục sản phẩm: xem, thêm, sửa, bật/tắt trạng thái nếu backend hỗ trợ. |
| `admin_shops_screen.dart` | Quản lý danh sách shop. |
| `admin_shop_approval_screen.dart` | Phê duyệt cửa hàng. |
| `admin_users_screen.dart` | Quản lý người dùng. |
| `admin_user_detail_screen.dart` | Chi tiết người dùng. |

---

### 6. `lib/theme/`

| File | Chức năng |
|---|---|
| `app_theme.dart` | Khai báo theme chung của app như màu chủ đạo, typography, AppBar, Button, Card, InputDecoration. |

Ghi chú:

- Các màn hình mới nên dùng theme chung trong `app_theme.dart` để UI đồng bộ.
- Hạn chế hard-code màu trực tiếp trong từng màn hình nếu màu đó thuộc hệ thống giao diện chung.

---

### 7. `lib/utils/`

| File | Chức năng |
|---|---|
| `app_constants.dart` | Khai báo base URL, endpoint API và các hằng số dùng chung. |

Ví dụ cấu hình base URL:

```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:3000/api';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String changePasswordRequestOtpEndpoint = '/users/me/change-password/request-otp';
  static const String changePasswordEndpoint = '/users/me/change-password';

  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/categories';
  static const String recommendationsEndpoint = '/recommendations';
}
```

Khi chạy Android Emulator, `localhost` của máy thật thường cần đổi thành:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

---

### 8. `lib/widgets/`

| File | Chức năng |
|---|---|
| `custom_button.dart` | Button tái sử dụng. |
| `loading_indicator.dart` | Loading spinner hoặc loading widget. |
| `osm_location_picker.dart` | Chọn vị trí trên bản đồ OpenStreetMap. |
| `product_card.dart` | Card sản phẩm dùng lại trong Home, Category, Shop Detail, Favorite hoặc Recommendation. |
| `review_card.dart` | Card hiển thị đánh giá sản phẩm. |
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
→ Lưu access token/refresh token nếu có
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
→ AuthProvider.requestChangePasswordOtp()
→ Backend gửi OTP đổi mật khẩu về email
→ User nhập OTP + mật khẩu mới
→ AuthProvider.changePassword(...)
→ AuthService.changePassword(...)
→ Backend đổi mật khẩu
→ Thông báo thành công
```

Endpoint backend đang dùng cho đổi mật khẩu:

```txt
POST  /users/me/change-password/request-otp
PATCH /users/me/change-password
```

### 5. Xem, tìm kiếm và mua sản phẩm

```txt
HomeScreen
→ ProductProvider.fetchPublicProducts()
→ CategoryProvider.load/fetch categories
→ RecommendationProvider lấy sản phẩm gợi ý nếu có
→ Chọn sản phẩm
→ ProductDetailScreen
→ Gửi event VIEW_DETAIL nếu có recommendation tracking
→ Bấm Thêm giỏ/Mua ngay
→ ProductCartActionSheet chọn variant
→ CartProvider.addToCart()
→ CartScreen/CheckoutScreen
```

### 6. Yêu thích sản phẩm

```txt
ProductCard/ProductDetailScreen
→ User bấm yêu thích
→ RecommendationProvider hoặc ProductProvider gửi event FAVORITE
→ FavoriteProductScreen hiển thị danh sách sản phẩm yêu thích
→ User có thể mở ProductDetailScreen từ danh sách yêu thích
```

### 7. Gợi ý sản phẩm

```txt
HomeScreen/ProductDetailScreen/ProductCartActionSheet/Checkout
→ Gửi interaction event
→ RecommendationService gọi backend recommendation API
→ RecommendationProvider lưu danh sách sản phẩm gợi ý
→ UI hiển thị sản phẩm gợi ý trên Home hoặc khu vực phù hợp
```

Các event thường dùng:

```txt
VIEW_DETAIL
ADD_TO_CART
FAVORITE
UNFAVORITE
PURCHASE
```

### 8. Seller quản lý sản phẩm

```txt
ShopManagementScreen
→ SellerProductListScreen
→ AddProductScreen/EditProductScreen
→ Chọn danh mục sản phẩm
→ AddVariantScreen
→ ProductProvider gọi API sản phẩm
```

### 9. Seller quản lý đơn hàng

```txt
ShopManagementScreen
→ SellerOrderListScreen
→ SellerOrderDetailScreen
→ Xem thông tin đơn, sản phẩm, biến thể, người nhận và trạng thái
```

### 10. Đặt hàng và thanh toán

```txt
CartScreen
→ CheckoutScreen
→ OrderProvider.createOrder()
→ PaymentQrScreen
→ PaymentResultScreen
→ MyOrdersScreen
```

### 11. Admin quản lý hệ thống

```txt
AdminHomeScreen
→ AdminDashboardScreen
→ AdminUsersScreen/AdminUserDetailScreen
→ AdminShopsScreen/AdminShopApprovalScreen
→ AdminCategoriesScreen
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

Khi chỉ cập nhật README:

```bash
git status
git add README.md
git commit -m "Update README for current Flutter app structure"
git push origin main
```

Nếu muốn commit theo từng nhóm chức năng mới:

```bash
# Nhóm recommendation
git add lib/models/recommendation_event_type.dart \
        lib/providers/recommendation_provider.dart \
        lib/service/recommendation_service.dart \
        README.md
git commit -m "Add product recommendation frontend support"

# Nhóm favorite products
git add lib/screens/favorites/favorite_product_screen.dart README.md
git commit -m "Add favorite products screen"

# Nhóm admin categories
git add lib/screens/admins/admin_categories_screen.dart \
        lib/providers/category_provider.dart \
        lib/service/category_service.dart \
        README.md
git commit -m "Add admin category management screen"

# Nhóm Dio platform config
git add lib/service/dio_platform_config.dart \
        lib/service/dio_platform_config_io.dart \
        lib/service/dio_platform_config_web.dart \
        lib/service/api_client.dart \
        README.md
git commit -m "Configure Dio by platform"

# Push
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

### 2. Bị 401 sau một thời gian đăng nhập

Trường hợp log có dạng:

```txt
[REQUEST] GET http://localhost:3000/api/users/me
401 → Refresh access token...
Refresh access token OK
[REQUEST] GET http://localhost:3000/api/users/me
```

Ý nghĩa:

- Access token cũ đã hết hạn.
- `ApiClient` gọi refresh token.
- Refresh thành công thì request cũ được gọi lại.
- Đây là luồng bình thường nếu sau đó API chạy thành công.

Nếu refresh thất bại, app nên logout hoặc yêu cầu đăng nhập lại.

### 3. Cảnh báo Dio trên Web

Nếu gặp cảnh báo kiểu:

```txt
[🔔 Dio] sendTimeout cannot be used without a request body to send on Web
```

Cần kiểm tra cấu hình trong:

```txt
lib/service/dio_platform_config.dart
lib/service/dio_platform_config_io.dart
lib/service/dio_platform_config_web.dart
```

Hướng xử lý:

- Với Flutter Web, tránh set `sendTimeout` cho request không có body như `GET`.
- Với Mobile/Desktop IO, có thể dùng timeout đầy đủ nếu cần.
- `api_client.dart` nên dùng cấu hình platform tương ứng thay vì hard-code một cấu hình Dio cho mọi nền tảng.

### 4. Không thấy danh mục khi thêm/chỉnh sửa sản phẩm

Kiểm tra:

- Backend đã có danh mục active chưa.
- FE gọi đúng endpoint danh mục chưa, ví dụ:

```txt
GET /api/categories?isActive=true
```

- `CategoryProvider` có hàm load/fetch danh mục đúng tên đang được màn hình gọi không.
- `AddProductScreen` và `EditProductScreen` đã truyền `categoryId` khi tạo/cập nhật sản phẩm chưa.

### 5. Folder đơn hàng/thanh toán

Tên folder hiện tại đang là:

```txt
lib/screens/orders_payments/
```

Nếu trước đó code còn import nhầm `oders_payments`, cần sửa lại toàn bộ import trong `main.dart` và các file liên quan.

---

## Ghi chú quan trọng

- Không đưa `.env`, key, certificate, keystore thật lên GitHub.
- `build/`, `.dart_tool/`, `.idea/`, `.vscode/` không cần commit.
- Nếu có thêm assets mới, phải khai báo trong `pubspec.yaml` và commit assets tương ứng.
- Nếu sửa `pubspec.yaml`, nên chạy lại `flutter pub get`.
- Các màn hình mới nên dùng `app_theme.dart` để giao diện đồng bộ.
- Các chức năng cần đăng nhập nên xử lý token hết hạn thông qua `ApiClient`.
- Các event recommendation nên được gọi ở những hành động quan trọng, không nên gọi tràn lan để tránh dữ liệu nhiễu.

---

## Cập nhật lần cuối

27/05/2026
