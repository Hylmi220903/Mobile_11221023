part of 'database.dart';

@DriftAccessor(tables: [Addresses])
class AddressDao extends DatabaseAccessor<AppDatabase> with _$AddressDaoMixin {
  AddressDao(super.db);

  // Add new address
  Future<int> addAddress({
    required int userId,
    required String recipientName,
    required String phoneNumber,
    required String province,
    required String city,
    required String district,
    required String postalCode,
    required String streetAddress,
    String? detailAddress,
    bool isMainAddress = false,
    bool isStoreAddress = false,
  }) async {
    // If setting as main address, unset other main addresses for this user
    if (isMainAddress) {
      await (update(addresses)..where((tbl) => tbl.userId.equals(userId)))
          .write(const AddressesCompanion(isMainAddress: Value(false)));
    }

    // If setting as store address, unset other store addresses for this user
    if (isStoreAddress) {
      await (update(addresses)..where((tbl) => tbl.userId.equals(userId)))
          .write(const AddressesCompanion(isStoreAddress: Value(false)));
    }

    return await into(addresses).insert(
      AddressesCompanion.insert(
        userId: userId,
        recipientName: recipientName,
        phoneNumber: phoneNumber,
        province: province,
        city: city,
        district: district,
        postalCode: postalCode,
        streetAddress: streetAddress,
        detailAddress: Value(detailAddress),
        isMainAddress: Value(isMainAddress),
        isStoreAddress: Value(isStoreAddress),
      ),
    );
  }

  // Get all addresses for a user
  Future<List<AddressesData>> getAddressesByUser(int userId) {
    return (select(addresses)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            // Main address first, then store address, then by created date
            (tbl) => OrderingTerm(expression: tbl.isMainAddress, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.isStoreAddress, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  // Get address by ID
  Future<AddressesData?> getAddressById(int addressId) {
    return (select(addresses)..where((tbl) => tbl.id.equals(addressId)))
        .getSingleOrNull();
  }

  // Get main address for a user
  Future<AddressesData?> getMainAddress(int userId) {
    return (select(addresses)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.isMainAddress.equals(true)))
        .getSingleOrNull();
  }

  // Get store address for a user
  Future<AddressesData?> getStoreAddress(int userId) {
    return (select(addresses)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.isStoreAddress.equals(true)))
        .getSingleOrNull();
  }

  // Update address
  Future<int> updateAddress({
    required int addressId,
    required int userId,
    required String recipientName,
    required String phoneNumber,
    required String province,
    required String city,
    required String district,
    required String postalCode,
    required String streetAddress,
    String? detailAddress,
    bool isMainAddress = false,
    bool isStoreAddress = false,
  }) async {
    // If setting as main address, unset other main addresses for this user
    if (isMainAddress) {
      await (update(addresses)
            ..where((tbl) => tbl.userId.equals(userId) & tbl.id.equals(addressId).not()))
          .write(const AddressesCompanion(isMainAddress: Value(false)));
    }

    // If setting as store address, unset other store addresses for this user
    if (isStoreAddress) {
      await (update(addresses)
            ..where((tbl) => tbl.userId.equals(userId) & tbl.id.equals(addressId).not()))
          .write(const AddressesCompanion(isStoreAddress: Value(false)));
    }

    return await (update(addresses)..where((tbl) => tbl.id.equals(addressId)))
        .write(AddressesCompanion(
      recipientName: Value(recipientName),
      phoneNumber: Value(phoneNumber),
      province: Value(province),
      city: Value(city),
      district: Value(district),
      postalCode: Value(postalCode),
      streetAddress: Value(streetAddress),
      detailAddress: Value(detailAddress),
      isMainAddress: Value(isMainAddress),
      isStoreAddress: Value(isStoreAddress),
    ));
  }

  // Delete address
  Future<int> deleteAddress(int addressId) {
    return (delete(addresses)..where((tbl) => tbl.id.equals(addressId))).go();
  }

  // Get address count for a user
  Future<int> getAddressCount(int userId) async {
    final result = await (select(addresses)
          ..where((tbl) => tbl.userId.equals(userId)))
        .get();
    return result.length;
  }

  // Set as main address
  Future<void> setAsMainAddress(int addressId, int userId) async {
    // Unset all main addresses for this user
    await (update(addresses)..where((tbl) => tbl.userId.equals(userId)))
        .write(const AddressesCompanion(isMainAddress: Value(false)));

    // Set selected address as main
    await (update(addresses)..where((tbl) => tbl.id.equals(addressId)))
        .write(const AddressesCompanion(isMainAddress: Value(true)));
  }

  // Set as store address
  Future<void> setAsStoreAddress(int addressId, int userId) async {
    // Unset all store addresses for this user
    await (update(addresses)..where((tbl) => tbl.userId.equals(userId)))
        .write(const AddressesCompanion(isStoreAddress: Value(false)));

    // Set selected address as store
    await (update(addresses)..where((tbl) => tbl.id.equals(addressId)))
        .write(const AddressesCompanion(isStoreAddress: Value(true)));
  }
}
