import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/l10n/l10n.dart';

class AffinityBadge extends StatelessWidget {
  const AffinityBadge(this.level, {super.key});
  final AffinityLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Ícono + texto + color: el nivel nunca depende solo del color.
    final (label, tone, icon) = switch (level) {
      AffinityLevel.high => (l10n.priorityHigh, TalexTone.green, Icons.check),
      AffinityLevel.medium => (l10n.priorityMedium, TalexTone.blue, Icons.remove),
      AffinityLevel.low => (
        l10n.priorityLow,
        TalexTone.warning,
        Icons.change_history,
      ),
      AffinityLevel.unknown => (
        l10n.affinityUnknown,
        TalexTone.neutral,
        Icons.more_horiz,
      ),
    };
    return TalexPill(label, tone: tone, icon: icon);
  }
}
