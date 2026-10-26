import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/widgets/app_select_field.dart';
import 'package:talex_platform/core/widgets/location_picker.dart';
import 'package:talex_platform/core/widgets/logo_field.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/l10n/l10n.dart';

Future<void> showAdminCreateCompany(BuildContext context) {
  final name = TextEditingController();
  final plan = TextEditingController();
  var status = CompanyStatus.onboarding;
  final labels = AdminLabels(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminFormDialog(
      title: context.l10n.newCompany,
      onSubmit: () {
        if (name.text.trim().isEmpty) return;
        context.read<AdminBloc>().add(
          AdminCompanyCreated(
            name: name.text.trim(),
            status: status,
            plan: plan.text.trim().isEmpty ? null : plan.text.trim(),
          ),
        );
        Navigator.pop(dialogContext);
      },
      children: [
        TextFormField(
          controller: name,
          decoration: InputDecoration(
            labelText: context.l10n.companyName,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<CompanyStatus>(
          initialValue: status,
          decoration: InputDecoration(
            labelText: context.l10n.statusLabel,
          ),
          items: CompanyStatus.values
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(labels.companyStatus(item)),
                ),
              )
              .toList(),
          onChanged: (value) => status = value ?? status,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: plan,
          decoration: InputDecoration(
            labelText: context.l10n.plan,
          ),
        ),
      ],
    ),
  );
}

Future<void> showAdminCreateProcess(BuildContext context, List<Company> companies) {
  if (companies.isEmpty) return Future.value();
  final name = TextEditingController();
  var companyId = companies.first.id;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminFormDialog(
      title: context.l10n.newProcess,
      onSubmit: () {
        if (name.text.trim().isEmpty) return;
        context.read<AdminBloc>().add(
          AdminProcessCreated(companyId: companyId, name: name.text.trim()),
        );
        Navigator.pop(dialogContext);
      },
      children: [
        DropdownButtonFormField<String>(
          initialValue: companyId,
          decoration: InputDecoration(
            labelText: context.l10n.adminCompanies,
          ),
          items: companies
              .map(
                (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) => companyId = value ?? companyId,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: name,
          decoration: InputDecoration(
            labelText: context.l10n.adminProcesses,
          ),
        ),
      ],
    ),
  );
}

