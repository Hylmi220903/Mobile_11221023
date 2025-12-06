import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'connection/connection.dart' as impl;

part 'database.g.dart';
part 'user_dao.dart';
part 'store_dao.dart';
part 'product_dao.dart';
part 'cart_dao.dart';
part 'wishlist_dao.dart';
part 'address_dao.dart';
part 'order_dao.dart';

// Users Table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().withLength(min: 1, max: 255)();
  TextColumn get email => text().withLength(min: 1, max: 255).unique()();
  TextColumn get phoneNumber => text().withLength(min: 6, max: 14)();
  TextColumn get password => text().withLength(min: 8)();
  TextColumn get storeName => text().withLength(min: 1, max: 255)(); // Store name for seller
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Stores Table (Toko yang dimiliki oleh User)
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  IntColumn get ownerId => integer().references(Users, #id, onDelete: KeyAction.cascade)(); // Foreign key to Users
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Products Table
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get model => text().withLength(min: 1, max: 255)();
  RealColumn get price => real()();
  TextColumn get imagePath => text()(); // Path to image file or URL
  TextColumn get description => text()();
  IntColumn get soldCount => integer().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get category => text().withLength(min: 1, max: 100)();
  IntColumn get storeId => integer().references(Stores, #id, onDelete: KeyAction.cascade)(); // Foreign key to Stores
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Cart Items Table
class CartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, productId}, // One user can only have one entry per product in cart
  ];
}

// Wishlist Items Table
class Wishlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, productId}, // One user can only have one entry per product in wishlist
  ];
}

// Addresses Table
class Addresses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get recipientName => text().withLength(min: 1, max: 255)();
  TextColumn get phoneNumber => text().withLength(min: 6, max: 20)();
  TextColumn get province => text().withLength(min: 1, max: 100)();
  TextColumn get city => text().withLength(min: 1, max: 100)();
  TextColumn get district => text().withLength(min: 1, max: 100)();
  TextColumn get postalCode => text().withLength(min: 1, max: 10)();
  TextColumn get streetAddress => text()(); // Nama Jalan, Gedung, No. Rumah
  TextColumn get detailAddress => text().nullable()(); // Detail Lainnya (Blok/Unit No., Patokan)
  BoolColumn get isMainAddress => boolean().withDefault(const Constant(false))();
  BoolColumn get isStoreAddress => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Orders Table
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get buyerId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get sellerId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get quantity => integer()();
  RealColumn get priceAtPurchase => real()(); // Price at the time of purchase
  TextColumn get shippingType => text()(); // e.g., "Reguler - JNE", "Instant - Gosend"
  TextColumn get status => text()(); // payment, packing, delivery, finished
  DateTimeColumn get paymentDeadline => dateTime().nullable()(); // 30 minutes for payment
  DateTimeColumn get orderedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}

// Helper class to return cart item with product details
class CartItemWithProduct {
  final CartItem cartItem;
  final Product product;

  CartItemWithProduct({
    required this.cartItem,
    required this.product,
  });
}

@DriftDatabase(
  tables: [Users, Stores, Products, CartItems, Wishlists, Addresses, Orders],
  daos: [UserDao, StoreDao, ProductDao, CartDao, WishlistDao, AddressDao, OrderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6; // Updated to include Orders table

  // Create singleton instance
  static AppDatabase? _instance;
  
  static Future<AppDatabase> getInstance() async {
    _instance ??= AppDatabase();
    return _instance!;
  }

  // Hash password using SHA256 (made public for DAO access)
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Migration helper
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add Stores table
          await m.createTable(stores);
          
          // Note: Data migration from Users.storeName to Stores table
          // should be handled manually if needed
        }
        if (from < 4) {
          // Add Wishlists table
          await m.createTable(wishlists);
        }
        if (from < 5) {
          // Add Addresses table
          await m.createTable(addresses);
        }
        if (from < 6) {
          // Add Orders table
          await m.createTable(orders);
        }
      },
    );
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final connection = await impl.connect();
    return connection.executor;
  });
}
