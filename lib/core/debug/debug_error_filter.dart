import 'package:flutter/foundation.dart';

// Silencia en debug una aserción conocida del motor web de Flutter: al hacer
// scroll con el trackpad de un Mac, el motor crea un PointerMoveEvent de tipo
// trackpad y el framework lo rechaza (events.dart, `!identical(kind,
// PointerDeviceKind.trackpad)`). No viene del código de la app y en release
// no existe porque las aserciones se eliminan. Cualquier otro error pasa
// intacto al manejador original.
void installDebugErrorFilter() {
  if (!kDebugMode) return;
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isTrackpadAssertion(details)) return;
    (original ?? FlutterError.presentError)(details);
  };
}

bool _isTrackpadAssertion(FlutterErrorDetails details) {
  final error = details.exception;
  return error is AssertionError &&
      details.library == 'gestures library' &&
      '$error'.contains('PointerDeviceKind.trackpad');
}
