import 'package:flutter/material.dart';

// Radios de la landing: --radius (tarjetas), --radius-sm (botones y campos)
// y --radius-pill (chips).
abstract final class AppRadii {
  static const double lg = 16;
  static const double md = 10;
  static const double pill = 999;
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get border => BorderRadius.circular(md);
  static RoundedRectangleBorder get shape =>
      const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(md)));
}
