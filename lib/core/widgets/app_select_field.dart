import 'package:flutter/material.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';

class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
  });

  final String label;
  final String? value;
  final List<CatalogOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    String? selected;
    for (final option in options) {
      if (option.id == value || option.label == value) {
        selected = option.id;
        break;
      }
    }
    final items = [
      ...options,
      if (value != null && value!.isNotEmpty && selected == null)
        CatalogOption(value!, value!),
    ];
    selected ??= items.any((item) => item.id == value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label|$locale|$selected'),
        initialValue: selected != null && items.any((item) => item.id == selected)
            ? selected
            : null,
        isExpanded: true,
        alignment: Alignment.center,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item.id,
              alignment: Alignment.center,
              child: Text(item.label, textAlign: TextAlign.center),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
