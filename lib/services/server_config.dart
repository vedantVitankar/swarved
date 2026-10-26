import '../models/prefetch_mode.dart';
import '../utils/app_profile.dart';

class ServerConfig {
  const ServerConfig({this.profile = AppProfile.swarnima});

  /// Whose data the server should use for content and playlists. Hers is the
  /// server's default, so it is never sent: copies of the app that came
  /// before profiles existed keep working as hers.
  final String profile;

  /// [path] on the server, naming the profile unless it is hers.
  Uri _profiled(String path) {
    final uri = Uri.parse('$baseUrl$path');
    if (profile == AppProfile.swarnima) return uri;
    return uri.replace(queryParameters: {'profile': profile});
  }

  static const baseUrl = 'https://swarved.duckdns.org';

  Uri get healthUri => Uri.parse('$baseUrl/health');

  /// What he has published for her: notes, memories and the rest.
  Uri get contentUri => _profiled('/api/content');

  /// The same, but the server holds the request open until he publishes
  /// something new, so the app can update while it is open.
  Uri get contentWaitUri => _profiled('/api/content/wait');

  /// Where the app tells the server what playlists she has, so he can see
  /// them (and write notes on her songs) in the admin site.
  Uri get playlistsReportUri => _profiled('/api/playlists/report');

  /// Where the app reads back the playlists the server holds for her, so
  /// her other devices can merge them into their own.
  Uri get playlistsUri => _profiled('/api/playlists');

  /// Where the app says which of his recordings have played, so the admin
  /// site can mark each one.
  Uri get voicesPlayedUri => _profiled('/api/voices/played');

  /// Where the app says which letters she has opened.
  Uri get lettersOpenedUri => _profiled('/api/letters/opened');

  /// The newest release of the app itself for [platform]. The server
  /// answers with nothing (204) when none is published for this profile.
  Uri appUpdateUri(String platform) {
    final uri = _profiled('/api/app-update');
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'platform': platform},
    );
  }

  /// One installer, by the name the release gives.
  Uri appUpdateFileUri(String file) =>
      _profiled('/api/app-update/file/${Uri.encodeComponent(file)}');

  /// One uploaded photo or recording, by the name the server gave it.
  /// Photos and recordings belong to a profile on the server, so this names
  /// the profile like content does.
  Uri mediaUri(String file) =>
      _profiled('/api/media/${Uri.encodeComponent(file)}');

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
