/// URL de la API (MySQL detrás de HTTP). Flutter nunca habla MySQL.
///
/// Por defecto apunta a local. Se puede override con
/// `--dart-define=TALEX_API_URL=...`
class LocalApiConfig {
  const LocalApiConfig({required this.url});

  final String url;

  static const fromEnvironment = LocalApiConfig(
    url: String.fromEnvironment(
      'TALEX_API_URL',
      defaultValue: 'http://127.0.0.1:8080',
    ),
  );

  bool get isConfigured => _isAllowedUrl(url.trim());

  static bool _isAllowedUrl(String value) {
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    const localHosts = {'127.0.0.1', 'localhost', 'host.docker.internal'};
    if (localHosts.contains(uri.host)) return true;
    if (uri.host.startsWith('192.168.') || uri.host.startsWith('10.')) {
      return true;
    }
    return false;
  }
}

bool get isLocalApiReady => LocalApiConfig.fromEnvironment.isConfigured;
