import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/search.dart';
import 'package:zenith/services/database.dart';

void main() {
  group('searchTokens', () {
    test('splits on any whitespace and lowercases', () {
      expect(searchTokens('  LIMC   D-KBFF\t'), ['limc', 'd-kbff']);
    });

    test('blank query has no tokens', () {
      expect(searchTokens('   '), isEmpty);
    });
  });

  group('sqlMatchesAllTokens', () {
    late LogbookDatabase db;
    setUp(() => db = LogbookDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    /// Whether [query] matches the given fields, evaluated by SQLite.
    Future<bool> matches(String query, List<String?> fields) async {
      final expr = sqlMatchesAllTokens(searchTokens(query), [
        for (final f in fields) Variable<String>(f),
      ]);
      final row = await db.selectExpressions([expr]).getSingle();
      return row.read(expr) ?? false;
    }

    const flight = ['LIMC', 'Milano Malpensa', 'LEVC', 'Valencia', 'D-KBFF'];

    test('words may hit different fields', () async {
      expect(await matches('LIMC D-KBFF', flight), isTrue);
      expect(await matches('d-kbff levc', flight), isTrue);
    });

    test('every word must hit some field', () async {
      expect(await matches('LIMC D-EABC', flight), isFalse);
    });

    test('matches substrings and ignores null fields', () async {
      expect(await matches('malp', [null, 'Milano Malpensa']), isTrue);
      expect(await matches('malp', [null]), isFalse);
    });

    test('wildcards are taken literally', () async {
      expect(await matches('50%', ['Fuel 50% left']), isTrue);
      expect(await matches('5%', ['Fuel 50 left']), isFalse);
      expect(await matches('i_a', ['I-ABCD']), isFalse);
    });

    test('no tokens matches everything', () async {
      expect(await matches('', const []), isTrue);
    });
  });
}
