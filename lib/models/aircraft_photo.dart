/// The photo of an aircraft: either a file the user picked, kept in the app's
/// aircraft photo folder, or a photo found online, of which only the links
/// are kept.
class AircraftPhoto {
  /// A photo the user picked. [file] is its name in the aircraft photo folder.
  const AircraftPhoto.file(String this.file)
    : url = null,
      thumbnailUrl = null,
      link = null,
      credit = null;

  /// A photo that stays online.
  const AircraftPhoto.online({
    required String this.url,
    String? thumbnailUrl,
    this.link,
    this.credit,
  }) : file = null,
       thumbnailUrl = thumbnailUrl ?? url;

  /// Builds the photo out of stored columns. Null when there is none.
  static AircraftPhoto? fromColumns({
    String? file,
    String? url,
    String? thumbnailUrl,
    String? link,
    String? credit,
  }) {
    if (file != null) return AircraftPhoto.file(file);
    if (url == null) return null;
    return AircraftPhoto.online(
      url: url,
      thumbnailUrl: thumbnailUrl,
      link: link,
      credit: credit,
    );
  }

  final String? file;

  /// Full size picture.
  final String? url;

  /// Small picture, for lists.
  final String? thumbnailUrl;

  /// Page the photo comes from.
  final String? link;

  /// Who took the photo.
  final String? credit;

  bool get isOnline => file == null;

  /// Name of the site an online photo comes from, to credit it.
  String? get source {
    final host = Uri.tryParse(link ?? url ?? '')?.host.toLowerCase() ?? '';
    if (host.isEmpty) return null;
    if (host.endsWith('jetphotos.com')) return 'JetPhotos';
    if (_isPlanespotters(host)) return 'Planespotters.net';
    if (host.endsWith('airport-data.com')) return 'Airport-Data.com';
    if (host.endsWith('hexdb.io')) return 'hexdb.io';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static bool _isPlanespotters(String host) =>
      host.endsWith('planespotters.net') || host.endsWith('plnspttrs.net');

  @override
  bool operator ==(Object other) =>
      other is AircraftPhoto &&
      other.file == file &&
      other.url == url &&
      other.thumbnailUrl == thumbnailUrl &&
      other.link == link &&
      other.credit == credit;

  @override
  int get hashCode => Object.hash(file, url, thumbnailUrl, link, credit);
}
