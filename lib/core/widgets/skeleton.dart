import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';

// Placeholders de carga con la forma del contenido que viene. [Skeleton]
// anima la opacidad de todo su subárbol con un solo controlador, así que los
// bloques internos ([SkeletonBox], [SkeletonCard]) son estáticos y baratos.

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(opacity: _pulse, child: widget.child),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE9EAEE),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// Mismo marco que los paneles blancos del dashboard.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFC9CBD1)),
      borderRadius: AppRadii.border,
    ),
    child: child,
  );
}

// Título y subtítulo de página.
class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonBox(width: 280, height: 36, radius: 8),
      SizedBox(height: 14),
      FractionallySizedBox(
        widthFactor: 0.55,
        child: SkeletonBox(height: 16),
      ),
    ],
  );
}

// Fila de tarjetas de métricas.
class SkeletonStats extends StatelessWidget {
  const SkeletonStats({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (var index = 0; index < count; index++)
        const SizedBox(
          width: 180,
          child: SkeletonCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 56, height: 28),
                  SizedBox(height: 10),
                  SkeletonBox(width: 110, height: 14),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

// Un elemento de lista: título, metadatos y una línea de detalle.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key, this.trailing = true});

  final bool trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: 0.4,
                child: SkeletonBox(height: 18),
              ),
              SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: SkeletonBox(height: 14),
              ),
              SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: SkeletonBox(height: 14),
              ),
            ],
          ),
        ),
        if (trailing) ...[
          const SizedBox(width: 16),
          const SkeletonBox(width: 84, height: 28),
        ],
      ],
    ),
  );
}

// Lista de [count] elementos. [separate] los dibuja como tarjetas sueltas;
// si no, van dentro de un solo panel con divisores.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5, this.separate = false});

  final int count;
  final bool separate;

  @override
  Widget build(BuildContext context) {
    if (separate) {
      return Column(
        children: [
          for (var index = 0; index < count; index++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonCard(child: SkeletonListTile()),
            ),
        ],
      );
    }
    return SkeletonCard(
      child: Column(
        children: [
          for (var index = 0; index < count; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.divider),
            const SkeletonListTile(),
          ],
        ],
      ),
    );
  }
}

// Página completa del dashboard: encabezado, métricas opcionales y lista.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key, this.stats = 4, this.rows = 5});

  final int stats;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(compact ? 18 : 40),
      child: Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SkeletonHeader(),
            const SizedBox(height: 28),
            if (stats > 0) ...[
              SkeletonStats(count: stats),
              const SizedBox(height: 24),
            ],
            SkeletonList(count: rows),
          ],
        ),
      ),
    );
  }
}

// Tarjeta centrada: título, párrafo y botón (pantallas tipo bienvenida).
class SkeletonCenteredCard extends StatelessWidget {
  const SkeletonCenteredCard({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: const Skeleton(
          child: SkeletonCard(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 72, height: 72, radius: 36),
                  SizedBox(height: 24),
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: SkeletonBox(height: 28, radius: 8),
                  ),
                  SizedBox(height: 18),
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: SkeletonBox(height: 14),
                  ),
                  SizedBox(height: 28),
                  SkeletonBox(height: 48, radius: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
