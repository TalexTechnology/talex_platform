abstract final class AssessmentInviteLink {
  static const path = '/assessment';

  static String? tokenFromUri(Uri uri) {
    final fromFragment = tokenFromFragment(uri.fragment);
    if (fromFragment != null) return fromFragment;
    if (uri.path != path && !uri.path.endsWith(path)) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static String? tokenFromFragment(String fragment) {
    if (fragment.trim().isEmpty) return null;
    final clean = fragment.startsWith('#') ? fragment.substring(1) : fragment;
    final normalized = clean.startsWith('/') ? clean : '/$clean';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.path != path) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }
}
