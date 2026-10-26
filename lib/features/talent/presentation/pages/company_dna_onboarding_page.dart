import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/theme_toggle_button.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/features/talent/presentation/widgets/company_dna_fields.dart';
import 'package:talex_platform/l10n/l10n.dart';

class CompanyDnaOnboardingPage extends StatefulWidget {
  const CompanyDnaOnboardingPage({super.key, required this.companyId});
  final String companyId;

  @override
  State<CompanyDnaOnboardingPage> createState() =>
      _CompanyDnaOnboardingPageState();
}

class _CompanyDnaOnboardingPageState extends State<CompanyDnaOnboardingPage> {
  var _values = <String>[];
  var _culture = <String>[];
  var _standout = <String>[];
  var _seeded = false;

  void _seed(CompanyProfile? profile) {
    if (_seeded || profile == null) return;
    _values = parseDnaList(profile.values);
    _culture = parseDnaList(profile.culture);
    _standout = parseDnaList(profile.standoutPeople);
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TalentBloc, TalentState>(
      listenWhen: (previous, current) =>
          current.dnaConfirmed ||
          previous.failure != current.failure ||
          previous.snapshot.profile != current.snapshot.profile,
      listener: (context, state) {
        _seed(state.snapshot.profile);
        if (state.failure != null) {
          getIt<NotificationService>().error(
            talentErrorMessage(context.l10n, state.failure!.message),
          );
        }
        if (state.dnaConfirmed) {
          context.read<AuthBloc>().add(const AuthSessionRequested());
        }
      },
      child: BlocBuilder<TalentBloc, TalentState>(
        builder: (context, state) {
          final profile = state.snapshot.profile;
          _seed(profile);
          final l10n = context.l10n;
          final reviewing = profile?.hasCompanyDna ?? false;
          return Scaffold(
            body: TalexGlow(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            TalexLogo(width: 120, height: 36),
                            Spacer(),
                            LanguageSelector(compact: true),
                            SizedBox(width: 12),
                            ThemeToggleButton(size: 36),
                          ],
                        ),
                        const SizedBox(height: 36),
                        TalexEyebrow(l10n.companyEyebrow),
                        const SizedBox(height: 14),
                        Text(
                          reviewing
                              ? l10n.reviewCompanyDnaTitle
                              : l10n.completeCompanyDnaTitle,
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.08,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          reviewing
                              ? l10n.reviewCompanyDnaSubtitle
                              : l10n.completeCompanyDnaSubtitle,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        CompanyDnaFields(
                          values: _values,
                          culture: _culture,
                          standout: _standout,
                          catalog: state.snapshot.dnaCatalog,
                          onValuesChanged: (value) =>
                              setState(() => _values = value),
                          onCultureChanged: (value) =>
                              setState(() => _culture = value),
                          onStandoutChanged: (value) =>
                              setState(() => _standout = value),
                          onDeleteCustom: (type, label) =>
                              context.read<TalentBloc>().add(
                                TalentDnaOptionDeleted(
                                  type: type,
                                  label: label,
                                ),
                              ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () {
                            if (_values.isEmpty ||
                                _culture.isEmpty ||
                                _standout.isEmpty) {
                              getIt<NotificationService>().error(
                                l10n.dnaRequired,
                              );
                              return;
                            }
                            final current = profile;
                            context.read<TalentBloc>().add(
                              TalentCompanyDnaConfirmed(
                                CompanyProfile(
                                  id: widget.companyId,
                                  name: current?.name ?? '',
                                  nit: current?.nit,
                                  logoUrl: current?.logoUrl,
                                  sector: current?.sector,
                                  size: current?.size,
                                  city: current?.city,
                                  country: current?.country,
                                  region: current?.region,
                                  website: current?.website,
                                  description: current?.description,
                                  values: joinDnaList(_values),
                                  culture: joinDnaList(_culture),
                                  standoutPeople: joinDnaList(_standout),
                                  soughtCharacteristics:
                                      current?.soughtCharacteristics,
                                  customValues:
                                      current?.customValues ?? const [],
                                  customCulture:
                                      current?.customCulture ?? const [],
                                  customStandout:
                                      current?.customStandout ?? const [],
                                  customAreas: current?.customAreas ?? const [],
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.confirmCompanyDna),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
