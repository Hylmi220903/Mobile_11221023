import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

// Web implementation using sqlite3_web
Future<DatabaseConnection> connect() async {
  final result = await WasmDatabase.open(
    databaseName: 'app_database',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  return DatabaseConnection(result.resolvedExecutor);
}
