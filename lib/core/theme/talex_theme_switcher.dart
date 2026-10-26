import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/theme/theme_cubit.dart';

// Cambio de tema con revelado circular que nace en el botón.
//
// 1. En el mismo cuadro del toque sale del botón un círculo con el fondo del
//    tema nuevo (respuesta inmediata, sin trabajo pesado).
// 2. Mientras crece, se congela una imagen de la pantalla con el tema actual
//    (empieza ya al presionar, ver [prepare]) y se aplica el tema nuevo debajo.
// 3. El revelado real sigue desde el radio que llevaba el círculo y abre la
//    imagen vieja hasta mostrar el tema nuevo completo.
//
// Con "reducir movimiento" el cambio es inmediato. Va dentro de
// MaterialApp.builder para cubrir también diálogos y avisos.
class TalexThemeSwitcher extends StatefulWidget {
  const TalexThemeSwitcher({super.key, required this.child});

  final Widget child;

  static TalexThemeSwitcherState of(BuildContext context) =>
      context.findAncestorStateOfType<TalexThemeSwitcherState>()!;

  @override
  State<TalexThemeSwitcher> createState() => TalexThemeSwitcherState();
}

class TalexThemeSwitcherState extends State<TalexThemeSwitcher>
    with TickerProviderStateMixin {
  static const _seedReach = 96.0;

  final _boundary = GlobalKey();
  late final AnimationController _seed = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  // Curva estándar de la landing (--ease-out): rápida al salir, suave al final.
  static const _ease = Cubic(0.2, 0.7, 0.2, 1);

  Future<ui.Image?>? _precapture;
  ui.Image? _snapshot;
  var _running = false;
  var _seedVisible = false;
  var _seedColor = Colors.transparent;
  var _startRadius = 0.0;
  Offset _origin = Offset.zero;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  /// Empieza a capturar la pantalla antes del toque (al presionar el botón),
  /// para que el cambio arranque sin espera al soltar.
  void prepare() {
    if (_running || _reduceMotion) return;
    _precapture ??= _capture();
  }

  /// El toque se canceló: descarta la captura adelantada.
  void cancelPrepare() {
    final pending = _precapture;
    _precapture = null;
    pending?.then((image) => image?.dispose());
  }

  /// Cambia al brillo contrario; el círculo sale desde [origin] (coordenadas
  /// globales, normalmente el centro del botón).
  Future<void> toggle({Offset? origin}) {
    final cubit = context.read<ThemeCubit>();
    final target = cubit.state.isDark ? Brightness.light : Brightness.dark;
    return _transition(origin, target, cubit.toggle);
  }

  /// Aplica [mode]; solo anima si el brillo visible cambia.
  Future<void> setMode(ThemeMode mode, {Offset? origin}) async {
    final cubit = context.read<ThemeCubit>();
    final target = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    if (target == cubit.state.brightness) {
      cancelPrepare();
      await cubit.setMode(mode);
      return;
    }
    await _transition(origin, target, () => cubit.setMode(mode));
  }

  Future<void> _transition(
    Offset? origin,
    Brightness target,
    Future<void> Function() apply,
  ) async {
    if (_running) return;
    if (_reduceMotion) {
      cancelPrepare();
      await apply();
      return;
    }
    _running = true;
    final size = MediaQuery.sizeOf(context);
    // 1. Respuesta inmediata desde el botón.
    setState(() {
      _origin = origin ?? Offset(size.width / 2, size.height / 2);
      _seedColor =
          (target == Brightness.dark ? TalexPalette.dark : TalexPalette.light)
              .bg;
      _seedVisible = true;
      _startRadius = 0;
    });
    _seed.forward(from: 0);

    // 2. Imagen del tema actual y tema nuevo debajo.
    final image = await (_precapture ?? _capture());
    _precapture = null;
    if (!mounted) return;
    if (image == null) {
      await apply();
      _finish();
      return;
    }
    setState(() => _snapshot = image);
    await WidgetsBinding.instance.endOfFrame;
    await apply();
    // El tema nuevo reconstruye toda la app en un cuadro pesado; el revelado
    // arranca después para no perder cuadros.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 3. Revelado real desde donde iba el círculo.
    setState(() {
      _startRadius = _seedRadius;
      _seedVisible = false;
    });
    await _reveal.forward(from: 0);
    if (!mounted) return;
    _finish();
    image.dispose();
  }

  double get _seedRadius => _seedReach * _ease.transform(_seed.value);

  void _finish() {
    _seed.reset();
    _reveal.reset();
    setState(() {
      _snapshot = null;
      _seedVisible = false;
      _running = false;
    });
  }

  Future<ui.Image?> _capture() async {
    try {
      final boundary =
          _boundary.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      if (kDebugMode && boundary.debugNeedsPaint) return null;
      // Hasta 1.5x: la imagen solo se ve un instante y capturar a resolución
      // completa en pantallas retina retrasa el arranque.
      return await boundary.toImage(
        pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 1.5),
      );
    } catch (_) {
      // Si el motor no permite capturar, se cambia sin animación.
      return null;
    }
  }

  @override
  void dispose() {
    _seed.dispose();
    _reveal.dispose();
    _snapshot?.dispose();
    cancelPrepare();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ThemeCubit, ThemeState>(
      listenWhen: (previous, current) =>
          previous.brightness != current.brightness,
      // Los colores se leen de AppColors al construir, así que todo el árbol
      // se vuelve a construir (conservando su estado) con la paleta nueva.
      listener: (context, _) => _rebuildAll(),
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          RepaintBoundary(key: _boundary, child: widget.child),
          if (_running)
            Positioned.fill(
              child: AbsorbPointer(
                // Solo repinta en cada cuadro; no reconstruye widgets.
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RevealPainter(
                      image: _snapshot,
                      center: _origin,
                      seedColor: _seedVisible ? _seedColor : null,
                      seedRadius: () => _seedRadius,
                      startRadius: _startRadius,
                      reveal: _reveal,
                      repaint: Listenable.merge([_seed, _reveal]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _rebuildAll() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}

// Pinta la imagen del tema anterior en toda la pantalla menos un círculo que
// crece desde [center] hasta la esquina más lejana. Antes de que exista la
// imagen (o mientras se aplica el tema) pinta el círculo inicial con el fondo
// del tema nuevo.
class _RevealPainter extends CustomPainter {
  _RevealPainter({
    required this.image,
    required this.center,
    required this.seedColor,
    required this.seedRadius,
    required this.startRadius,
    required this.reveal,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final ui.Image? image;
  final Offset center;
  final Color? seedColor;
  final double Function() seedRadius;
  final double startRadius;
  final Animation<double> reveal;

  static const _ease = Cubic(0.2, 0.7, 0.2, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image != null) {
      final reach = [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ].map((corner) => (corner - center).distance).reduce(math.max);
      final radius = ui.lerpDouble(
        startRadius,
        reach,
        _ease.transform(reveal.value),
      )!;
      final screen = Offset.zero & size;
      canvas
        ..save()
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(screen)
            ..addOval(Rect.fromCircle(center: center, radius: radius)),
        )
        ..drawImageRect(
          image,
          Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
          screen,
          Paint()..filterQuality = FilterQuality.low,
        )
        ..restore();
    }
    final seedColor = this.seedColor;
    if (seedColor != null) {
      canvas.drawCircle(center, seedRadius(), Paint()..color = seedColor);
    }
  }

  @override
  bool shouldRepaint(_RevealPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.center != center ||
      oldDelegate.seedColor != seedColor ||
      oldDelegate.startRadius != startRadius;
}
