import '../models/prefetch_mode.dart';

class ServerConfig {
  const ServerConfig();

  static const baseUrl = 'https://swarved.duckdns.org';

  Uri get healthUri => Uri.parse('$baseUrl/health');

  /// Where the audio of one YouTube song is streamed from.
  Uri playUri(String videoId) {
    return Uri.parse('$baseUrl/api/play').replace(
      queryParameters: {'id': videoId},
    );
  }

  /// Where a search for [query] goes. The query is encoded for the URL here,
  /// so spaces and non-English letters travel safely.
  Uri searchUri(String query, {int limit = 10}) {
    return Uri.parse('$baseUrl/api/search').replace(
      queryParameters: {'q': query, 'limit': '$limit'},
    );
  }

  /// Where the server hands over one song as a finished, tagged MP3. Empty
  /// details are left out, so the server never receives a blank one.
  Uri exportUri(
    String videoId, {
    String? title,
    String? artist,
    String? cover,
  }) {
    return Uri.parse('$baseUrl/api/export').replace(
      queryParameters: {
        'id': videoId,
        if (title != null && title.isNotEmpty) 'title': title,
        if (artist != null && artist.isNotEmpty) 'artist': artist,
        if (cover != null && cover.isNotEmpty) 'cover': cover,
      },
    );
  }

  /// Where the server is asked to get songs ready ahead of time.
  Uri prefetchUri(List<String> videoIds, PrefetchMode mode) {
    return Uri.parse('$baseUrl/api/prefetch').replace(
      queryParameters: {'ids': videoIds.join(','), 'mode': mode.name},
    );
  }
}
