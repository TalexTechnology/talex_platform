import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

class CatalogOption {
  const CatalogOption(this.id, this.label);
  final String id;
  final String label;
}

String _norm(String value) {
  var normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll(RegExp(r'\s+'), ' ');
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  for (var i = 0; i < from.length; i++) {
    normalized = normalized.replaceAll(from[i], to[i]);
  }
  return normalized;
}

String? resolveCatalogId(String? raw, List<CatalogOption> options) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  for (final option in options) {
    if (option.id == trimmed || option.label == trimmed) return option.id;
  }
  return null;
}

String catalogLabel(AppLocalizations l10n, String? raw, List<CatalogOption> options) {
  final id = resolveCatalogId(raw, options) ?? raw;
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return raw ?? '';
}

abstract final class CompanySizeId {
  static const size1to10 = 'size_1_10';
  static const size11to50 = 'size_11_50';
  static const size51to200 = 'size_51_200';
  static const size201to500 = 'size_201_500';
  static const size500plus = 'size_500_plus';
}

abstract final class CompanySectorId {
  static const technology = 'technology';
  static const finance = 'finance';
  static const health = 'health';
  static const education = 'education';
  static const manufacturing = 'manufacturing';
  static const retail = 'retail';
  static const services = 'services';
  static const construction = 'construction';
  static const energy = 'energy';
  static const agribusiness = 'agribusiness';
  static const government = 'government';
  static const other = 'other';
}

abstract final class VacancyContractId {
  static const indefinite = 'indefinite';
  static const fixed = 'fixed';
  static const services = 'services';
  static const internship = 'internship';
  static const temporary = 'temporary';
}

abstract final class VacancyAreaId {
  static const people = 'area_people';
  static const financeOps = 'area_finance_ops';
  static const operations = 'area_operations';
  static const commercial = 'area_commercial';
  static const customer = 'area_customer';
  static const admin = 'area_admin';
  static const engineering = 'area_engineering';
  static const product = 'area_product';
  static const data = 'area_data';
  static const support = 'area_support';
  static const risk = 'area_risk';
  static const accounting = 'area_accounting';
  static const clinical = 'area_clinical';
  static const care = 'area_care';
  static const academic = 'area_academic';
  static const training = 'area_training';
  static const production = 'area_production';
  static const quality = 'area_quality';
  static const maintenance = 'area_maintenance';
  static const store = 'area_store';
  static const logistics = 'area_logistics';
  static const projects = 'area_projects';
  static const field = 'area_field';
  static const publicService = 'area_public_service';
  static const other = 'area_other';
}

List<CatalogOption> companySectors(AppLocalizations l10n) => [
  CatalogOption(CompanySectorId.technology, l10n.technologyIndustry),
  CatalogOption(CompanySectorId.finance, l10n.sectorFinance),
  CatalogOption(CompanySectorId.health, l10n.sectorHealth),
  CatalogOption(CompanySectorId.education, l10n.sectorEducation),
  CatalogOption(CompanySectorId.manufacturing, l10n.sectorManufacturing),
  CatalogOption(CompanySectorId.retail, l10n.sectorRetail),
  CatalogOption(CompanySectorId.services, l10n.sectorServices),
  CatalogOption(CompanySectorId.construction, l10n.sectorConstruction),
  CatalogOption(CompanySectorId.energy, l10n.sectorEnergy),
  CatalogOption(CompanySectorId.agribusiness, l10n.sectorAgribusiness),
  CatalogOption(CompanySectorId.government, l10n.sectorGovernment),
  CatalogOption(CompanySectorId.other, l10n.sectorOther),
];

List<CatalogOption> companySizes(AppLocalizations l10n) => [
  CatalogOption(CompanySizeId.size1to10, l10n.size1to10),
  CatalogOption(CompanySizeId.size11to50, l10n.size11to50),
  CatalogOption(CompanySizeId.size51to200, l10n.employeesRange),
  CatalogOption(CompanySizeId.size201to500, l10n.size201to500),
  CatalogOption(CompanySizeId.size500plus, l10n.size500plus),
];

