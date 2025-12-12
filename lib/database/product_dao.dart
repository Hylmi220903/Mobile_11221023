part of 'database.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

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

  // Get all products (only with stock > 0)
  Future<List<Product>> getAllProducts() {
    return (select(products)..where((tbl) => tbl.stock.isBiggerThanValue(0))).get();
  }

  // Get all products including out of stock (for admin/seller view)
  Future<List<Product>> getAllProductsIncludingOutOfStock() {
    return select(products).get();
  }

  // Get products by category (only with stock > 0)
  Future<List<Product>> getProductsByCategory(String category) {
    return (select(products)..where((tbl) => tbl.category.equals(category) & tbl.stock.isBiggerThanValue(0))).get();
  }

  // Get products by store (seller) - only with stock > 0 for public view
  Future<List<Product>> getProductsByStore(int storeId) {
    return (select(products)..where((tbl) => tbl.storeId.equals(storeId) & tbl.stock.isBiggerThanValue(0))).get();
  }

  // Get all products by store including out of stock (for seller's own view)
  Future<List<Product>> getProductsByStoreIncludingOutOfStock(int storeId) {
    return (select(products)..where((tbl) => tbl.storeId.equals(storeId))).get();
  }

  // Get product by ID
  Future<Product?> getProductById(int productId) {
    return (select(products)..where((tbl) => tbl.id.equals(productId)))
        .getSingleOrNull();
  }

  // Search products by name, model, or description
  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((tbl) => 
              tbl.name.like('%$query%') | 
              tbl.model.like('%$query%') |
              tbl.description.like('%$query%')))
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
}
