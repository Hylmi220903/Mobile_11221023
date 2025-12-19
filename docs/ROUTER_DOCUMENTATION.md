# Dokumentasi GoRouter - Struktur Routing

## Lokasi File
**File:** [lib/router.dart](../lib/router.dart)

---

## Ringkasan Struktur Routes

Aplikasi ini menggunakan **go_router** package untuk navigasi deklaratif di Flutter. Router dikonfigurasi dengan `initialLocation: '/'` yang mengarah ke HomePage.

**Fitur Utama:**
- Nested Routes untuk grouping halaman terkait
- Path Parameters untuk ID dinamis
- Extra Data untuk passing objects kompleks

---

## Struktur Nested Routes

### 1. Root Routes
| Path | Name | Page |
|------|------|------|
| `/` | `home` | `HomePage` |

### 2. Profile Routes (Nested)
```
/profile                    → ProfilePage
├── /profile/edit          → EditProfilePage
├── /profile/addresses     → AddressesPage
│   ├── /profile/addresses/add    → AddEditAddressPage
│   └── /profile/addresses/:id    → AddEditAddressPage (edit)
└── /profile/wishlist      → WishlistPage
```

| Path | Name | Page | Parameter |
|------|------|------|-----------|
| `/profile` | `profile` | `ProfilePage` | - |
| `/profile/edit` | `edit_profile` | `EditProfilePage` | - |
| `/profile/addresses` | `addresses` | `AddressesPage` | - |
| `/profile/addresses/add` | `add_address` | `AddEditAddressPage` | - |
| `/profile/addresses/:id` | `edit_address` | `AddEditAddressPage` | `id` (int) |
| `/profile/wishlist` | `wishlist` | `WishlistPage` | - |

### 3. Cart Routes (Nested)
```
/cart                       → CartPage
├── /cart/checkout         → CheckoutPage
└── /cart/payment          → PaymentPage
```

| Path | Name | Page | Parameter (Extra) |
|------|------|------|-------------------|
| `/cart` | `cart` | `CartPage` | - |
| `/cart/checkout` | `checkout` | `CheckoutPage` | `product`, `quantity`, `store` |
| `/cart/payment` | `payment` | `PaymentPage` | `orderId`, `amount`, `orderCode`, `productName`, `quantity`, `qrContent`, `expiresAt` |

### 4. Product Routes
| Path | Name | Page | Parameter |
|------|------|------|-----------|
| `/product/:id` | `product_detail` | `ProductDetailPage` | `id` (String) |
| `/store/:id` | `store_catalog` | `StoreCatalogPage` | `id` (String) |

### 5. My Products Routes (Nested - Seller)
```
/my-products                → MyProductsPage
├── /my-products/add       → AddEditProductPage
└── /my-products/:id       → AddEditProductPage (edit)
```

| Path | Name | Page | Parameter |
|------|------|------|-----------|
| `/my-products` | `my_products` | `MyProductsPage` | - |
| `/my-products/add` | `add_product` | `AddEditProductPage` | - |
| `/my-products/:id` | `edit_product` | `AddEditProductPage` | `id` (int) |

### 6. Orders Routes
```
/my-orders                  → MyOrdersPage (Seller view)

/order-history              → OrderHistoryPage (Buyer view)
└── /order-history/:id     → OrderDetailPage
```

| Path | Name | Page | Parameter |
|------|------|------|-----------|
| `/my-orders` | `my_orders` | `MyOrdersPage` | - |
| `/order-history` | `order_history` | `OrderHistoryPage` | - |
| `/order-history/:id` | `order_detail` | `OrderDetailPage` | `id` (int) |

### 7. Authentication Routes (Nested)
```
/login                      → LoginPage
└── /login/register        → RegisterPage
```

| Path | Name | Page |
|------|------|------|
| `/login` | `login` | `LoginPage` |
| `/login/register` | `register` | `RegisterPage` |

---

## Diagram Struktur Lengkap

```
/                                   → HomePage
│
├── /profile                       → ProfilePage
│   ├── /profile/edit             → EditProfilePage
│   ├── /profile/addresses        → AddressesPage
│   │   ├── /profile/addresses/add    → AddEditAddressPage
│   │   └── /profile/addresses/:id    → AddEditAddressPage (edit)
│   └── /profile/wishlist         → WishlistPage
│
├── /cart                          → CartPage
│   ├── /cart/checkout            → CheckoutPage
│   └── /cart/payment             → PaymentPage
│
├── /product/:id                   → ProductDetailPage
│
├── /store/:id                     → StoreCatalogPage
│
├── /my-products                   → MyProductsPage
│   ├── /my-products/add          → AddEditProductPage
│   └── /my-products/:id          → AddEditProductPage (edit)
│
├── /my-orders                     → MyOrdersPage
│
├── /order-history                 → OrderHistoryPage
│   └── /order-history/:id        → OrderDetailPage
│
└── /login                         → LoginPage
    └── /login/register           → RegisterPage
```

---

## Cara Penggunaan

### Navigasi Dasar
```dart
// Go to a named route
context.goNamed('home');

// Go to a route by path
context.go('/profile');

// Push a route (adds to stack)
context.push('/profile/edit');
```

### Navigasi dengan Path Parameters
```dart
// Navigate to product detail
context.push('/product/$productId');

// Navigate to edit address
context.push('/profile/addresses/${address.id}');

// Navigate to order detail
context.push('/order-history/$orderId');

// Navigate to edit product
context.push('/my-products/$productId');
```

### Navigasi dengan Extra Data
```dart
// Navigate to checkout with product data
context.push('/cart/checkout', extra: {
  'product': product,
  'quantity': quantity,
  'store': store,
});

// Navigate to payment page
context.pushNamed('payment', extra: {
  'orderId': orderId,
  'amount': totalAmount,
  'orderCode': orderCode,
  'productName': productName,
  'quantity': quantity,
  'qrContent': qrContent,
  'expiresAt': expiresAt,
});
```

---

## Keuntungan Nested Routes

1. **URL Semantik**: URL mencerminkan hierarki halaman
   - `/profile/addresses` lebih jelas daripada `/addresses`
   - `/cart/checkout` menunjukkan checkout adalah bagian dari cart flow

2. **Grouping Logis**: Halaman terkait dikelompokkan bersama
   - Semua halaman profil di bawah `/profile`
   - Semua halaman cart/checkout di bawah `/cart`

3. **Maintenance Lebih Mudah**: Perubahan pada grup route lebih terisolasi

4. **State Management**: Lebih mudah untuk share state antar nested routes

---

## Fallback Handling

Routes yang membutuhkan `extra` data akan redirect ke `HomePage` jika data tidak tersedia:

```dart
GoRoute(
  path: 'checkout',
  name: 'checkout',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    if (extra == null) {
      return const HomePage(); // Fallback
    }
    // ... process extra data
  },
),
```

---

## Catatan Implementasi

1. **Path Parameters**: Gunakan `:paramName` untuk parameter dinamis
2. **Named Routes**: Semua routes memiliki `name` untuk `goNamed()` / `pushNamed()`
3. **Nested Routes**: Gunakan `routes: []` di dalam `GoRoute` untuk sub-routes
4. **Extra Data**: Untuk passing objects kompleks yang tidak bisa di-serialize ke URL
