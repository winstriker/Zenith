import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database.dart';

/// Single access point to the app database. Override in tests with an
/// in-memory [LogbookDatabase].
final databaseProvider = Provider<LogbookDatabase>((ref) {
  return LogbookDatabase();
});
