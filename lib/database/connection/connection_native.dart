import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Native implementation for mobile and desktop platforms
Future<DatabaseConnection> connect() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
  return DatabaseConnection(NativeDatabase.createInBackground(file));
}
