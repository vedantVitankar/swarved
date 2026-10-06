class ServerConfig {
  const ServerConfig();

  static const baseUrl = 'https://swarved.duckdns.org';

  Uri get healthUri => Uri.parse('$baseUrl/health');
}
