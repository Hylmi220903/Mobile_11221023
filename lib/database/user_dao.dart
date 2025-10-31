part of 'database.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  // Register new user
  Future<int> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String storeName,
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
    final hashedPassword = db.hashPassword(password);
    
    return await into(users).insert(
      UsersCompanion.insert(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: hashedPassword,
        storeName: storeName,
      ),
    );
  }

  // Login user
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    final hashedPassword = db.hashPassword(password);
    
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
}
