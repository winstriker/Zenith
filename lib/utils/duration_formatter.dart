/// Utility class for formatting durations in various display formats.
class DurationFormatter {
  DurationFormatter._();

  /// Format as H:MM:SS: '1:02:30'
  static String hms(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format as MM:SS: '02:30'
  static String hm(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Format as descriptive: '2h 30m'
  static String descriptive(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Format with label: 'Duration: 2:30'
  static String withLabel(
    Duration duration, {
    String label = 'Duration',
    String format = 'compact',
  }) {
    final formatted = switch (format) {
      'hms' => hms(duration),
      'hm' => hm(duration),
      'descriptive' => descriptive(duration),
      _ => hm(duration),
    };
    return '$label: $formatted';
  }
}
