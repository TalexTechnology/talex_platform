abstract final class CultureSurveyLink {
  static const path = '/cultura';

  static String? organizationIdFromUri(Uri uri) {
    return _fromFragment(uri.fragment) ?? _fromPath(uri);
  }

  static String? organizationIdFromFragment(String fragment) {
    return _fromFragment(fragment);
  }

  static String? _fromPath(Uri uri) {
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    final match = RegExp(r'^/cultura/([^/]+)$').firstMatch(path);
    if (match != null) {
      final id = match.group(1)?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    if (uri.path != path && !uri.path.endsWith(path)) return null;
    final org = uri.queryParameters['org']?.trim();
    return org == null || org.isEmpty ? null : org;
  }

  static String? _fromFragment(String fragment) {
    if (fragment.trim().isEmpty) return null;
    final clean = fragment.startsWith('#') ? fragment.substring(1) : fragment;
    final normalized = clean.startsWith('/') ? clean : '/$clean';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;
    if (uri.path == path || uri.path.endsWith(path)) {
      final org = uri.queryParameters['org']?.trim();
      if (org != null && org.isNotEmpty) return org;
    }
    final match = RegExp(r'^/cultura/([^/?#]+)').firstMatch(normalized);
    return match?.group(1);
  }
}
