import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/location/location_query.dart';
import 'package:talex_platform/l10n/l10n.dart';

class SearchableSelect extends StatelessWidget {
  const SearchableSelect({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.value,
    this.enabled = true,
    this.loading = false,
    this.searchHint,
    this.emptyHint,
    this.allowCustom = false,
    this.addCustomLabel,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final bool loading;
  final String? searchHint;
  final String? emptyHint;
  final bool allowCustom;
  final String Function(String query)? addCustomLabel;

  Future<void> _open(BuildContext context) async {
    if (!enabled || loading) return;
    final selected = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _SearchableSelectDialog(
        label: label,
        options: options,
        value: value,
        searchHint: searchHint ?? context.l10n.searchLocation,
        allowCustom: allowCustom,
        addCustomLabel: addCustomLabel,
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = enabled && !loading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: canOpen ? () => _open(context) : null,
        borderRadius: AppRadii.border,
        child: InputDecorator(
          isEmpty: value == null || value!.isEmpty,
          decoration: InputDecoration(
            labelText: label,
            helperText: (value == null || value!.isEmpty) &&
                    !enabled &&
                    !loading &&
                    emptyHint != null
                ? emptyHint
                : null,
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.expand_more,
                    color: canOpen ? AppColors.blue : AppColors.textDimmer,
                  ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 24),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                value ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableSelectDialog extends StatefulWidget {
  const _SearchableSelectDialog({
    required this.label,
    required this.options,
    required this.searchHint,
    this.value,
    this.allowCustom = false,
    this.addCustomLabel,
  });

  final String label;
  final List<String> options;
  final String searchHint;
  final String? value;
  final bool allowCustom;
  final String Function(String query)? addCustomLabel;

  @override
  State<_SearchableSelectDialog> createState() => _SearchableSelectDialogState();
}

class _SearchableSelectDialogState extends State<_SearchableSelectDialog> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((item) => locationQueryMatches(item, _query.text))
        .toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (filtered.length == 1) {
                    Navigator.pop(context, filtered.first);
                  }
                },
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (filtered.isEmpty &&
                        !(widget.allowCustom &&
                            _query.text.trim().isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.locationNoResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDimmer),
                        ),
                      ),
                    for (final option in filtered)
                      ListTile(
                        selected: option == widget.value,
                        selectedTileColor: AppColors.greenDim,
                        title: Text(option),
                        onTap: () => Navigator.pop(context, option),
                      ),
                    if (widget.allowCustom &&
                        _query.text.trim().isNotEmpty &&
                        !widget.options.any(
                          (item) =>
                              item.toLowerCase() ==
                              _query.text.trim().toLowerCase(),
                        ))
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: Text(
                          widget.addCustomLabel?.call(_query.text.trim()) ??
                              context.l10n.addCustomOption(_query.text.trim()),
                        ),
                        onTap: () =>
                            Navigator.pop(context, _query.text.trim()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchableMultiSelect extends StatelessWidget {
  const SearchableMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChanged,
    this.searchHint,
    this.allowCustom = false,
    this.removableValues = const {},
    this.onRemoveOption,
  });

  final String label;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? searchHint;
  final bool allowCustom;
  final Set<String> removableValues;
  final ValueChanged<String>? onRemoveOption;

  Future<void> _open(BuildContext context) async {
    final selected = await showDialog<List<String>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _SearchableMultiSelectDialog(
        label: label,
        options: uniqueSelectOptions([...options, ...values]),
        values: values,
        searchHint: searchHint ?? context.l10n.searchLocation,
        allowCustom: allowCustom,
        removableValues: removableValues,
        onRemoveOption: onRemoveOption,
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: AppRadii.border,
        child: InputDecorator(
          isEmpty: values.isEmpty,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Icon(
              Icons.expand_more,
              color: AppColors.blue,
            ),
          ),
          child: values.isEmpty
              ? const SizedBox(height: 24)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in values)
                      InputChip(
                        label: Text(item),
                        onDeleted: () {
                          onChanged(
                            values.where((value) => value != item).toList(),
                          );
                        },
                        deleteIcon: Icon(
                          removableValues.contains(item)
                              ? Icons.delete_outline
                              : Icons.close,
                          size: 18,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

List<String> uniqueSelectOptions(Iterable<String> items) {
  final seen = <String>{};
  final result = <String>[];
  for (final item in items) {
    final value = item.trim();
    if (value.isEmpty) continue;
    if (seen.add(value.toLowerCase())) result.add(value);
  }
  return result;
}

class _SearchableMultiSelectDialog extends StatefulWidget {
  const _SearchableMultiSelectDialog({
    required this.label,
    required this.options,
    required this.values,
    required this.searchHint,
    required this.allowCustom,
    required this.removableValues,
    this.onRemoveOption,
  });

  final String label;
  final List<String> options;
  final List<String> values;
  final String searchHint;
  final bool allowCustom;
  final Set<String> removableValues;
  final ValueChanged<String>? onRemoveOption;

  @override
  State<_SearchableMultiSelectDialog> createState() =>
      _SearchableMultiSelectDialogState();
}

class _SearchableMultiSelectDialogState
    extends State<_SearchableMultiSelectDialog> {
  final _query = TextEditingController();
  late List<String> _selected;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.values];
    _options = [...widget.options];
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _isSelected(String option) =>
      _selected.any((item) => item.toLowerCase() == option.toLowerCase());

  void _toggle(String option) {
    setState(() {
      if (_isSelected(option)) {
        _selected.removeWhere(
          (item) => item.toLowerCase() == option.toLowerCase(),
        );
      } else {
        _selected.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _options
        .where((item) => locationQueryMatches(item, _query.text))
        .toList();
    final query = _query.text.trim();
    final canAddCustom =
        widget.allowCustom &&
        query.isNotEmpty &&
        !_options.any((item) => item.toLowerCase() == query.toLowerCase());
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: Text(context.l10n.continueAction),
                  ),
                ],
              ),
              TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (filtered.isEmpty && !canAddCustom)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.locationNoResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDimmer),
                        ),
                      ),
                    for (final option in filtered)
                      ListTile(
                        selected: _isSelected(option),
                        selectedTileColor: AppColors.greenDim,
                        title: Text(option),
                        trailing: widget.removableValues.contains(option)
                            ? IconButton(
                                tooltip: context.l10n.removeCustomOption,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _options.remove(option);
                                    _selected.removeWhere(
                                      (item) =>
                                          item.toLowerCase() ==
                                          option.toLowerCase(),
                                    );
                                  });
                                  widget.onRemoveOption?.call(option);
                                },
                              )
                            : Checkbox(
                                value: _isSelected(option),
                                onChanged: (_) => _toggle(option),
                              ),
                        onTap: () => _toggle(option),
                      ),
                    if (canAddCustom)
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: Text(context.l10n.addCustomOption(query)),
                        onTap: () {
                          setState(() {
                            _options.add(query);
                            _selected.add(query);
                            _query.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
