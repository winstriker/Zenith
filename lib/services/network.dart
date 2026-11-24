import 'dart:async';
import 'dart:typed_data';

/// How long a request waits for an answer, and a download for its next
/// bytes, before giving up.
const networkTimeout = Duration(seconds: 30);

/// How long one chunk of an upload may take.
const uploadChunkTimeout = Duration(minutes: 2);

/// The server stopped answering.
class NetworkTimeout extends TimeoutException {
  NetworkTimeout(Duration duration)
    : super('No answer from the server', duration);

  @override
  String toString() =>
      'No answer from the server for ${duration!.inSeconds} seconds. '
      'Check the internet connection and try again.';
}

extension NetworkTimeoutFuture<T> on Future<T> {
  /// Fails with a [NetworkTimeout] after [duration].
  Future<T> withTimeout([Duration duration = networkTimeout]) =>
      timeout(duration, onTimeout: () => throw NetworkTimeout(duration));
}

extension NetworkTimeoutStream<T> on Stream<T> {
  /// Fails with a [NetworkTimeout] when nothing arrives for [duration].
  Stream<T> withIdleTimeout([Duration duration = networkTimeout]) => timeout(
    duration,
    onTimeout: (sink) => sink
      ..addError(NetworkTimeout(duration))
      ..close(),
  );
}

/// Reads a download whole, failing when it stalls. [onProgress] gets the
/// fraction received when the size is known ([total], else null).
Future<Uint8List> readDownload(
  Stream<List<int>> body, {
  int? total,
  void Function(double fraction)? onProgress,
}) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in body.withIdleTimeout()) {
    bytes.add(chunk);
    if (total != null && total > 0) {
      onProgress?.call((bytes.length / total).clamp(0, 1));
    }
  }
  return bytes.takeBytes();
}
