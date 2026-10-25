class ServerException implements Exception {
  const ServerException(this.message, {this.detail});
  final String message;

  /// Texto que manda el backend junto al código (por ejemplo, qué campo de
  /// una pregunta es inválido). Puede no venir.
  final String? detail;
}
