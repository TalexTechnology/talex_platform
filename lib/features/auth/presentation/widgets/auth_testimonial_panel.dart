import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Panel de marca de las pantallas de acceso: el mensaje del hero de la
// landing y una comparación de ejemplo empresa (azul) vs. candidato (verde).
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, this.showLogo = true});

  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          const TalexLogo(width: 150, height: 44),
          const SizedBox(height: 56),
        ],
        TalexEyebrow(l10n.authBrandEyebrow),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${l10n.authBrandTitleLead} '),
              TextSpan(
                text: l10n.authBrandTitleAccent,
                style: TextStyle(color: AppColors.green),
              ),
            ],
          ),
          style: TextStyle(
            color: AppColors.text,
            fontSize: 56,
            height: 0.98,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            l10n.authBrandBody,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const _FitPreview(),
        ),
      ],
    );
  }
}

class _FitPreview extends StatelessWidget {
  const _FitPreview();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = [
      (l10n.authBrandDimCollaboration, 0.82, 0.78),
      (l10n.authBrandDimAutonomy, 0.64, 0.71),
      (l10n.authBrandDimStructure, 0.70, 0.38),
      (l10n.authBrandDimInnovation, 0.55, 0.60),
    ];
    return TalexPanel(
      color: AppColors.surface,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Legend(color: AppColors.company, label: l10n.authBrandCompany),
              const SizedBox(width: 16),
              _Legend(
                color: AppColors.candidate,
                label: l10n.authBrandCandidate,
              ),
              const Spacer(),
              TalexPill(l10n.authBrandExample, tone: TalexTone.neutral),
            ],
          ),
          const SizedBox(height: 20),
          for (final (label, company, candidate) in rows) ...[
            _FitRow(label: label, company: company, candidate: candidate),
            if (label != rows.last.$1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      ),
    ],
  );
}

class _FitRow extends StatelessWidget {
  const _FitRow({
    required this.label,
    required this.company,
    required this.candidate,
  });

  final String label;
  final double company;
  final double candidate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final aligned = (company - candidate).abs() < 0.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              aligned ? Icons.check : Icons.change_history,
              size: 13,
              color: aligned ? AppColors.good : AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              aligned ? l10n.authBrandAligned : l10n.authBrandFriction,
              style: TextStyle(
                color: aligned ? AppColors.good : AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Bar(value: company, color: AppColors.company),
        const SizedBox(height: 4),
        _Bar(value: candidate, color: AppColors.candidate),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900),
    curve: const Cubic(0.2, 0.7, 0.2, 1),
    builder: (context, value, _) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 5,
        color: color,
        backgroundColor: AppColors.surface2,
      ),
    ),
  );
}
