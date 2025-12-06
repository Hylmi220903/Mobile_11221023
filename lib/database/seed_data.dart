import 'package:drift/drift.dart';
import '../database/database.dart';

// Function to seed initial data: Admin user, Apple Store, and products
Future<void> seedInitialData(AppDatabase database) async {
  try {
    // Check if products already exist (more reliable than checking users)
    try {
      final existingProducts = await database.productDao.getAllProducts();
      if (existingProducts.isNotEmpty) {
        print('✓ Data already seeded (${existingProducts.length} products found).');
        return;
      }
    } catch (e) {
      print('Database needs seeding (error checking products: $e)');
    }

    // Check if Admin Apple user already exists
    User? adminUser;
    try {
      adminUser = await database.userDao.getUserByEmail('apple123@gmail.com');
    } catch (e) {
      print('Admin user does not exist yet.');
    }

    int adminUserId;
    if (adminUser != null) {
      print('✓ Admin Apple user already exists (ID: ${adminUser.id})');
      adminUserId = adminUser.id;
    } else {
      // 1. Create Admin Apple user
      print('Creating Admin Apple user...');
      adminUserId = await database.userDao.registerUser(
        fullName: 'Admin Apple',
        email: 'apple123@gmail.com',
        phoneNumber: '082357163888',
        storeName: 'Apple Official Store', // Added storeName
        password: 'apple1234!',
      );
      print('✓ Admin Apple user created with ID: $adminUserId');
    }

    // 2. Create Test Account for testing purposes
    User? testUser;
    try {
      testUser = await database.userDao.getUserByEmail('tes@gmail.com');
    } catch (e) {
      print('Test user does not exist yet.');
    }

    if (testUser != null) {
      print('✓ Test Account already exists (ID: ${testUser.id})');
    } else {
      print('Creating Test Account...');
      final testUserId = await database.userDao.registerUser(
        fullName: 'TestAccount',
        email: 'tes@gmail.com',
        phoneNumber: '08123456789',
        storeName: 'Test123',
        password: 'tes12345',
      );
      print('✓ Test Account created with ID: $testUserId');
    }

    // Check if Apple Store already exists
    final existingStores = await database.storeDao.getStoresByOwner(adminUserId);
    int appleStoreId;
    
    if (existingStores.isNotEmpty) {
      print('✓ Apple Store already exists (ID: ${existingStores.first.id})');
      appleStoreId = existingStores.first.id;
    } else {
      // 2. Create Apple Store Official
      print('Creating Apple Store Official...');
      appleStoreId = await database.storeDao.createStore(
        storeName: 'Apple Store Official',
        ownerId: adminUserId,
        description: 'Official Apple products store with authentic devices and accessories',
      );
      print('✓ Apple Store Official created with ID: $appleStoreId');
    }

    // 3. Seed products
    print('Seeding products...');
    final productsData = [
      {
        'name': 'Apple iPhone 14 Pro',
        'model': '512GB Gold (MQ233)',
        'price': 1437.0,
        'imagePath': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-gold-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519413',
        'description': 'This premium smartphone features cutting-edge technology with an advanced camera system, powerful processor, and stunning display. Perfect for photography, gaming, and productivity. Experience the latest innovations in mobile technology with this flagship device.',
        'soldCount': 1247,
        'stock': 45,
        'category': 'Smartphone',
      },
      {
        'name': 'Apple iPhone 11',
        'model': '128GB White (MQ233)',
        'price': 510.0,
        'imagePath': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone11-white-select-2019?wid=470&hei=556&fmt=png-alpha&.v=1566956148115',
        'description': 'iPhone 11 features an all-day battery, Liquid Retina display, and dual-camera system for stunning photos and videos. Perfect balance of performance and affordability with advanced features for everyday use.',
        'soldCount': 2150,
        'stock': 78,
        'category': 'Smartphone',
      },
      {
        'name': 'Apple iPhone 14 Pro',
        'model': '1TB Gold (MQ2V3)',
        'price': 1499.0,
        'imagePath': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-gold-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519413',
        'description': 'iPhone 14 Pro Max with maximum storage capacity, perfect for professional photographers and content creators.',
        'soldCount': 892,
        'stock': 30,
        'category': 'Smartphone',
      },
      {
        'name': 'Apple iPhone 14 Pro',
        'model': '128GB Deep Purple (MQ0G3)',
        'price': 1600.0,
        'imagePath': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-deeppurple-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519408',
        'description': 'Experience the stunning new Deep Purple color with the most advanced iPhone camera system ever.',
        'soldCount': 1680,
        'stock': 52,
        'category': 'Smartphone',
      },
      {
        'name': 'Apple iPhone 13 mini',
        'model': '128GB Pink (MLK23)',
        'price': 850.0,
        'imagePath': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-13-mini-pink-select-2021?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1645572315651',
        'description': 'iPhone 13 mini packs big features in a compact 5.4-inch design, perfect for one-handed use.',
        'soldCount': 756,
        'stock': 40,
        'category': 'Smartphone',
      },
      {
        'name': 'Apple iPhone 14 Pro',
        'model': '256GB Space Black (MQ0T3)',
        'price': 1399.0,
        'imagePath': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-black-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519378',
        'description': 'Classic Space Black iPhone 14 Pro with optimal storage for most users and professionals.',
        'soldCount': 1450,
        'stock': 60,
        'category': 'Smartphone',
      },
    ];

    int productCount = 0;
    for (var productData in productsData) {
      await database.productDao.addProduct(
        name: productData['name'] as String,
        model: productData['model'] as String,
        price: productData['price'] as double,
        imagePath: productData['imagePath'] as String,
        description: productData['description'] as String,
        soldCount: productData['soldCount'] as int,
        stock: productData['stock'] as int,
        category: productData['category'] as String,
        storeId: appleStoreId,
      );
      productCount++;
    }
    print('✓ Successfully seeded $productCount products');

    // 4. Seed sample orders
    print('Seeding sample orders...');
    
    // Get test user
    final testUser2 = await database.userDao.getUserByEmail('tes@gmail.com');
    final testUserId = testUser2?.id;
    
    if (testUserId != null) {
      // Get some products for orders
      final allProducts = await database.productDao.getAllProducts();
      
      if (allProducts.length >= 3) {
        // Create orders for the test user (buyer) and admin (seller)
        
        // Order 1: Payment status (30 min deadline)
        await database.orderDao.createOrder(
          OrdersCompanion.insert(
            buyerId: testUserId,
            sellerId: adminUserId,
            productId: allProducts[0].id,
            quantity: 1,
            priceAtPurchase: allProducts[0].price,
            shippingType: 'Reguler - JNE',
            status: 'payment',
            paymentDeadline: Value(DateTime.now().add(const Duration(minutes: 22))),
          ),
        );
        
        // Order 2: Packing status
        await database.orderDao.createOrder(
          OrdersCompanion.insert(
            buyerId: testUserId,
            sellerId: adminUserId,
            productId: allProducts[1].id,
            quantity: 1,
            priceAtPurchase: allProducts[1].price,
            shippingType: 'Instant - Gosend',
            status: 'packing',
            paidAt: Value(DateTime.now().subtract(const Duration(hours: 1))),
          ),
        );
        
        // Order 3: Delivery status
        await database.orderDao.createOrder(
          OrdersCompanion.insert(
            buyerId: testUserId,
            sellerId: adminUserId,
            productId: allProducts[2].id,
            quantity: 2,
            priceAtPurchase: allProducts[2].price,
            shippingType: 'Kargo - SiCepat',
            status: 'delivery',
            paidAt: Value(DateTime.now().subtract(const Duration(days: 1))),
            deliveredAt: Value(DateTime.now().subtract(const Duration(hours: 12))),
          ),
        );
        
        // Order 4: Finished status
        if (allProducts.length >= 4) {
          await database.orderDao.createOrder(
            OrdersCompanion.insert(
              buyerId: testUserId,
              sellerId: adminUserId,
              productId: allProducts[3].id,
              quantity: 1,
              priceAtPurchase: allProducts[3].price,
              shippingType: 'Reguler - JNE',
              status: 'finished',
              paidAt: Value(DateTime.now().subtract(const Duration(days: 5))),
              deliveredAt: Value(DateTime.now().subtract(const Duration(days: 3))),
              finishedAt: Value(DateTime.now().subtract(const Duration(days: 2))),
            ),
          );
        }
        
        print('✓ Successfully seeded 4 sample orders');
      }
    }

    print('\n========================================');
    print('✅ Initial data seeding completed!');
    print('========================================');
    print('Admin User: apple123@gmail.com / apple1234!');
    print('Test Account: tes@gmail.com / tes12345');
    print('Store: Apple Store Official (ID: $appleStoreId)');
    print('Products: $productCount items added');
    print('Orders: Sample orders added for testing');
    print('========================================\n');

  } catch (e) {
    print('❌ Error seeding data: $e');
    rethrow;
  }
}
