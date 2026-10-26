import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

// Guarda un PDF en el dispositivo desde el navegador.
//
// Funciona igual en Chrome, Edge, Firefox y Safari (también iOS 13+ y
// Android): se crea un Blob, un enlace oculto con `download` y se hace clic.
// Detalles que lo hacen fiable en todos:
// - El enlace se agrega al documento antes del clic (Firefox lo exige).
// - La URL del Blob se libera un minuto después, no al instante: Safari y
//   Firefox empiezan la descarga de forma asíncrona y la cancelan si la URL
//   ya no existe.
// - Si el navegador no soporta `download` (algunos navegadores integrados en
//   apps de iOS), se abre el PDF en el visor para guardarlo o compartirlo.
void savePdfBytes(Uint8List bytes, String filename) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  if (!(anchor as JSObject).has('download')) {
    web.window.location.assign(url);
    return;
  }
  anchor
    ..href = url
    ..download = filename
    ..rel = 'noopener'
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
