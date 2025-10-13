class Product {
  final String id;
  final String name;
  final String model;
  final double price;
  final String imageUrl;
  final String description;
  final int soldCount;
  final String storeId;
  final String storeName;

  Product({
    required this.id,
    required this.name,
    required this.model,
    required this.price,
    required this.imageUrl,
    this.description = '',
    this.soldCount = 0,
    this.storeId = 'default',
    this.storeName = 'iTech Store',
  });

  // Sample product data
  static List<Product> sampleProducts = [
    Product(
      id: 'iphone14pro-512-gold',
      name: 'Apple iPhone 14 Pro',
      model: '512GB Gold (MQ233)',
      price: 1437,
      imageUrl: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-gold-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519413',
      description: 'The iPhone 14 Pro features the powerful A16 Bionic chip, Pro camera system with 48MP Main camera, and ProMotion technology with Always-On display.',
      soldCount: 1247,
      storeId: 'store1',
      storeName: 'Apple Store Official',
    ),
    Product(
      id: 'iphone11-128-white',
      name: 'Apple iPhone 11',
      model: '128GB White (MQ233)',
      price: 510,
      imageUrl: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone11-white-select-2019?wid=470&hei=556&fmt=png-alpha&.v=1566956148115',
      description: 'iPhone 11 features an all-day battery, Liquid Retina display, and dual-camera system for stunning photos and videos.',
      soldCount: 2150,
      storeId: 'store1',
      storeName: 'Apple Store Official',
    ),
    Product(
      id: 'iphone14pro-1tb-gold',
      name: 'Apple iPhone 14 Pro',
      model: '1TB Gold (MQ2V3)',
      price: 1499,
      imageUrl: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-gold-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519413',
      description: 'iPhone 14 Pro Max with maximum storage capacity, perfect for professional photographers and content creators.',
      soldCount: 892,
      storeId: 'store1',
      storeName: 'Apple Store Official',
    ),
    Product(
      id: 'iphone14pro-deep-purple',
      name: 'Apple iPhone 14 Pro',
      model: '128GB Deep Purple (MQ0G3)',
      price: 1600,
      imageUrl: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-deeppurple-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519408',
      description: 'Experience the stunning new Deep Purple color with the most advanced iPhone camera system ever.',
      soldCount: 1680,
      storeId: 'store1',
      storeName: 'Apple Store Official',
    ),
    Product(
      id: 'iphone13-mini-pink',
      name: 'Apple iPhone 13 mini',
      model: '128GB Pink (MLK23)',
      price: 850,
      imageUrl: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-13-mini-pink-select-2021?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1645572315651',
      description: 'iPhone 13 mini packs big features in a compact 5.4-inch design, perfect for one-handed use.',
      soldCount: 756,
      storeId: 'store2',
      storeName: 'Mobile World',
    ),
    Product(
      id: 'iphone14pro-256-black',
      name: 'Apple iPhone 14 Pro',
      model: '256GB Space Black (MQ0T3)',
      price: 1399,
      imageUrl: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-14-pro-black-select?wid=470&hei=556&fmt=jpeg&qlt=95&.v=1676503519378',
      description: 'Classic Space Black iPhone 14 Pro with optimal storage for most users and professionals.',
      soldCount: 1450,
      storeId: 'store1',
      storeName: 'Apple Store Official',
    ),
  ];
}