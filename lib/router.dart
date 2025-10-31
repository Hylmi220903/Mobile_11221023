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
