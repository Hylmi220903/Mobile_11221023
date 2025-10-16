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
  TextColumn get storeName => text().withLength(min: 1, max: 255)();
  TextColumn get phoneNumber => text().withLength(min: 6, max: 14)();
  TextColumn get password => text().withLength(min: 8)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Create singleton instance
  static AppDatabase? _instance;
  
  static Future<AppDatabase> getInstance() async {
    if (_instance == null) {
      _instance = AppDatabase();
    }
    return _instance!;
  }

  // Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register new user
  Future<int> registerUser({
    required String fullName,
    required String email,
    required String storeName,
    required String phoneNumber,
    required String password,
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
        storeName: storeName,
        phoneNumber: phoneNumber,
        password: hashedPassword,
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
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final connection = await impl.connect();
    return connection.executor;
  });
}
