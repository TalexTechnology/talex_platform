import 'package:equatable/equatable.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';

// Respuesta de `culture_leads_by_organization`: leads de la landing
// /micultura agrupados por la empresa que se creó para cada uno.

class CultureCount extends Equatable {
  const CultureCount({required this.label, required this.count, this.pct});

  final String label;
  final int count;
  final num? pct;

  factory CultureCount.fromMap(Map<String, dynamic> map) => CultureCount(
    label: '${map['label'] ?? ''}',
    count: _int(map['count']),
    pct: map['pct'] is num ? map['pct'] as num : null,
  );

  @override
  List<Object?> get props => [label, count, pct];
}

class CultureComment extends Equatable {
  const CultureComment({
    required this.leadId,
    required this.comment,
    this.createdAt,
  });

  final String leadId;
  final String comment;
  final DateTime? createdAt;

  factory CultureComment.fromMap(Map<String, dynamic> map) => CultureComment(
    leadId: '${map['leadId'] ?? ''}',
    comment: '${map['comment'] ?? ''}'.trim(),
    createdAt: _date(map['created_at']),
  );

  @override
  List<Object?> get props => [leadId, comment, createdAt];
}

class CultureSummary extends Equatable {
  const CultureSummary({
    required this.leadCount,
    required this.respondedCount,
    required this.uniqueEmails,
    required this.perceivedCulture,
    required this.employeeRanges,
    required this.comments,
    this.firstLeadAt,
    this.lastLeadAt,
  });

  final int leadCount;
  final int respondedCount;
  final int uniqueEmails;
  final DateTime? firstLeadAt;
  final DateTime? lastLeadAt;
  final List<CultureCount> perceivedCulture;
  final List<CultureCount> employeeRanges;
  final List<CultureComment> comments;

  factory CultureSummary.fromMap(Map<String, dynamic> map) => CultureSummary(
    leadCount: _int(map['leadCount']),
    respondedCount: _int(map['respondedCount']),
    uniqueEmails: _int(map['uniqueEmails']),
    firstLeadAt: _date(map['firstLeadAt']),
    lastLeadAt: _date(map['lastLeadAt']),
    perceivedCulture: _list(map['perceivedCulture'], CultureCount.fromMap),
    employeeRanges: _list(map['employeeRanges'], CultureCount.fromMap),
    comments: _list(
      map['comments'],
      CultureComment.fromMap,
    ).where((item) => item.comment.isNotEmpty).toList(),
  );

  @override
  List<Object?> get props => [
    leadCount,
    respondedCount,
    uniqueEmails,
    firstLeadAt,
    lastLeadAt,
    perceivedCulture,
    employeeRanges,
    comments,
  ];
}

// Campos del lead que [CultureLead] no trae y que solo expone este reporte.
class CultureReportLead extends Equatable {
  const CultureReportLead({
    required this.lead,
    this.contactName,
    this.emailStatus,
    this.respondedAt,
  });

  final CultureLead lead;
  final String? contactName;
  final String? emailStatus;
  final DateTime? respondedAt;

  bool get responded => respondedAt != null;

  factory CultureReportLead.fromMap(Map<String, dynamic> map) {
    final contact = '${map['contact_name'] ?? ''}'.trim();
    final emailStatus = '${map['email_status'] ?? ''}'.trim();
    return CultureReportLead(
      lead: CultureLead.fromMap(map),
      contactName: contact.isEmpty ? null : contact,
      emailStatus: emailStatus.isEmpty ? null : emailStatus,
      respondedAt: _date(map['responded_at']),
    );
  }

  @override
  List<Object?> get props => [lead, contactName, emailStatus, respondedAt];
}

class CultureOrganizationGroup extends Equatable {
  const CultureOrganizationGroup({
    required this.summary,
    required this.leads,
    this.id,
    this.name,
    this.sizeLabel,
    this.createdAt,
  });

  // Null en el grupo de leads sin empresa asignada.
  final String? id;
  final String? name;
  final String? sizeLabel;
  final DateTime? createdAt;
  final CultureSummary summary;
  final List<CultureReportLead> leads;

  bool get unassigned => id == null;

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return (name ?? '').toLowerCase().contains(needle) ||
        leads.any(
          (item) =>
              item.lead.email.toLowerCase().contains(needle) ||
              item.lead.companyName.toLowerCase().contains(needle) ||
              (item.contactName ?? '').toLowerCase().contains(needle),
        );
  }

  factory CultureOrganizationGroup.fromMap(Map<String, dynamic> map) {
    final organization = map['organization'] is Map
        ? Map<String, dynamic>.from(map['organization'] as Map)
        : null;
    final size = '${organization?['size_label'] ?? ''}'.trim();
    return CultureOrganizationGroup(
      id: organization == null ? null : '${organization['id'] ?? ''}',
      name: organization == null ? null : '${organization['name'] ?? ''}',
      sizeLabel: size.isEmpty ? null : size,
      createdAt: _date(organization?['created_at']),
      summary: CultureSummary.fromMap(
        map['summary'] is Map
            ? Map<String, dynamic>.from(map['summary'] as Map)
            : const {},
      ),
      leads: _list(map['leads'], CultureReportLead.fromMap),
    );
  }

  @override
  List<Object?> get props => [id, name, sizeLabel, createdAt, summary, leads];
}

class CultureOrganizationReport extends Equatable {
  const CultureOrganizationReport({
    required this.organizationCount,
    required this.leadCount,
    required this.unassignedLeads,
    required this.organizations,
    this.unassigned,
    this.generatedAt,
  });

  final DateTime? generatedAt;
  final int organizationCount;
  final int leadCount;
  final int unassignedLeads;
  final List<CultureOrganizationGroup> organizations;
  final CultureOrganizationGroup? unassigned;

  int get respondedCount => [
    ...organizations,
    ?unassigned,
  ].fold(0, (total, group) => total + group.summary.respondedCount);

  List<CultureOrganizationGroup> get groups => [
    ...organizations,
    if (unassigned != null && unassigned!.leads.isNotEmpty) unassigned!,
  ];

  factory CultureOrganizationReport.fromMap(Map<String, dynamic> map) {
    final totals = map['totals'] is Map
        ? Map<String, dynamic>.from(map['totals'] as Map)
        : const <String, dynamic>{};
    final organizations =
        _list(map['organizations'], CultureOrganizationGroup.fromMap)..sort(
          (a, b) => (b.summary.lastLeadAt ?? DateTime(0)).compareTo(
            a.summary.lastLeadAt ?? DateTime(0),
          ),
        );
    return CultureOrganizationReport(
      generatedAt: _date(map['generatedAt']),
      organizationCount: _int(totals['organizations']),
      leadCount: _int(totals['leads']),
      unassignedLeads: _int(totals['unassignedLeads']),
      organizations: organizations,
      unassigned: map['unassigned'] is Map
          ? CultureOrganizationGroup.fromMap(
              Map<String, dynamic>.from(map['unassigned'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
    generatedAt,
    organizationCount,
    leadCount,
    unassignedLeads,
    organizations,
    unassigned,
  ];
}

int _int(Object? value) => value is num ? value.toInt() : 0;

DateTime? _date(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) => [
  if (value is List)
    for (final item in value)
      if (item is Map) parse(Map<String, dynamic>.from(item)),
];
