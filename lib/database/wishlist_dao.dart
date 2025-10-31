part of 'database.dart';

@DriftAccessor(tables: [Wishlists, Products])
class WishlistDao extends DatabaseAccessor<AppDatabase> with _$WishlistDaoMixin {
  WishlistDao(super.db);

  // Add item to wishlist
  Future<int> addToWishlist({
    required int userId,
    required int productId,
  }) async {
    // Check if product already in wishlist
    final existingItem = await (select(wishlists)
          ..where((tbl) => 
              tbl.userId.equals(userId) & 
              tbl.productId.equals(productId)))
        .getSingleOrNull();

    if (existingItem != null) {
      // Already in wishlist, do nothing
      return existingItem.id;
    } else {
      // Add new item to wishlist
      return await into(wishlists).insert(
        WishlistsCompanion.insert(
          userId: userId,
          productId: productId,
        ),
      );
    }
  }

  // Remove item from wishlist
  Future<int> removeFromWishlist({
    required int userId,
    required int productId,
  }) async {
    return await (delete(wishlists)
          ..where((tbl) => 
              tbl.userId.equals(userId) & 
              tbl.productId.equals(productId)))
        .go();
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist({
    required int userId,
    required int productId,
  }) async {
    final item = await (select(wishlists)
          ..where((tbl) => 
              tbl.userId.equals(userId) & 
              tbl.productId.equals(productId)))
        .getSingleOrNull();
    
    return item != null;
  }

  // Get all wishlist items for user with product details
  Future<List<Product>> getWishlistProducts(int userId) async {
    final query = select(wishlists).join([
      innerJoin(products, products.id.equalsExp(wishlists.productId)),
    ])..where(wishlists.userId.equals(userId));

    final results = await query.get();
    
    return results.map((row) => row.readTable(products)).toList();
  }

  // Get wishlist count for user
  Future<int> getWishlistCount(int userId) async {
    final query = selectOnly(wishlists)
      ..addColumns([wishlists.id.count()])
      ..where(wishlists.userId.equals(userId));
    
    final result = await query.getSingle();
    return result.read(wishlists.id.count()) ?? 0;
  }

  // Clear wishlist for user
  Future<int> clearWishlist(int userId) async {
    return await (delete(wishlists)
          ..where((tbl) => tbl.userId.equals(userId)))
        .go();
  }
}
