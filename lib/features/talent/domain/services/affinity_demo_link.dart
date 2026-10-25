/// Demo de la encuesta de afinidad: la misma pantalla que ve el candidato,
/// con datos de ejemplo y sin guardar nada. Es pública (no requiere sesión).
abstract final class AffinityDemoLink {
  static const path = '/afinidad/demo';

  static bool matches(Uri uri) {
    final clean = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (clean == path) return true;
    final fragment = uri.fragment.startsWith('/')
        ? uri.fragment
        : '/${uri.fragment}';
    return fragment.split('?').first.replaceFirst(RegExp(r'/+$'), '') == path;
  }

  static String url({required Uri base}) => '${base.origin}$path';
}