Future<void> showAdminCreatePerson(
  BuildContext context, {
  required List<Company> companies,
  required List<TalentProcess> processes,
}) {
  if (companies.isEmpty || processes.isEmpty) return Future.value();
  final name = TextEditingController();
  final score = TextEditingController();
  var companyId = companies.first.id;
  var processId = processes.first.id;
  var status = EvaluationStatus.invited;
  final labels = AdminLabels(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminFormDialog(
      title: context.l10n.newPerson,
      onSubmit: () {
        if (name.text.trim().isEmpty) return;
        context.read<AdminBloc>().add(
          AdminPersonCreated(
            companyId: companyId,
            processId: processId,
            displayName: name.text.trim(),
            status: status,
            affinityScore: double.tryParse(score.text.trim()),
          ),
        );
        Navigator.pop(dialogContext);
      },
      children: [
        DropdownButtonFormField<String>(
          initialValue: companyId,
          decoration: InputDecoration(
            labelText: context.l10n.adminCompanies,
          ),
          items: companies
              .map(
                (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) => companyId = value ?? companyId,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: processId,
          decoration: InputDecoration(
            labelText: context.l10n.adminProcesses,
          ),
          items: processes
              .map(
                (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) => processId = value ?? processId,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: name,
          decoration: InputDecoration(
            labelText: context.l10n.personName,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<EvaluationStatus>(
          initialValue: status,
          decoration: InputDecoration(
            labelText: context.l10n.statusLabel,
          ),
          items: EvaluationStatus.values
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(labels.evaluation(item))),
              )
              .toList(),
          onChanged: (value) => status = value ?? status,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: score,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.affinityScore,
          ),
        ),
      ],
    ),
  );
}

Future<void> showAdminCreateDeal(BuildContext context, List<Company> companies) {
  if (companies.isEmpty) return Future.value();
  var companyId = companies.first.id;
  var stage = DealStage.prospect;
  final value = TextEditingController();
  final owner = TextEditingController();
  final next = TextEditingController();
  final labels = AdminLabels(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminFormDialog(
      title: context.l10n.newDeal,
      onSubmit: () {
        context.read<AdminBloc>().add(
          AdminDealCreated(
            companyId: companyId,
            stage: stage,
            estimatedValue: double.tryParse(value.text.trim()),
            ownerName: owner.text.trim().isEmpty ? null : owner.text.trim(),
            nextAction: next.text.trim().isEmpty ? null : next.text.trim(),
          ),
        );
        Navigator.pop(dialogContext);
      },
      children: [
        DropdownButtonFormField<String>(
          initialValue: companyId,
          decoration: InputDecoration(
            labelText: context.l10n.adminCompanies,
          ),
          items: companies
              .map(
                (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) => companyId = value ?? companyId,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<DealStage>(
          initialValue: stage,
          decoration: InputDecoration(
            labelText: context.l10n.statusLabel,
          ),
          items: DealStage.values
              .map((item) => DropdownMenuItem(value: item, child: Text(labels.deal(item))))
              .toList(),
          onChanged: (value) => stage = value ?? stage,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.estimatedValue,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: owner,
          decoration: InputDecoration(
            labelText: context.l10n.owner,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: next,
          decoration: InputDecoration(
            labelText: context.l10n.nextAction,
          ),
        ),
      ],
    ),
  );
}

Future<void> showAdminEditCompany(BuildContext context, Company company) {
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _EditCompanyDialog(company: company),
    ),
  );
}

class _EditCompanyDialog extends StatefulWidget {
  const _EditCompanyDialog({required this.company});
  final Company company;
  @override
  State<_EditCompanyDialog> createState() => _EditCompanyDialogState();
}

class _EditCompanyDialogState extends State<_EditCompanyDialog> {
  late final TextEditingController _name;
  late final TextEditingController _nit;
  late final TextEditingController _website;
  late final TextEditingController _description;
  late LocationValue _location;
  late LogoSelection _logo;
  late CompanyStatus _status;
  String? _sector;
  String? _size;

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _name = TextEditingController(text: company.name);
    _nit = TextEditingController(text: company.nit ?? '');
    _website = TextEditingController(text: company.website ?? '');
    _description = TextEditingController(text: company.description ?? '');
    _location = LocationValue(
      country: company.country ?? 'Colombia',
      region: company.region,
      city: company.city,
    );
    _logo = LogoSelection(url: company.logoUrl);
    _status = company.status;
    _sector = company.sector;
    _size = company.size;
  }

  @override
  void dispose() {
    _name.dispose();
    _nit.dispose();
    _website.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    context.read<AdminBloc>().add(
      AdminCompanyUpdated(
        company: Company(
          id: widget.company.id,
          name: _name.text.trim(),
          status: _status,
          createdAt: widget.company.createdAt,
          logoUrl: _logo.url,
          website: _website.text.trim(),
          description: _description.text.trim(),
          nit: _nit.text.trim(),
          sector: _sector,
          size: _size,
          city: _location.city,
          region: _location.region,
          country: _location.country,
          lastActivityAt: widget.company.lastActivityAt,
          activeProcesses: widget.company.activeProcesses,
          invitedPeople: widget.company.invitedPeople,
          startedEvaluations: widget.company.startedEvaluations,
          completedEvaluations: widget.company.completedEvaluations,
          affinitiesDetected: widget.company.affinitiesDetected,
          plan: widget.company.plan,
          contractValue: widget.company.contractValue,
          mrr: widget.company.mrr,
          renewalAt: widget.company.renewalAt,
          commercialStage: widget.company.commercialStage,
          archived: widget.company.archived,
        ),
        logoBytes: _logo.bytes,
        logoContentType: _logo.contentType,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = AdminLabels(context);
    return _AdminFormDialog(
      title: l10n.editCompany,
      onSubmit: _save,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: l10n.companyName,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nit,
          decoration: InputDecoration(
            labelText: l10n.nit,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<CompanyStatus>(
          key: ValueKey(_status),
          initialValue: _status,
          decoration: InputDecoration(
            labelText: l10n.statusLabel,
          ),
          items: [
            for (final status in CompanyStatus.values)
              DropdownMenuItem(value: status, child: Text(labels.companyStatus(status))),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
        const SizedBox(height: 14),
        AppSelectField(
          label: l10n.sector,
          value: resolveCompanySectorId(_sector, l10n),
          options: companySectors(l10n),
          onChanged: (value) => setState(() => _sector = value),
        ),
        AppSelectField(
          label: l10n.companySize,
          value: resolveCompanySizeId(_size, l10n),
          options: companySizes(l10n),
          onChanged: (value) => setState(() => _size = value),
        ),
        LocationPicker(
          initial: _location,
          onChanged: (value) => _location = value,
        ),
        TextField(
          controller: _website,
          decoration: InputDecoration(
            labelText: l10n.website,
          ),
        ),
        const SizedBox(height: 14),
        LogoField(
          initialUrl: widget.company.logoUrl,
          onChanged: (value) => _logo = value,
        ),
        TextField(
          controller: _description,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.description,
          ),
        ),
      ],
    );
  }
}

Future<void> showAdminCreateSale(BuildContext context, List<Company> companies) {
  if (companies.isEmpty) return Future.value();
  var companyId = companies.first.id;
  final amount = TextEditingController();
  final product = TextEditingController();
  var recurring = false;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => _AdminFormDialog(
        title: context.l10n.newSale,
        onSubmit: () {
          final parsed = double.tryParse(amount.text.trim());
          if (parsed == null) return;
          context.read<AdminBloc>().add(
            AdminSaleCreated(
              companyId: companyId,
              amount: parsed,
              product: product.text.trim().isEmpty ? null : product.text.trim(),
              recurring: recurring,
            ),
          );
          Navigator.pop(dialogContext);
        },
        children: [
          DropdownButtonFormField<String>(
            initialValue: companyId,
            decoration: InputDecoration(
              labelText: context.l10n.adminCompanies,
            ),
            items: companies
                .map(
                  (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => companyId = value ?? companyId,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.amount,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: product,
            decoration: InputDecoration(
              labelText: context.l10n.product,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.recurring),
            value: recurring,
            onChanged: (value) => setState(() => recurring = value),
          ),
        ],
      ),
    ),
  );
}

Future<void> showCompanyLifecycleDialog(
  BuildContext context, {
  required Company company,
  required CompanyLifecycleAction action,
}) async {
  final l10n = context.l10n;
  final title = switch (action) {
    CompanyLifecycleAction.disable => l10n.disableCompanyTitle,
    CompanyLifecycleAction.enable => l10n.enableCompanyTitle,
    CompanyLifecycleAction.archive => l10n.archiveCompanyTitle,
    CompanyLifecycleAction.restore => l10n.restoreCompanyTitle,
  };
  final body = switch (action) {
    CompanyLifecycleAction.disable => l10n.disableCompanyBody,
    CompanyLifecycleAction.enable => l10n.enableCompanyBody,
    CompanyLifecycleAction.archive => l10n.archiveCompanyBody,
    CompanyLifecycleAction.restore => l10n.restoreCompanyBody,
  };
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.confirmAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  context.read<AdminBloc>().add(
    AdminCompanyLifecycleRequested(id: company.id, action: action),
  );
}

class _AdminFormDialog extends StatelessWidget {
  const _AdminFormDialog({
    required this.title,
    required this.children,
    required this.onSubmit,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(20),
    shape: AppRadii.shape,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            ...children,
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onSubmit,
              child: Text(context.l10n.saveChanges),
            ),
          ],
        ),
      ),
    ),
  );
}