List<CatalogOption> vacancyContractTypes(AppLocalizations l10n) => [
  CatalogOption(VacancyContractId.indefinite, l10n.contractIndefinite),
  CatalogOption(VacancyContractId.fixed, l10n.contractFixed),
  CatalogOption(VacancyContractId.services, l10n.contractServices),
  CatalogOption(VacancyContractId.internship, l10n.contractInternship),
  CatalogOption(VacancyContractId.temporary, l10n.contractTemporary),
];

String? resolveCompanySizeId(String? raw, AppLocalizations l10n) {
  final fromOptions = resolveCatalogId(raw, companySizes(l10n));
  if (fromOptions != null) return fromOptions;
  final key = _norm(raw ?? '');
  if (key.contains('1-10')) return CompanySizeId.size1to10;
  if (key.contains('11-50')) return CompanySizeId.size11to50;
  if (key.contains('51-200') || key.contains('51–200')) {
    return CompanySizeId.size51to200;
  }
  if (key.contains('201-500')) return CompanySizeId.size201to500;
  if (key.contains('500')) return CompanySizeId.size500plus;
  return raw;
}

String? resolveCompanySectorId(String? raw, AppLocalizations l10n) {
  final fromOptions = resolveCatalogId(raw, companySectors(l10n));
  if (fromOptions != null) return fromOptions;
  return switch (_norm(raw ?? '')) {
    'tecnología' || 'tecnologia' || 'technology' => CompanySectorId.technology,
    'financiero' || 'finance' => CompanySectorId.finance,
    'salud' || 'healthcare' || 'health' => CompanySectorId.health,
    'educación' || 'educacion' || 'education' => CompanySectorId.education,
    'manufactura' || 'manufacturing' => CompanySectorId.manufacturing,
    'comercio' || 'retail' => CompanySectorId.retail,
    'servicios' || 'services' => CompanySectorId.services,
    'construcción' || 'construccion' || 'construction' =>
      CompanySectorId.construction,
    'energía' || 'energia' || 'energy' => CompanySectorId.energy,
    'agroindustria' || 'agribusiness' => CompanySectorId.agribusiness,
    'gobierno' || 'government' => CompanySectorId.government,
    'otro' || 'other' => CompanySectorId.other,
    _ => raw,
  };
}

String? resolveContractId(String? raw, AppLocalizations l10n) {
  final fromOptions = resolveCatalogId(raw, vacancyContractTypes(l10n));
  if (fromOptions != null) return fromOptions;
  return switch (_norm(raw ?? '')) {
    'indefinido' || 'open-ended' || 'open ended' => VacancyContractId.indefinite,
    'término fijo' || 'termino fijo' || 'fixed term' => VacancyContractId.fixed,
    'prestación de servicios' ||
    'prestacion de servicios' ||
    'independent contractor' => VacancyContractId.services,
    'práctica o pasantía' ||
    'practica o pasantia' ||
    'internship' => VacancyContractId.internship,
    'temporal' || 'temporary' => VacancyContractId.temporary,
    _ => raw,
  };
}

List<CatalogOption> _allAreas(AppLocalizations l10n) => [
  CatalogOption(VacancyAreaId.people, l10n.areaPeople),
  CatalogOption(VacancyAreaId.financeOps, l10n.areaFinanceOps),
  CatalogOption(VacancyAreaId.operations, l10n.areaOperations),
  CatalogOption(VacancyAreaId.commercial, l10n.areaCommercial),
  CatalogOption(VacancyAreaId.customer, l10n.areaCustomer),
  CatalogOption(VacancyAreaId.admin, l10n.areaAdmin),
  CatalogOption(VacancyAreaId.engineering, l10n.areaEngineering),
  CatalogOption(VacancyAreaId.product, l10n.areaProduct),
  CatalogOption(VacancyAreaId.data, l10n.areaData),
  CatalogOption(VacancyAreaId.support, l10n.areaSupport),
  CatalogOption(VacancyAreaId.risk, l10n.areaRisk),
  CatalogOption(VacancyAreaId.accounting, l10n.areaAccounting),
  CatalogOption(VacancyAreaId.clinical, l10n.areaClinical),
  CatalogOption(VacancyAreaId.care, l10n.areaCare),
  CatalogOption(VacancyAreaId.academic, l10n.areaAcademic),
  CatalogOption(VacancyAreaId.training, l10n.areaTraining),
  CatalogOption(VacancyAreaId.production, l10n.areaProduction),
  CatalogOption(VacancyAreaId.quality, l10n.areaQuality),
  CatalogOption(VacancyAreaId.maintenance, l10n.areaMaintenance),
  CatalogOption(VacancyAreaId.store, l10n.areaStore),
  CatalogOption(VacancyAreaId.logistics, l10n.areaLogistics),
  CatalogOption(VacancyAreaId.projects, l10n.areaProjects),
  CatalogOption(VacancyAreaId.field, l10n.areaField),
  CatalogOption(VacancyAreaId.publicService, l10n.areaPublicService),
  CatalogOption(VacancyAreaId.other, l10n.areaOther),
];

