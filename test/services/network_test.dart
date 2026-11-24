import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/network.dart';

void main() {
  test('a request that takes too long fails with a NetworkTimeout', () {
    final never = Completer<int>().future;
    expect(
      never.withTimeout(const Duration(milliseconds: 10)),
      throwsA(isA<NetworkTimeout>()),
    );
  });

  test('a download that stalls fails with a NetworkTimeout', () async {
    final body = StreamController<List<int>>();
    body.add([1, 2]);
    final read = body.stream
        .withIdleTimeout(const Duration(milliseconds: 10))
        .toList();
    await expectLater(read, throwsA(isA<NetworkTimeout>()));
    await body.close();
  });

  test('a download reports how much of it arrived', () async {
    final received = <double>[];
    final bytes = await readDownload(
      Stream.fromIterable([
        [1, 2],
        [3, 4],
      ]),
      total: 4,
      onProgress: received.add,
    );
    expect(bytes, [1, 2, 3, 4]);
    expect(received, [0.5, 1]);
  });

  test('the timeout message is meant for the user', () {
    expect(
      NetworkTimeout(networkTimeout).toString(),
      startsWith('No answer from the server for 30 seconds'),
    );
  });
}
