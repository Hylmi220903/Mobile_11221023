part of 'database.dart';

// Helper class to return order with product and store details
class OrderWithDetails {
  final Order order;
  final Product product;
  final String storeName;
  final String buyerName;

  OrderWithDetails({
    required this.order,
    required this.product,
    required this.storeName,
    required this.buyerName,
  });
}

@DriftAccessor(tables: [Orders, Products, Stores, Users])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(AppDatabase db) : super(db);

  // Create a new order
  Future<int> createOrder(OrdersCompanion order) {
    return into(orders).insert(order);
  }

  // Get all orders where user is the buyer
  Future<List<OrderWithDetails>> getBuyerOrders(int buyerId) async {
    final query = select(orders).join([
      innerJoin(products, products.id.equalsExp(orders.productId)),
      innerJoin(stores, stores.id.equalsExp(products.storeId)),
      innerJoin(users, users.id.equalsExp(orders.sellerId)),
    ])..where(orders.buyerId.equals(buyerId))
      ..orderBy([OrderingTerm.desc(orders.orderedAt)]);

    final results = await query.get();
    return results.map((row) {
      return OrderWithDetails(
        order: row.readTable(orders),
        product: row.readTable(products),
        storeName: row.readTable(stores).storeName,
        buyerName: '', // Not needed for buyer view
      );
    }).toList();
  }

  // Get all orders where user is the seller
  Future<List<OrderWithDetails>> getSellerOrders(int sellerId) async {
    final query = select(orders).join([
      innerJoin(products, products.id.equalsExp(orders.productId)),
      innerJoin(stores, stores.id.equalsExp(products.storeId)),
      innerJoin(users, users.id.equalsExp(orders.buyerId)),
    ])..where(orders.sellerId.equals(sellerId))
      ..orderBy([OrderingTerm.desc(orders.orderedAt)]);

    final results = await query.get();
    return results.map((row) {
      return OrderWithDetails(
        order: row.readTable(orders),
        product: row.readTable(products),
        storeName: row.readTable(stores).storeName,
        buyerName: row.readTable(users).fullName,
      );
    }).toList();
  }

  // Get buyer orders by status
  Future<List<OrderWithDetails>> getBuyerOrdersByStatus(int buyerId, String status) async {
    final query = select(orders).join([
      innerJoin(products, products.id.equalsExp(orders.productId)),
      innerJoin(stores, stores.id.equalsExp(products.storeId)),
      innerJoin(users, users.id.equalsExp(orders.sellerId)),
    ])..where(orders.buyerId.equals(buyerId) & orders.status.equals(status))
      ..orderBy([OrderingTerm.desc(orders.orderedAt)]);

    final results = await query.get();
    return results.map((row) {
      return OrderWithDetails(
        order: row.readTable(orders),
        product: row.readTable(products),
        storeName: row.readTable(stores).storeName,
        buyerName: '',
      );
    }).toList();
  }

  // Get seller orders by status
  Future<List<OrderWithDetails>> getSellerOrdersByStatus(int sellerId, String status) async {
    final query = select(orders).join([
      innerJoin(products, products.id.equalsExp(orders.productId)),
      innerJoin(stores, stores.id.equalsExp(products.storeId)),
      innerJoin(users, users.id.equalsExp(orders.buyerId)),
    ])..where(orders.sellerId.equals(sellerId) & orders.status.equals(status))
      ..orderBy([OrderingTerm.desc(orders.orderedAt)]);

    final results = await query.get();
    return results.map((row) {
      return OrderWithDetails(
        order: row.readTable(orders),
        product: row.readTable(products),
        storeName: row.readTable(stores).storeName,
        buyerName: row.readTable(users).fullName,
      );
    }).toList();
  }

  // Update order status
  Future<int> updateOrderStatus(int orderId, String status) {
    return (update(orders)..where((o) => o.id.equals(orderId)))
        .write(OrdersCompanion(status: Value(status)));
  }

  // Update order with payment confirmation
  Future<int> confirmPayment(int orderId) {
    return (update(orders)..where((o) => o.id.equals(orderId)))
        .write(OrdersCompanion(
      status: const Value('packing'),
      paidAt: Value(DateTime.now()),
    ));
  }

  // Mark order as delivered
  Future<int> markAsDelivered(int orderId) {
    return (update(orders)..where((o) => o.id.equals(orderId)))
        .write(OrdersCompanion(
      status: const Value('delivery'),
      deliveredAt: Value(DateTime.now()),
    ));
  }

  // Mark order as finished
  Future<int> markAsFinished(int orderId) {
    return (update(orders)..where((o) => o.id.equals(orderId)))
        .write(OrdersCompanion(
      status: const Value('finished'),
      finishedAt: Value(DateTime.now()),
    ));
  }

  // Get order by ID
  Future<Order?> getOrderById(int orderId) {
    return (select(orders)..where((o) => o.id.equals(orderId))).getSingleOrNull();
  }

  // Delete order (admin only)
  Future<int> deleteOrder(int orderId) {
    return (delete(orders)..where((o) => o.id.equals(orderId))).go();
  }

  // Get expired payment orders (30 minutes passed)
  Future<List<Order>> getExpiredPaymentOrders() {
    return (select(orders)
          ..where((o) =>
              o.status.equals('payment') &
              o.paymentDeadline.isSmallerThanValue(DateTime.now())))
        .get();
  }
}
