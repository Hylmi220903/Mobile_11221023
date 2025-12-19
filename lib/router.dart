import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/cart_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/my_products_page.dart';
import 'pages/my_orders_page.dart';
import 'pages/add_edit_product_page.dart';
import 'pages/store_catalog_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/addresses_page.dart';
import 'pages/add_edit_address_page.dart';
import 'pages/checkout_page.dart';
import 'pages/payment_page.dart';
import 'pages/order_detail_page.dart';
import 'pages/order_history_page.dart';
import 'database/database.dart';

/// GoRouter configuration untuk aplikasi.
/// 
/// Struktur routing menggunakan nested routes untuk mengelompokkan
/// halaman-halaman yang berhubungan secara hierarkis.
/// 
/// Struktur Utama:
/// - `/` - HomePage (root)
/// - `/profile` - Profil dengan sub-routes (edit, addresses, wishlist)
/// - `/cart` - Keranjang dengan sub-routes (checkout, payment)
/// - `/product/:id` - Detail produk
/// - `/store/:id` - Katalog toko
/// - `/my-products` - Manajemen produk seller dengan sub-routes
/// - `/my-orders` - Pesanan masuk seller
/// - `/order-history` - Riwayat pesanan buyer dengan sub-routes
/// - `/login` - Autentikasi dengan sub-route register
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // ==========================================
    // ROOT - Home
    // ==========================================
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    // ==========================================
    // PROFILE - Nested Routes
    // /profile, /profile/edit, /profile/addresses, /profile/wishlist
    // ==========================================
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
      routes: [
        // Edit Profile - /profile/edit
        GoRoute(
          path: 'edit',
          name: 'edit_profile',
          builder: (context, state) => const EditProfilePage(),
        ),
        // Addresses - /profile/addresses
        GoRoute(
          path: 'addresses',
          name: 'addresses',
          builder: (context, state) => const AddressesPage(),
          routes: [
            // Add Address - /profile/addresses/add
            GoRoute(
              path: 'add',
              name: 'add_address',
              builder: (context, state) => const AddEditAddressPage(),
            ),
            // Edit Address - /profile/addresses/:id
            GoRoute(
              path: ':id',
              name: 'edit_address',
              builder: (context, state) {
                final addressId = int.parse(state.pathParameters['id']!);
                return AddEditAddressPage(addressId: addressId);
              },
            ),
          ],
        ),
        // Wishlist - /profile/wishlist
        GoRoute(
          path: 'wishlist',
          name: 'wishlist',
          builder: (context, state) => const WishlistPage(),
        ),
      ],
    ),

    // ==========================================
    // CART - Nested Routes
    // /cart, /cart/checkout, /cart/payment
    // ==========================================
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartPage(),
      routes: [
        // Checkout - /cart/checkout
        GoRoute(
          path: 'checkout',
          name: 'checkout',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra == null) {
              return const HomePage();
            }
            final product = extra['product'] as Product;
            final quantity = extra['quantity'] as int;
            final store = extra['store'] as Store?;
            return CheckoutPage(product: product, quantity: quantity, store: store);
          },
        ),
        // Payment - /cart/payment
        GoRoute(
          path: 'payment',
          name: 'payment',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra == null) {
              return const HomePage();
            }

            return PaymentPage(
              orderId: extra['orderId'] as int,
              amount: extra['amount'] as double,
              orderCode: extra['orderCode'] as String,
              productName: extra['productName'] as String,
              quantity: extra['quantity'] as int,
              qrContent: extra['qrContent'] as String,
              expiresAt: extra['expiresAt'] as DateTime,
            );
          },
        ),
      ],
    ),

    // ==========================================
    // PRODUCT - Detail & Store
    // ==========================================
    GoRoute(
      path: '/product/:id',
      name: 'product_detail',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailPage(productId: productId);
      },
    ),

    GoRoute(
      path: '/store/:id',
      name: 'store_catalog',
      builder: (context, state) {
        final storeId = state.pathParameters['id']!;
        return StoreCatalogPage(storeId: storeId);
      },
    ),

    // ==========================================
    // MY PRODUCTS (Seller) - Nested Routes
    // /my-products, /my-products/add, /my-products/:id (edit)
    // ==========================================
    GoRoute(
      path: '/my-products',
      name: 'my_products',
      builder: (context, state) => const MyProductsPage(),
      routes: [
        // Add Product - /my-products/add
        GoRoute(
          path: 'add',
          name: 'add_product',
          builder: (context, state) => const AddEditProductPage(),
        ),
        // Edit Product - /my-products/:id
        GoRoute(
          path: ':id',
          name: 'edit_product',
          builder: (context, state) {
            final productId = int.parse(state.pathParameters['id']!);
            return AddEditProductPage(productId: productId);
          },
        ),
      ],
    ),

    // ==========================================
    // ORDERS (Seller) - My Orders
    // ==========================================
    GoRoute(
      path: '/my-orders',
      name: 'my_orders',
      builder: (context, state) => const MyOrdersPage(),
    ),

    // ==========================================
    // ORDER HISTORY (Buyer) - Nested Routes
    // /order-history, /order-history/:id (detail)
    // ==========================================
    GoRoute(
      path: '/order-history',
      name: 'order_history',
      builder: (context, state) => const OrderHistoryPage(),
      routes: [
        // Order Detail - /order-history/:id
        GoRoute(
          path: ':id',
          name: 'order_detail',
          builder: (context, state) {
            final orderId = int.parse(state.pathParameters['id']!);
            return OrderDetailPage(orderId: orderId);
          },
        ),
      ],
    ),

    // ==========================================
    // AUTHENTICATION - Nested Routes
    // /login, /login/register
    // ==========================================
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
      routes: [
        // Register - /login/register
        GoRoute(
          path: 'register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
    ),
  ],
);
