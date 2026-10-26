import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';

// Piezas visuales compartidas del rediseño, calcadas de la landing: paneles
// elevados con borde sutil, eyebrow lima en mayúsculas, títulos con tracking
// negativo y fondos con brillo radial azul/lima.

/// Tono de un chip o ícono destacado.
enum TalexTone { neutral, blue, green, warning, danger }

extension TalexToneColors on TalexTone {
  Color get color => switch (this) {
    TalexTone.neutral => AppColors.textMuted,
    TalexTone.blue => AppColors.blue,
    TalexTone.green => AppColors.green,
    TalexTone.warning => AppColors.warning,
    TalexTone.danger => AppColors.danger,
  };

  Color get background => switch (this) {
    TalexTone.neutral => AppColors.surface2,
    TalexTone.blue => AppColors.blueDim,
    TalexTone.green => AppColors.greenDim,
    TalexTone.warning => AppColors.warningDim,
    TalexTone.danger => AppColors.dangerDim,
  };
}

/// Tarjeta base: superficie elevada, borde de 1 px y radio de 16.
class TalexPanel extends StatelessWidget {
  const TalexPanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final shape = radius ?? AppRadii.card;
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    return Material(
      color: color ?? AppColors.bgRaised,
      shape: RoundedRectangleBorder(
        borderRadius: shape,
        side: BorderSide(color: borderColor ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              hoverColor: AppColors.surface,
              child: content,
            ),
    );
  }
}

/// Texto corto en mayúsculas sobre los títulos (13 px, lima, tracking amplio).
class TalexEyebrow extends StatelessWidget {
  const TalexEyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color ?? AppColors.green,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
    ),
  );
}

/// Encabezado de página: eyebrow opcional, título grande y bajada.
class TalexPageHeader extends StatelessWidget {
  const TalexPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          TalexEyebrow(eyebrow!),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: TextStyle(
            color: AppColors.text,
            fontSize: compact ? 30 : 40,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: compact ? -1 : -1.6,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
    if (actions.isEmpty) return heading;
    final buttons = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: actions,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [heading, const SizedBox(height: 20), buttons],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 24),
        Flexible(child: buttons),
      ],
    );
  }
}

/// Título de sección dentro de una página o panel.
class TalexSectionTitle extends StatelessWidget {
  const TalexSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

/// Chip en forma de píldora con el color del tono.
class TalexPill extends StatelessWidget {
  const TalexPill(
    this.label, {
    super.key,
    this.tone = TalexTone.blue,
    this.icon,
  });

  final String label;
  final TalexTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: tone.color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tone.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Ícono dentro de un cuadro redondeado con fondo tenue del tono.
class TalexIconBadge extends StatelessWidget {
  const TalexIconBadge(
    this.icon, {
    super.key,
    this.tone = TalexTone.blue,
    this.size = 40,
  });

  final IconData icon;
  final TalexTone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Icon(icon, size: size * 0.5, color: tone.color),
  );
}

/// Indicador numérico: valor grande y etiqueta tenue.
class TalexStat extends StatelessWidget {
  const TalexStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = TalexTone.blue,
    this.width = 200,
  });

  final String label;
  final String value;
  final IconData? icon;
  final TalexTone tone;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: TalexPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            TalexIconBadge(icon!, tone: tone, size: 34),
            const SizedBox(height: 16),
          ],
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          ),
        ],
      ),
    ),
  );
}

/// Fondo de página con el brillo radial del hero de la landing (azul arriba a
/// la derecha, lima a la izquierda). En claro el brillo es más tenue.
class TalexGlow extends StatelessWidget {
  const TalexGlow({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? AppColors.bg),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -1.15),
                    radius: 0.95,
                    colors: [
                      AppColors.company.withValues(alpha: dark ? 0.22 : 0.12),
                      AppColors.company.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.1, 0.1),
                    radius: 0.8,
                    colors: [
                      AppColors.brandGreen.withValues(alpha: dark ? 0.07 : 0.14),
                      AppColors.brandGreen.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Línea divisoria de 1 px con el borde de la marca.
class TalexDivider extends StatelessWidget {
  const TalexDivider({super.key, this.height = 1});
  final double height;

  @override
  Widget build(BuildContext context) =>
      Divider(height: height, thickness: 1, color: AppColors.border);
}
