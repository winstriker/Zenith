import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/search.dart';

void main() {
  group('searchTokens', () {
    test('splits on any whitespace and lowercases', () {
      expect(searchTokens('  LIMC   D-KBFF\t'), ['limc', 'd-kbff']);
    });

    test('blank query has no tokens', () {
      expect(searchTokens('   '), isEmpty);
    });
  });

  group('matchesAllTokens', () {
    const flight = ['LIMC', 'Milano Malpensa', 'LEVC', 'Valencia', 'D-KBFF'];

    test('words may hit different fields', () {
      expect(matchesAllTokens(searchTokens('LIMC D-KBFF'), flight), isTrue);
      expect(matchesAllTokens(searchTokens('d-kbff levc'), flight), isTrue);
    });

    test('every word must hit some field', () {
      expect(matchesAllTokens(searchTokens('LIMC D-EABC'), flight), isFalse);
    });

    test('matches substrings and ignores null fields', () {
      expect(matchesAllTokens(['malp'], [null, 'Milano Malpensa']), isTrue);
    });

    test('no tokens matches everything', () {
      expect(matchesAllTokens(const [], const <String?>[]), isTrue);
    });
  });
}
