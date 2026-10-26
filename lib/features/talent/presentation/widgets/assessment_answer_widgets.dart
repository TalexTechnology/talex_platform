import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';

// Respuestas de la encuesta de afinidad. Ambas usan valores 1..5:
// - [PairAnswer]: 1 = claramente la A … 5 = claramente la B.
// - [FrequencyAnswer]: 1 = nunca … 5 = siempre.
// Cada opción lleva la clave `answer-<valor>` para poder ubicarla en tests.

const _sideA = LegacyColors.brandBlue;
const _sideB = Color(0xFF5E9A1F);
const _neutral = Color(0xFF9AA8B9);
const _line = Color(0xFFDCE4EE);

Color _sideColor(int value) => value < 3
    ? _sideA
    : value > 3
    ? _sideB
    : _neutral;

class PairAnswer extends StatelessWidget {
  const PairAnswer({
    super.key,
    required this.statementA,
    required this.statementB,
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.hint,
  });

  final String statementA, statementB, hint;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelected;

  // 0 = sin inclinación, 1 = "más", 2 = "claramente".
  int _strength(bool sideA) {
    final value = selected;
    if (value == null) return 0;
    if (sideA) return value == 1 ? 2 : (value == 2 ? 1 : 0);
    return value == 5 ? 2 : (value == 4 ? 1 : 0);
  }

  // Tocar una frase la elige; tocarla de nuevo la vuelve "claramente".
  void _tapSide(bool sideA) {
    final lean = sideA ? 2 : 4;
    final strong = sideA ? 1 : 5;
    onSelected(selected == lean ? strong : lean);
  }

  @override
  Widget build(BuildContext context) {
    final neutral = selected == 3;
    final cardA = _SideCard(
      letter: 'A',
      text: statementA,
      color: _sideA,
      strength: _strength(true),
      neutral: neutral,
      onTap: () => _tapSide(true),
    );
    final cardB = _SideCard(
      letter: 'B',
      text: statementB,
      color: _sideB,
      strength: _strength(false),
      neutral: neutral,
      onTap: () => _tapSide(false),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 560
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [cardA, const SizedBox(height: 10), cardB],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cardA),
                      const SizedBox(width: 12),
                      Expanded(child: cardB),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 22),
        _PairScale(selected: selected, labels: labels, onSelected: onSelected),
        const SizedBox(height: 14),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: selected == null
                ? Text(
                    hint,
                    key: const ValueKey('hint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: LegacyColors.muted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                : Container(
                    key: ValueKey(selected),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _sideColor(selected!).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[selected! - 1],
                      style: TextStyle(
                        color: selected == 3
                            ? LegacyColors.subtitle
                            : _sideColor(selected!),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.letter, required this.color, this.filled = true});

  final String letter;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: filled ? color : color.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    child: Text(
      letter,
      style: TextStyle(
        color: filled ? Colors.white : color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.letter,
    required this.text,
    required this.color,
    required this.strength,
    required this.neutral,
    required this.onTap,
  });

  final String letter, text;
  final Color color;
  final int strength;
  final bool neutral;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = strength > 0;
    final border = active
        ? color.withValues(alpha: strength == 2 ? 1 : 0.55)
        : neutral
        ? _neutral
        : _line;
    final background = active
        ? color.withValues(alpha: strength == 2 ? 0.1 : 0.05)
        : Colors.white;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: active ? 2 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(letter: letter, color: color, filled: active),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: LegacyColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cinco puntos unidos por una línea: los extremos son más grandes
/// ("claramente") y el centro es neutro.
class _PairScale extends StatelessWidget {
  const _PairScale({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final int? selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  static const _sizes = [30.0, 22.0, 16.0, 22.0, 30.0];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: Row(
      children: [
        _Badge(letter: 'A', color: _sideA, filled: (selected ?? 3) < 3),
        const SizedBox(width: 10),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 22,
                right: 22,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        _sideA.withValues(alpha: 0.35),
                        _line,
                        _sideB.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var value = 1; value <= 5; value++)
                    _Dot(
                      key: ValueKey('answer-$value'),
                      size: _sizes[value - 1],
                      color: _sideColor(value),
                      selected: selected == value,
                      label: labels[value - 1],
                      onTap: () => onSelected(value),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _Badge(letter: 'B', color: _sideB, filled: (selected ?? 3) > 3),
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({
    super.key,
    required this.size,
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final double size;
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? size + 4 : size,
              height: selected ? size + 4 : size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: selected && size >= 22
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: size * 0.6,
                    )
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
}

class FrequencyAnswer extends StatelessWidget {
  const FrequencyAnswer({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 520;
      final tiles = [
        for (var value = 1; value <= labels.length; value++)
          _FrequencyTile(
            key: ValueKey('answer-$value'),
            level: value - 1,
            levels: labels.length - 1,
            label: labels[value - 1],
            selected: selected == value,
            horizontal: narrow,
            onTap: () => onSelected(value),
          ),
      ];
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tile in tiles)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: tile),
          ],
        );
      }
      return Row(
        children: [
          for (final (index, tile) in tiles.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: tile),
          ],
        ],
      );
    },
  );
}

class _FrequencyTile extends StatelessWidget {
  const _FrequencyTile({
    super.key,
    required this.level,
    required this.levels,
    required this.label,
    required this.selected,
    required this.horizontal,
    required this.onTap,
  });

  final int level, levels;
  final String label;
  final bool selected, horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : LegacyColors.ink;
    final bars = _Bars(
      level: level,
      levels: levels,
      color: selected ? Colors.white : LegacyColors.brandBlue,
    );
    final text = Text(
      label,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        color: foreground,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: horizontal ? 52 : 92,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? LegacyColors.brandBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? LegacyColors.brandBlue : _line,
                width: selected ? 2 : 1,
              ),
            ),
            child: horizontal
                ? Row(
                    children: [
                      bars,
                      const SizedBox(width: 14),
                      Expanded(child: text),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [bars, const SizedBox(height: 10), text],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Barras crecientes: tantas llenas como [level] (0 = nunca, [levels] = siempre).
class _Bars extends StatelessWidget {
  const _Bars({required this.level, required this.levels, required this.color});

  final int level, levels;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 24,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < levels; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 6,
            height: 8 + 16 * i / (levels - 1).clamp(1, levels),
            decoration: BoxDecoration(
              color: i < level ? color : color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    ),
  );
}