String vacancyAreaLabel(AppLocalizations l10n, String? raw) =>
    catalogLabel(l10n, raw, _allAreas(l10n));

abstract final class VacancyWorkMode {
  static const onsite = 'onsite';
  static const remote = 'remote';
  static const hybrid = 'hybrid';
}

abstract final class VacancySeniority {
  static const junior = 'junior';
  static const mid = 'mid';
  static const senior = 'senior';
  static const lead = 'lead';
}

enum VacancySectorFocus {
  technology,
  finance,
  health,
  education,
  manufacturing,
  retail,
  services,
  construction,
  energy,
  agribusiness,
  government,
  other,
}

VacancySectorFocus vacancySectorFocus(String? sector, AppLocalizations l10n) {
  return switch (resolveCompanySectorId(sector, l10n)) {
    CompanySectorId.technology => VacancySectorFocus.technology,
    CompanySectorId.finance => VacancySectorFocus.finance,
    CompanySectorId.health => VacancySectorFocus.health,
    CompanySectorId.education => VacancySectorFocus.education,
    CompanySectorId.manufacturing => VacancySectorFocus.manufacturing,
    CompanySectorId.retail => VacancySectorFocus.retail,
    CompanySectorId.services => VacancySectorFocus.services,
    CompanySectorId.construction => VacancySectorFocus.construction,
    CompanySectorId.energy => VacancySectorFocus.energy,
    CompanySectorId.agribusiness => VacancySectorFocus.agribusiness,
    CompanySectorId.government => VacancySectorFocus.government,
    _ => VacancySectorFocus.other,
  };
}

List<CatalogOption> vacancyAreasForSector(AppLocalizations l10n, String? sector) {
  final shared = [
    CatalogOption(VacancyAreaId.people, l10n.areaPeople),
    CatalogOption(VacancyAreaId.financeOps, l10n.areaFinanceOps),
    CatalogOption(VacancyAreaId.operations, l10n.areaOperations),
    CatalogOption(VacancyAreaId.commercial, l10n.areaCommercial),
    CatalogOption(VacancyAreaId.customer, l10n.areaCustomer),
    CatalogOption(VacancyAreaId.admin, l10n.areaAdmin),
  ];
  final extra = switch (vacancySectorFocus(sector, l10n)) {
    VacancySectorFocus.technology || VacancySectorFocus.services => [
      CatalogOption(VacancyAreaId.engineering, l10n.areaEngineering),
      CatalogOption(VacancyAreaId.product, l10n.areaProduct),
      CatalogOption(VacancyAreaId.data, l10n.areaData),
      CatalogOption(VacancyAreaId.support, l10n.areaSupport),
    ],
    VacancySectorFocus.finance => [
      CatalogOption(VacancyAreaId.risk, l10n.areaRisk),
      CatalogOption(VacancyAreaId.accounting, l10n.areaAccounting),
    ],
    VacancySectorFocus.health => [
      CatalogOption(VacancyAreaId.clinical, l10n.areaClinical),
      CatalogOption(VacancyAreaId.care, l10n.areaCare),
    ],
    VacancySectorFocus.manufacturing => [
      CatalogOption(VacancyAreaId.production, l10n.areaProduction),
      CatalogOption(VacancyAreaId.quality, l10n.areaQuality),
      CatalogOption(VacancyAreaId.maintenance, l10n.areaMaintenance),
    ],
    VacancySectorFocus.retail => [
      CatalogOption(VacancyAreaId.store, l10n.areaStore),
      CatalogOption(VacancyAreaId.logistics, l10n.areaLogistics),
    ],
    VacancySectorFocus.construction => [
      CatalogOption(VacancyAreaId.projects, l10n.areaProjects),
      CatalogOption(VacancyAreaId.field, l10n.areaField),
    ],
    VacancySectorFocus.energy => [
      CatalogOption(VacancyAreaId.field, l10n.areaField),
      CatalogOption(VacancyAreaId.quality, l10n.areaQuality),
    ],
    VacancySectorFocus.agribusiness => [
      CatalogOption(VacancyAreaId.field, l10n.areaField),
      CatalogOption(VacancyAreaId.logistics, l10n.areaLogistics),
    ],
    VacancySectorFocus.government => [
      CatalogOption(VacancyAreaId.publicService, l10n.areaPublicService),
      CatalogOption(VacancyAreaId.projects, l10n.areaProjects),
    ],
    VacancySectorFocus.education => [
      CatalogOption(VacancyAreaId.academic, l10n.areaAcademic),
      CatalogOption(VacancyAreaId.training, l10n.areaTraining),
    ],
    VacancySectorFocus.other => const <CatalogOption>[],
  };
  final ids = {for (final item in shared) item.id};
  return [
    ...shared,
    ...extra.where((item) => !ids.contains(item.id)),
    CatalogOption(VacancyAreaId.other, l10n.areaOther),
  ];
}

