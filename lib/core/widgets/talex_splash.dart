import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';

// Pantalla de carga de marca: el logo respira, una barra con el degradado de
// TaleX recorre la pista y los [messages] avanzan uno a uno (se queda en el
// último). Respeta "reducir movimiento" del sistema.
class TalexSplash extends StatefulWidget {
  const TalexSplash({super.key, required this.messages});

  final List<String> messages;

  @override
  State<TalexSplash> createState() => _TalexSplashState();
}

class _TalexSplashState extends State<TalexSplash>
    with TickerProviderStateMixin {
  static const _step = Duration(milliseconds: 1800);

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _startMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.value = 1;
      _sweep.value = 0.5;
    } else {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
      if (!_sweep.isAnimating) _sweep.repeat();
    }
  }

  @override
  void didUpdateWidget(TalexSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMessages(oldWidget.messages, widget.messages)) {
      _index = 0;
      _startMessages();
    }
  }

  bool _sameMessages(List<String> a, List<String> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

  void _startMessages() {
    _timer?.cancel();
    if (widget.messages.length < 2) return;
    _timer = Timer.periodic(_step, (timer) {
      if (_index >= widget.messages.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.messages.isEmpty
        ? ''
        : widget.messages[_index.clamp(0, widget.messages.length - 1)];
    final breath = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 0.9,
            colors: [Color(0x161D7BD6), Color(0x00FBF9FA)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.82, end: 1).animate(breath),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.02).animate(breath),
                  child: const TalexLogo(width: 220, height: 64),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 200,
                height: 3,
                child: _SweepBar(animation: _sweep),
              ),
              const SizedBox(height: 22),
              Semantics(
                liveRegion: true,
                label: message,
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.35),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        message,
                        key: ValueKey(message),
                        style: const TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pista fina con un tramo en degradado azul → verde que la recorre.
class _SweepBar extends StatelessWidget {
  const _SweepBar({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: ColoredBox(
      color: const Color(0xFFE4E9F0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final segment = width * 0.42;
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final t = Curves.easeInOutCubic.transform(animation.value);
              return Stack(
                children: [
                  Positioned(
                    left: -segment + (width + segment) * t,
                    top: 0,
                    bottom: 0,
                    width: segment,
                    child: child!,
                  ),
                ],
              );
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(3)),
                gradient: LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandGreen],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
