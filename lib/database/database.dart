import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'connection/connection.dart' as impl;

part 'database.g.dart';

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

@DriftDatabase(tables: [Users, Stores, Products, CartItems])
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

  // Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================
  // USER METHODS
  // ============================================

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

  // Register new user
  Future<int> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String storeName, // Added storeName parameter
  }) async {
    // Validate fullName (only letters and spaces)
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(fullName)) {
      throw Exception('Full Name harus hanya berisi huruf');
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception('Format email tidak valid');
    }

    // Validate phone number (only numbers)
    if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      throw Exception('Phone Number harus hanya berisi angka');
    }

    // Validate phone number length
    if (phoneNumber.length < 6 || phoneNumber.length > 14) {
      throw Exception('Phone Number harus antara 6-14 digit');
    }

    // Validate password length
    if (password.length < 8) {
      throw Exception('Password minimal 8 karakter');
    }

    // Validate store name
    if (storeName.trim().isEmpty) {
      throw Exception('Store Name tidak boleh kosong');
    }

    // Check if email already exists
    final existingUser = await (select(users)
          ..where((tbl) => tbl.email.equals(email)))
        .getSingleOrNull();

    if (existingUser != null) {
      throw Exception('Email sudah terdaftar');
    }

    // Hash password and insert user
    final hashedPassword = _hashPassword(password);
    
    return await into(users).insert(
      UsersCompanion.insert(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: hashedPassword,
        storeName: storeName, // Include storeName
      ),
    );
  }

  // Login user
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    final hashedPassword = _hashPassword(password);
    
    final user = await (select(users)
          ..where((tbl) => 
              tbl.email.equals(email) & 
              tbl.password.equals(hashedPassword)))
        .getSingleOrNull();

    return user;
  }

  // Get user by ID
  Future<User?> getUserById(int userId) {
    return (select(users)..where((tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) {
    return (select(users)..where((tbl) => tbl.email.equals(email)))
        .getSingleOrNull();
  }

  // Update user
  Future<bool> updateUser(User user) {
    return update(users).replace(user);
  }

  // Delete user
  Future<int> deleteUser(int userId) {
    return (delete(users)..where((tbl) => tbl.id.equals(userId))).go();
  }

  // Get all users (for admin purposes)
  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  // ============================================
  // STORE METHODS
  // ============================================

  // Create new store
  Future<int> createStore({
    required String storeName,
    required int ownerId,
    String? description,
  }) async {
    return await into(stores).insert(
      StoresCompanion.insert(
        storeName: storeName,
        ownerId: ownerId,
        description: Value(description),
      ),
    );
  }

  // Get store by ID
  Future<Store?> getStoreById(int storeId) {
    return (select(stores)..where((tbl) => tbl.id.equals(storeId)))
        .getSingleOrNull();
  }

  // Get stores by owner
  Future<List<Store>> getStoresByOwner(int ownerId) {
    return (select(stores)..where((tbl) => tbl.ownerId.equals(ownerId))).get();
  }

  // Get all stores
  Future<List<Store>> getAllStores() {
    return select(stores).get();
  }

  // Update store
  Future<bool> updateStore(Store store) {
    return update(stores).replace(store);
  }

  // Delete store
  Future<int> deleteStore(int storeId) {
    return (delete(stores)..where((tbl) => tbl.id.equals(storeId))).go();
  }

  // ============================================
  // PRODUCT METHODS
  // ============================================

  // Add new product
  Future<int> addProduct({
    required String name,
    required String model,
    required double price,
    required String imagePath,
    required String description,
    required int stock,
    required String category,
    required int storeId,
    int soldCount = 0,
  }) async {
    return await into(products).insert(
      ProductsCompanion.insert(
        name: name,
        model: model,
        price: price,
        imagePath: imagePath,
        description: description,
        soldCount: Value(soldCount),
        stock: Value(stock),
        category: category,
        storeId: storeId,
      ),
    );
  }

  // Get all products
  Future<List<Product>> getAllProducts() {
    return select(products).get();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) {
    return (select(products)..where((tbl) => tbl.category.equals(category))).get();
  }

  // Get products by store (seller)
  Future<List<Product>> getProductsByStore(int storeId) {
    return (select(products)..where((tbl) => tbl.storeId.equals(storeId))).get();
  }

  // Get product by ID
  Future<Product?> getProductById(int productId) {
    return (select(products)..where((tbl) => tbl.id.equals(productId)))
        .getSingleOrNull();
  }

  // Search products by name
  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((tbl) => tbl.name.like('%$query%') | tbl.description.like('%$query%')))
        .get();
  }

  // Update product
  Future<bool> updateProduct(Product product) {
    return update(products).replace(product);
  }

  // Update product stock
  Future<int> updateProductStock(int productId, int newStock) {
    return (update(products)..where((tbl) => tbl.id.equals(productId)))
        .write(ProductsCompanion(stock: Value(newStock)));
  }

  // Increment sold count (when user purchases)
  Future<int> incrementSoldCount(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product != null) {
      return (update(products)..where((tbl) => tbl.id.equals(productId)))
          .write(ProductsCompanion(
        soldCount: Value(product.soldCount + quantity),
        stock: Value(product.stock - quantity),
      ));
    }
    return 0;
  }

  // Delete product
  Future<int> deleteProduct(int productId) {
    return (delete(products)..where((tbl) => tbl.id.equals(productId))).go();
  }

  // ============================================
  // CART METHODS
  // ============================================

  // Add item to cart
  Future<int> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    // Check if product already in cart
    final existingItem = await (select(cartItems)
          ..where((tbl) => 
              tbl.userId.equals(userId) & 
              tbl.productId.equals(productId)))
        .getSingleOrNull();

    if (existingItem != null) {
      // Update quantity if already exists
      return await (update(cartItems)
            ..where((tbl) => tbl.id.equals(existingItem.id)))
          .write(CartItemsCompanion(
        quantity: Value(existingItem.quantity + quantity),
      ));
    } else {
      // Add new item to cart
      return await into(cartItems).insert(
        CartItemsCompanion.insert(
          userId: userId,
          productId: productId,
          quantity: Value(quantity),
        ),
      );
    }
  }

  // Get cart items for user with product details
  Future<List<CartItemWithProduct>> getCartItems(int userId) async {
    final query = select(cartItems).join([
      innerJoin(products, products.id.equalsExp(cartItems.productId)),
    ])..where(cartItems.userId.equals(userId));

    final results = await query.get();
    
    return results.map((row) {
      return CartItemWithProduct(
        cartItem: row.readTable(cartItems),
        product: row.readTable(products),
      );
    }).toList();
  }

  // Update cart item quantity
  Future<int> updateCartItemQuantity(int cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      return removeFromCart(cartItemId);
    }
    return (update(cartItems)..where((tbl) => tbl.id.equals(cartItemId)))
        .write(CartItemsCompanion(quantity: Value(newQuantity)));
  }

  // Remove item from cart
  Future<int> removeFromCart(int cartItemId) {
    return (delete(cartItems)..where((tbl) => tbl.id.equals(cartItemId))).go();
  }

  // Clear all cart items for user
  Future<int> clearCart(int userId) {
    return (delete(cartItems)..where((tbl) => tbl.userId.equals(userId))).go();
  }

  // Get cart item count for user
  Future<int> getCartItemCount(int userId) async {
    final query = selectOnly(cartItems)
      ..addColumns([cartItems.quantity.sum()])
      ..where(cartItems.userId.equals(userId));
    
    final result = await query.getSingleOrNull();
    return result?.read(cartItems.quantity.sum()) ?? 0;
  }

  // Get cart total price
  Future<double> getCartTotal(int userId) async {
    final items = await getCartItems(userId);
    double total = 0;
    for (var item in items) {
      total += item.product.price * item.cartItem.quantity;
    }
    return total;
  }
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

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final connection = await impl.connect();
    return connection.executor;
  });
}
