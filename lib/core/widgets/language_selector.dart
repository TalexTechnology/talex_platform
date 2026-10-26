import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/locale/locale_cubit.dart';
import 'package:talex_platform/l10n/l10n.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangChip(
          label: compact ? 'ES' : context.l10n.spanish,
          selected: current == 'es',
          onTap: () => context.read<LocaleCubit>().setLanguageCode('es'),
        ),
        Text(' | ', style: TextStyle(color: AppColors.textDimmer)),
        _LangChip(
          label: compact ? 'EN' : context.l10n.english,
          selected: current == 'en',
          onTap: () => context.read<LocaleCubit>().setLanguageCode('en'),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.text : AppColors.textDimmer,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}
