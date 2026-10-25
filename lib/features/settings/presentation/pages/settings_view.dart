import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/l10n/l10n.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _organization = TextEditingController();
  bool _candidateUpdates = true;
  bool _weeklyDigest = true;
  bool _twoFactor = false;
  bool _bound = false;
  bool _binding = false;
  String? _sector;
  String? _size;
  String? _timezone;

  void _bind(BuildContext context) {
    if (_bound || _binding) return;
    final l10n = context.l10n;
    _timezone ??= l10n.timezoneBogota;
    final bloc = _companyBloc(context);
    if (bloc == null) {
      _bound = true;
      if (_organization.text.isEmpty) _organization.text = 'TaleX';
      return;
    }
    final profile = bloc.state.snapshot.profile;
    if (profile == null) return;
    final name = profile.name;
    final sector = resolveCompanySectorId(profile.sector, l10n);
    final size = resolveCompanySizeId(profile.size, l10n);
    _binding = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _bound = true;
        _binding = false;
        _organization.text = name;
        _sector = sector;
        _size = size;
      });
    });
  }

  void _save() {
    final l10n = context.l10n;
    final bloc = _companyBloc(context);
    final profile = bloc?.state.snapshot.profile;
    final id = bloc?.state.companyId ?? profile?.id;
    if (bloc != null && profile != null && id != null) {
      final name = _organization.text.trim();
      bloc.add(
        TalentProfileSaved(
          CompanyProfile(
            id: id,
            name: name.isEmpty ? profile.name : name,
            nit: profile.nit,
            logoUrl: profile.logoUrl,
            sector: _sector ?? profile.sector,
            size: _size ?? profile.size,
            city: profile.city,
            country: profile.country,
            region: profile.region,
            website: profile.website,
            description: profile.description,
            values: profile.values,
            culture: profile.culture,
            standoutPeople: profile.standoutPeople,
            soughtCharacteristics: profile.soughtCharacteristics,
            customValues: profile.customValues,
            customCulture: profile.customCulture,
            customStandout: profile.customStandout,
            customAreas: profile.customAreas,
          ),
        ),
      );
    }
    getIt<NotificationService>().success(l10n.changesSaved);
  }

  @override
  void dispose() {
    _organization.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _bind(context);
      final l10n = context.l10n;
      final compact = constraints.maxWidth < 760;
      final pagePadding = compact ? 18.0 : 40.0;
      final sectors = companySectors(l10n);
      final sizes = companySizes(l10n);
      final zones = [
        l10n.timezoneBogota,
        'America/Lima',
        'America/Mexico_City',
        'Europe/Madrid',
        'America/New_York',
      ];
      final organizationFields = [
        SettingsTextField(
          label: l10n.organizationName,
          controller: _organization,
        ),
        SettingsDropdown(
          label: l10n.industry,
          value: _optionLabel(sectors, _sector),
          items: [for (final option in sectors) option.label],
          onChanged: (label) => setState(
            () => _sector = _optionId(sectors, label),
          ),
        ),
        SettingsDropdown(
          label: l10n.companySize,
          value: _optionLabel(sizes, _size),
          items: [for (final option in sizes) option.label],
          onChanged: (label) => setState(
            () => _size = _optionId(sizes, label),
          ),
        ),
        SettingsDropdown(
          label: l10n.timezone,
          value: _timezone ?? l10n.timezoneBogota,
          items: zones,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _timezone = value);
          },
        ),
      ];
      return SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 18,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.settingsTitle,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: compact ? 34 : 42,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.settingsSubtitle,
                          style: const TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(context.l10n.saveChanges),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SettingsSection(
                  title: context.l10n.language,
                  description: context.l10n.languageDescription,
                  icon: Icons.language,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: LanguageSelector(),
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSection(
                  title: context.l10n.organizationProfile,
                  description: context.l10n.organizationDescription,
                  icon: Icons.business_outlined,
                  child: Column(
                    children: [
                      for (var index = 0; index < organizationFields.length; index++) ...[
                        if (index > 0) const SizedBox(height: 16),
                        organizationFields[index],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSection(
                  title: context.l10n.notificationsTitle,
                  description: context.l10n.notificationsDescription,
                  icon: Icons.notifications_none,
                  child: Column(
                    children: [
                      SettingsToggle(
                        title: context.l10n.candidateUpdates,
                        description: context.l10n.candidateUpdatesDescription,
                        value: _candidateUpdates,
                        onChanged: (value) =>
                            setState(() => _candidateUpdates = value),
                      ),
                      SettingsToggle(
                        title: context.l10n.weeklyDigest,
                        description: context.l10n.weeklyDigestDescription,
                        value: _weeklyDigest,
                        onChanged: (value) =>
                            setState(() => _weeklyDigest = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSection(
                  title: context.l10n.securityTitle,
                  description: context.l10n.securityDescription,
                  icon: Icons.shield_outlined,
                  child: Column(
                    children: [
                      SettingsToggle(
                        title: context.l10n.twoFactorAuth,
                        description: context.l10n.twoFactorDescription,
                        value: _twoFactor,
                        onChanged: (value) =>
                            setState(() => _twoFactor = value),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.sessionTimeout,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(context.l10n.minutes30),
                          const SizedBox(width: 20),
                          OutlinedButton(
                            onPressed: () {},
                            child: Text(context.l10n.manageMembers),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    },
  );

  TalentBloc? _companyBloc(BuildContext context) {
    try {
      return BlocProvider.of<TalentBloc>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  String _optionLabel(List<CatalogOption> options, String? id) {
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return options.first.label;
  }

  String? _optionId(List<CatalogOption> options, String? label) {
    for (final option in options) {
      if (option.label == label) return option.id;
    }
    return null;
  }
}
