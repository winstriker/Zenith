import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'network.dart';

/// The website announcements are published on (GitHub Pages).
const announcementsBaseUrl = String.fromEnvironment("ANNOUNCEMENTS_URL");

/// One announcement: its markdown [file] (relative to the site root), its
/// [title] and [date], and where to download it.
typedef Announcement = ({String file, String title, DateTime date, Uri url});

/// Lists announcements, newest first, and downloads their text.
class AnnouncementService {
  AnnouncementService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Reads `announcements.txt`: one announcement per line as
  /// `YYYY-MM-DD | Title | file.md`. Blank lines, `#` comments and lines
  /// that don't fit are skipped.
  Future<List<Announcement>> list() async =>
      parse(await _get('announcements.txt'));

  static List<Announcement> parse(String text) {
    final items = <Announcement>[];
    for (final line in const LineSplitter().convert(text)) {
      final parts = line.split('|').map((p) => p.trim()).toList();
      final date = parts.length == 3 ? DateTime.tryParse(parts[0]) : null;
      if (date == null || parts[1].isEmpty || parts[2].isEmpty) continue;
      items.add((
        file: parts[2],
        title: parts[1],
        date: date,
        url: Uri.parse('$announcementsBaseUrl/${parts[2]}'),
      ));
    }
    // Stable, so same-day announcements keep their order in the file.
    return items..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<String> fetch(Announcement a) => _get(a.file);

  Future<String> _get(String path) async {
    final response = await _client
        .get(Uri.parse('$announcementsBaseUrl/$path'))
        .withTimeout();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Server replied ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }
}
