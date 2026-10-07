class ServerConfig {
  const ServerConfig();

  static const baseUrl = 'https://swarved.duckdns.org';

  Uri get healthUri => Uri.parse('$baseUrl/health');

  /// Where a search for [query] goes. The query is encoded for the URL here,
  /// so spaces and non-English letters travel safely.
  Uri searchUri(String query, {int limit = 10}) {
    return Uri.parse('$baseUrl/api/search').replace(
      queryParameters: {'q': query, 'limit': '$limit'},
    );
  }
}
