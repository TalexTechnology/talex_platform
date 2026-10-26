abstract final class CultureSurveyLink {
  static const path = '/cultura';

  /// Enlace de vista previa de la encuesta tal como la ve el equipo de
  /// [organizationId]. `culture_survey_boot.js` lo atiende con `?demo=1`:
  /// se puede completar entera pero no envía respuestas.
  static String demoUrl(String organizationId, {required Uri base}) =>
      '${base.origin}$path/${Uri.encodeComponent(organizationId)}?demo=1';

  /// Clave de localStorage donde el admin deja el banco de preguntas activo
  /// para [previewUrl]; debe coincidir con `culture_survey_boot.js`.
  static const previewStorageKey = 'talex.cultureSurveyPreview';

  /// Vista previa sin empresa: la encuesta se arma con el banco guardado en
  /// [previewStorageKey] y las opciones por defecto de cada pregunta.
  static String previewUrl({required Uri base}) =>
      '${base.origin}$path/preview?demo=1';

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
