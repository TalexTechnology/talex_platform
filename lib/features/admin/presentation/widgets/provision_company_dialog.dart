import 'package:dartz/dartz.dart' show Left;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_assets.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/app_select_field.dart';
import 'package:talex_platform/core/widgets/location_picker.dart';
import 'package:talex_platform/core/widgets/logo_field.dart';
import 'package:talex_platform/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:talex_platform/features/talent/data/services/invite_email_service.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/repositories/talent_repository.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/l10n.dart';

Future<void> showProvisionCompanyDialog(BuildContext context) {
  final bloc = context.read<AdminBloc>();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _ProvisionCompanyDialog(),
    ),
  );
}

class _ProvisionCompanyDialog extends StatefulWidget {
  const _ProvisionCompanyDialog();
  @override
  State<_ProvisionCompanyDialog> createState() => _ProvisionCompanyDialogState();
}

class _ProvisionCompanyDialogState extends State<_ProvisionCompanyDialog> {
  var _step = 0;
  var _submitting = false;
  String? _sector;
  String? _size;
  var _location = const LocationValue(country: 'Colombia');
  LogoSelection _logo = const LogoSelection();
  final _name = TextEditingController();
  final _nit = TextEditingController();
  final _website = TextEditingController();
  final _description = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _nit.dispose();
    _website.dispose();
    _description.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _finish() async {
    if (_submitting) return;
    final l10n = context.l10n;
    final notifications = getIt<NotificationService>();
    if (_first.text.trim().isEmpty ||
        _last.text.trim().isEmpty ||
        !_email.text.contains('@')) {
      notifications.error(l10n.requiredField);
      return;
    }
    setState(() => _submitting = true);
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final result = await getIt<TalentRepository>()
          .provisionCompany(
            profile: CompanyProfile(
              id: '',
              name: _name.text.trim(),
              nit: _nit.text.trim(),
              sector: _sector,
              size: _size,
              country: _location.country,
              region: _location.region,
              city: _location.city,
              website: _website.text.trim(),
              logoUrl: _logo.url,
              description: _description.text.trim(),
            ),
            recruiterFirstName: _first.text.trim(),
            recruiterLastName: _last.text.trim(),
            recruiterEmail: _email.text.trim(),
            logoBytes: _logo.bytes,
            logoContentType: _logo.contentType,
          )
          .timeout(
            const Duration(seconds: 35),
            onTimeout: () => const Left(ServerFailure('errorUnexpected')),
          );
      if (!mounted) return;
      await result.fold(
        (failure) async {
          notifications.error(talentErrorMessage(l10n, failure.message));
        },
        (pin) async {
          if (!mounted) return;
          context.read<AdminBloc>().add(const AdminCompaniesRequested());
          Navigator.pop(context);
          notifications.success(l10n.pinGenerated(pin));
          final mail = await getIt<InviteEmailService>().sendRecruiterPin(
            to: _email.text.trim(),
            firstName: _first.text.trim(),
            companyName: _name.text.trim(),
            pin: pin,
            locale: locale,
            situation: 'account_created',
          );
          mail.fold(
            (failure) => notifications.error(
              talentErrorMessage(l10n, failure.message),
            ),
            (_) => notifications.success(l10n.emailSent),
          );
        },
      );
    } catch (_) {
      notifications.error(talentErrorMessage(l10n, 'errorUnexpected'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [l10n.provisionStepCompany, l10n.provisionStepInvite];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
            child: Material(
              color: Colors.white,
              elevation: 18,
              shadowColor: AppColors.ink.withValues(alpha: 0.18),
              borderRadius: AppRadii.border,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.ink, Color(0xFF0A1F40)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: l10n.close,
                              onPressed: _close,
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Image.asset(
                                    AppAssets.talexBadgeDark,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.newCompany,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (var i = 0; i < steps.length; i++)
                              _StepChip(
                                label: '${i + 1}. ${steps[i]}',
                                active: i == _step,
                                done: i < _step,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.fieldFill,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: switch (_step) {
                          0 => Column(
                            children: [
                              _field(l10n.companyName, _name),
                              _field(l10n.nit, _nit),
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
                              _field(l10n.website, _website),
                              LogoField(onChanged: (value) => _logo = value),
                              _field(l10n.description, _description, lines: 3),
                            ],
                          ),
                          _ => Column(
                            children: [
                              _field(l10n.firstName, _first),
                              _field(l10n.lastName, _last),
                              _field(l10n.emailAddress, _email),
                            ],
                          ),
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.fieldBorder)),
                    ),
                    child: Row(
                      children: [
                        if (_step > 0)
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _step -= 1),
                            child: Text(l10n.goBack),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _submitting
                              ? null
                              : _step < 1
                              ? () => setState(() => _step += 1)
                              : _finish,
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_step < 1 ? l10n.next : l10n.sendInvitation),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.active,
    required this.done,
  });
  final String label;
  final bool active, done;

  @override
  Widget build(BuildContext context) {
    final color = active || done
        ? AppColors.dashboardAccent
        : Colors.white.withValues(alpha: 0.28);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadii.border,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.ink : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
