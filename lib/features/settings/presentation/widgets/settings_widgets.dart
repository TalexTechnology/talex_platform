import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/core/constants/app_colors.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.icon,
  });
  final String title, description;
  final Widget child;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => TalexPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                TalexIconBadge(icon!),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TalexSectionTitle(title),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const TalexDivider(),
        Padding(padding: const EdgeInsets.all(24), child: child),
      ],
    ),
  );
}

class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
        ),
      ),
    ],
  );
}

class SettingsDropdown extends StatelessWidget {
  const SettingsDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
        ),
      ),
    ],
  );
}

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  final String title, description;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
