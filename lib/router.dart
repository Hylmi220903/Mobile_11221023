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
import 'database/database.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),

    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartPage(),
    ),

    GoRoute(
      path: '/product/:id',
      name: 'product_detail',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailPage(productId: productId);
      },
    ),

    GoRoute(
      path: '/my-products',
      name: 'my_products',
      builder: (context, state) => const MyProductsPage(),
    ),

    GoRoute(
      path: '/my-orders',
      name: 'my_orders',
      builder: (context, state) => const MyOrdersPage(),
    ),

    GoRoute(
      path: '/order/:id',
      name: 'order_detail',
      builder: (context, state) {
        final orderId = int.parse(state.pathParameters['id']!);
        return OrderDetailPage(orderId: orderId);
      },
    ),

    GoRoute(
      path: '/add-product',
      name: 'add_product',
      builder: (context, state) => const AddEditProductPage(),
    ),

    GoRoute(
      path: '/edit-product/:id',
      name: 'edit_product',
      builder: (context, state) {
        final productId = int.parse(state.pathParameters['id']!);
        return AddEditProductPage(productId: productId);
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

    GoRoute(
      path: '/edit-profile',
      name: 'edit_profile',
      builder: (context, state) => const EditProfilePage(),
    ),

    GoRoute(
      path: '/wishlist',
      name: 'wishlist',
      builder: (context, state) => const WishlistPage(),
    ),

    GoRoute(
      path: '/addresses',
      name: 'addresses',
      builder: (context, state) => const AddressesPage(),
    ),

    GoRoute(
      path: '/add-address',
      name: 'add_address',
      builder: (context, state) => const AddEditAddressPage(),
    ),

    GoRoute(
      path: '/edit-address/:id',
      name: 'edit_address',
      builder: (context, state) {
        final addressId = int.parse(state.pathParameters['id']!);
        return AddEditAddressPage(addressId: addressId);
      },
    ),

    GoRoute(
      path: '/checkout',
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

    GoRoute(
      path: '/payment',
      name: 'payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const HomePage();
        }

        return PaymentPage(
          amount: extra['amount'] as double,
          orderCode: extra['orderCode'] as String,
          productName: extra['productName'] as String,
          quantity: extra['quantity'] as int,
          qrContent: extra['qrContent'] as String,
          expiresAt: extra['expiresAt'] as DateTime,
        );
      },
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
      routes: [
        GoRoute(
          path: 'register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
    ),
  ],
);
