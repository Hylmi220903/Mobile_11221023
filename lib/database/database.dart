import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'connection/connection.dart' as impl;

part 'database.g.dart';
part 'user_dao.dart';
part 'store_dao.dart';
part 'product_dao.dart';
part 'cart_dao.dart';

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
  tables: [Users, Stores, Products, CartItems],
  daos: [UserDao, StoreDao, ProductDao, CartDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // Updated to include storeName in Users table

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