String vacancyWorkModeLabel(AppLocalizations l10n, String? raw) {
  final key = _norm(raw ?? '');
  return switch (raw) {
    VacancyWorkMode.onsite || 'presencial' || 'on-site' || 'onsite' =>
      l10n.workModeOnsite,
    VacancyWorkMode.remote || 'virtual' || 'remoto' || 'remote' =>
      l10n.workModeRemote,
    VacancyWorkMode.hybrid || 'híbrida' || 'hibrida' || 'hybrid' =>
      l10n.workModeHybrid,
    _ => switch (key) {
      'presencial' || 'on-site' => l10n.workModeOnsite,
      'virtual' || 'remoto' => l10n.workModeRemote,
      'hibrida' || 'híbrida' || 'hybrid' => l10n.workModeHybrid,
      _ => raw ?? '',
    },
  };
}

String vacancySeniorityLabel(AppLocalizations l10n, String? raw) {
  final key = _norm(raw ?? '');
  return switch (raw) {
    VacancySeniority.junior => l10n.seniorityJunior,
    VacancySeniority.mid => l10n.seniorityMid,
    VacancySeniority.senior => l10n.senioritySenior,
    VacancySeniority.lead => l10n.seniorityLead,
    _ => switch (key) {
      'inicial' || 'entry level' || 'junior' => l10n.seniorityJunior,
      'intermedio' || 'intermediate' || 'mid level' || 'mid' =>
        l10n.seniorityMid,
      'con experiencia' || 'experienced' || 'senior' => l10n.senioritySenior,
      'liderazgo' || 'leadership' || 'lead' => l10n.seniorityLead,
      _ => raw ?? '',
    },
  };
}

String? resolveWorkModeId(String? raw) {
  final key = _norm(raw ?? '');
  return switch (key) {
    'onsite' || 'presencial' || 'on-site' => VacancyWorkMode.onsite,
    'remote' || 'virtual' || 'remoto' => VacancyWorkMode.remote,
    'hybrid' || 'hibrida' || 'híbrida' => VacancyWorkMode.hybrid,
    _ => raw,
  };
}

String? resolveSeniorityId(String? raw) {
  final key = _norm(raw ?? '');
  return switch (key) {
    'junior' || 'inicial' || 'entry level' => VacancySeniority.junior,
    'mid' || 'intermedio' || 'intermediate' || 'mid level' =>
      VacancySeniority.mid,
    'senior' || 'con experiencia' || 'experienced' => VacancySeniority.senior,
    'lead' || 'liderazgo' || 'leadership' => VacancySeniority.lead,
    _ => raw,
  };
}

bool vacancyWorkModeNeedsCity(String? mode) {
  final id = resolveWorkModeId(mode);
  return id == VacancyWorkMode.onsite || id == VacancyWorkMode.hybrid;
}

List<UserRole> companyInviteRoles() => const [
  UserRole.companyAdmin,
  UserRole.companyLead,
  UserRole.peopleOps,
  UserRole.recruiter,
  UserRole.hiringManager,
];

String teamRoleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
  UserRole.companyAdmin => l10n.teamRoleCompanyAdmin,
  UserRole.companyLead => l10n.teamRoleCompanyLead,
  UserRole.peopleOps => l10n.teamRolePeopleOps,
  UserRole.recruiter => l10n.teamRoleRecruiter,
  UserRole.hiringManager => l10n.teamRoleHiringManager,
  _ => role.value,
};

/// Texto de la ficha de afinidad cuando todavía no hay un análisis listo.
String affinityAnalysisMessage(
  AppLocalizations l10n,
  AffinityAnalysis analysis, {
  required bool evaluationCompleted,
}) {
  if (analysis.hasResult) return analysis.summary;
  if (!evaluationCompleted) return l10n.affinityUnknownHint;
  return switch (analysis.status) {
    AffinityAnalysisStatus.pending => l10n.affinityAnalysisPending,
    AffinityAnalysisStatus.failed => l10n.affinityAnalysisFailed,
    AffinityAnalysisStatus.insufficientData =>
      analysis.errorCode == 'answers_incomplete'
          ? l10n.affinityAnalysisIncompleteAnswers
          : l10n.affinityAnalysisMissingDna,
    _ => l10n.affinityAnalysisNone,
  };
}

List<String> dnaValueOptions({
  required String languageCode,
  List<DnaCatalogEntry> catalog = const [],
  List<String> extra = const [],
}) => uniqueDnaLabels([
  ...dnaValuePresets.map((item) => dnaCatalogLabel(item, languageCode)),
  ...catalog
      .where((item) => item.type == DnaCatalogType.values)
      .map((item) => item.labelFor(languageCode)),
  ...extra,
]);

List<String> dnaCultureOptions({
  required String languageCode,
  List<DnaCatalogEntry> catalog = const [],
  List<String> extra = const [],
}) => uniqueDnaLabels([
  ...dnaCulturePresets.map((item) => dnaCatalogLabel(item, languageCode)),
  ...catalog
      .where((item) => item.type == DnaCatalogType.culture)
      .map((item) => item.labelFor(languageCode)),
  ...extra,
]);

List<String> dnaStandoutOptions({
  required String languageCode,
  List<DnaCatalogEntry> catalog = const [],
  List<String> extra = const [],
}) => uniqueDnaLabels([
  ...dnaStandoutPresets.map((item) => dnaCatalogLabel(item, languageCode)),
  ...catalog
      .where((item) => item.type == DnaCatalogType.standout)
      .map((item) => item.labelFor(languageCode)),
  ...extra,
]);

String assessmentInstruction(AppLocalizations l10n, AssessmentItem item) =>
    switch (item.block) {
      AssessmentBlock.workValues => l10n.assessmentPairInstruction,
      AssessmentBlock.needs => l10n.assessmentNeedInstruction,
      AssessmentBlock.capabilities => l10n.assessmentExperienceInstruction,
    };

List<String> assessmentScaleLabels(
  AppLocalizations l10n,
  AssessmentFormat format,
) => switch (format) {
  AssessmentFormat.pair => [
    l10n.pairScale1,
    l10n.pairScale2,
    l10n.pairScale3,
    l10n.pairScale4,
    l10n.pairScale5,
  ],
  AssessmentFormat.experience => [
    l10n.frequencyScale1,
    l10n.frequencyScale2,
    l10n.frequencyScale3,
    l10n.frequencyScale4,
    l10n.frequencyScale5,
  ],
};

/// Enunciado legible de una pregunta; en pares incluye ambas frases.
String assessmentQuestionLabel(AppLocalizations l10n, String id) {
  final item = AssessmentCatalog.byId(id);
  if (item == null) return id;
  final a = item.statementA.of(l10n.localeName);
  if (!item.isPair) return a;
  final b = item.statementB!.of(l10n.localeName);
  return 'A: $a\nB: $b';
}

String assessmentAnswerLabel(AppLocalizations l10n, String id, int value) {
  final item = AssessmentCatalog.byId(id);
  if (item == null || value < 1 || value > 5) return '$value';
  return assessmentScaleLabels(l10n, item.format)[value - 1];
}
