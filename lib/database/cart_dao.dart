part of 'database.dart';

@DriftAccessor(tables: [CartItems, Products])
class CartDao extends DatabaseAccessor<AppDatabase> with _$CartDaoMixin {
  CartDao(super.db);

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
