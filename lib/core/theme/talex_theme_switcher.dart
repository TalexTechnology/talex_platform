import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/theme/theme_cubit.dart';

// Cambio de tema con revelado circular: se congela una imagen de la pantalla
// con el tema actual, se aplica el nuevo debajo y un círculo que nace en el
// punto tocado (el botón) va abriendo la imagen vieja hasta mostrar el tema
// nuevo completo. Con "reducir movimiento" el cambio es inmediato.
//
// Va dentro de MaterialApp.builder para cubrir también diálogos y avisos.
class TalexThemeSwitcher extends StatefulWidget {
  const TalexThemeSwitcher({super.key, required this.child});

  final Widget child;

  static TalexThemeSwitcherState of(BuildContext context) =>
      context.findAncestorStateOfType<TalexThemeSwitcherState>()!;

  @override
  State<TalexThemeSwitcher> createState() => TalexThemeSwitcherState();
}

class TalexThemeSwitcherState extends State<TalexThemeSwitcher>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  ui.Image? _snapshot;
  Offset _origin = Offset.zero;

  bool get _busy => _snapshot != null;

  /// Cambia al brillo contrario; el círculo sale desde [origin] (coordenadas
  /// globales, normalmente el centro del botón).
  Future<void> toggle({Offset? origin}) {
    final cubit = context.read<ThemeCubit>();
    return _transition(origin, cubit.toggle);
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
      await cubit.setMode(mode);
      return;
    }
    await _transition(origin, () => cubit.setMode(mode));
  }

  Future<void> _transition(
    Offset? origin,
    Future<void> Function() apply,
  ) async {
    if (_busy) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      await apply();
      return;
    }
    final image = await _capture();
    if (!mounted) return;
    if (image == null) {
      await apply();
      return;
    }
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _snapshot = image;
      _origin = origin ?? Offset(size.width / 2, size.height / 2);
    });
    await apply();
    await _reveal.forward(from: 0);
    if (!mounted) return;
    setState(() => _snapshot = null);
    image.dispose();
  }

  Future<ui.Image?> _capture() async {
    try {
      final boundary =
          _boundary.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) return null;
      return await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      // Si el motor no permite capturar, se cambia sin animación.
      return null;
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
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
          if (snapshot != null)
            Positioned.fill(
              child: AbsorbPointer(
                child: AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) => ClipPath(
                    clipper: _HoleClipper(
                      center: _origin,
                      progress: Curves.easeInOutCubic.transform(_reveal.value),
                    ),
                    child: RawImage(
                      image: snapshot,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
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

// Toda la pantalla menos un círculo que crece desde [center] hasta cubrir la
// esquina más lejana.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper({required this.center, required this.progress});

  final Offset center;
  final double progress;

  @override
  Path getClip(Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final reach = corners
        .map((corner) => (corner - center).distance)
        .reduce(math.max);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: reach * progress));
  }

  @override
  bool shouldReclip(_HoleClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.center != center;
}
