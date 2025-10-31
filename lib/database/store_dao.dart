part of 'database.dart';

@DriftAccessor(tables: [Stores])
class StoreDao extends DatabaseAccessor<AppDatabase> with _$StoreDaoMixin {
  StoreDao(super.db);

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
}
