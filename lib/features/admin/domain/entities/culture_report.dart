import 'package:equatable/equatable.dart';

// Informe de cultura ya analizado (GET /api/cultura/{id}/informe). El backend
// hace todo el análisis; aquí solo se leen los campos con tipos y valores por
// defecto para que un campo faltante no rompa la vista. La copia de las
// respuestas que trae el informe ("respuestas") se ignora: ya se muestra en
// el detalle de la encuesta.

class CultureReportCoverage extends Equatable {
  const CultureReportCoverage({
    required this.respondents,
    required this.needed,
    required this.percent,
    required this.reached,
    this.employeeRange,
  });

  final int respondents;
  final int needed;
  final num percent;
  final bool reached;
  final String? employeeRange;

  factory CultureReportCoverage.fromMap(Map<String, dynamic> map) =>
      CultureReportCoverage(
        respondents: _int(map['respondents']),
        needed: _int(map['needed']),
        percent: _num(map['percent']),
        reached: map['reached'] == true,
        employeeRange: _str(map['employeeRange']),
      );

  @override
  List<Object?> get props => [respondents, needed, percent, reached];
}

/// Puntaje de un valor para líderes y empleados (escala de -1 a 1).
class CultureMirrorValue extends Equatable {
  const CultureMirrorValue({
    required this.value,
    required this.leaders,
    required this.employees,
    required this.gap,
    required this.status,
  });

  final String value;
  final double leaders;
  final double employees;
  final double gap;
  final String status;

  factory CultureMirrorValue.fromMap(Map<String, dynamic> map) =>
      CultureMirrorValue(
        value: _str(map['valor']) ?? '',
        leaders: _num(map['lideres']).toDouble(),
        employees: _num(map['empleados']).toDouble(),
        gap: _num(map['brecha']).toDouble(),
        status: _str(map['estado']) ?? '',
      );

  @override
  List<Object?> get props => [value, leaders, employees, gap, status];
}

class CultureDeclaredValue extends Equatable {
  const CultureDeclaredValue({
    required this.declared,
    required this.talexValue,
    required this.leaders,
    required this.employees,
    required this.verdict,
  });

  final String declared;
  final String talexValue;
  final double leaders;
  final double employees;

  /// se_vive, a_medias o solo_en_la_pared.
  final String verdict;

  factory CultureDeclaredValue.fromMap(Map<String, dynamic> map) =>
      CultureDeclaredValue(
        declared: _str(map['valor_declarado']) ?? '',
        talexValue: _str(map['valor_taleX']) ?? '',
        leaders: _num(map['lideres']).toDouble(),
        employees: _num(map['empleados']).toDouble(),
        verdict: _str(map['veredicto']) ?? '',
      );

  @override
  List<Object?> get props => [declared, verdict, leaders, employees];
}

class CultureReport extends Equatable {
  const CultureReport(this._data);

  final Map<String, dynamic> _data;

  factory CultureReport.fromMap(Map<String, dynamic> map) => CultureReport(map);

  Map<String, dynamic> get _informe => _map(_data['informe']);
  Map<String, dynamic> _block(String key) => _map(_informe[key]);

  String get organizationName =>
      _str(_data['organizationName']) ??
      _str(_block('empresa')['nombre']) ??
      '';

  /// "generated" cuando hay informe; otro valor si aún se recolectan datos.
  String get status => _str(_data['status']) ?? '';
  bool get hasReport => _informe.isNotEmpty;

  String? get cutoffDate => _str(_block('empresa')['fecha_corte']);

  CultureReportCoverage get coverage =>
      CultureReportCoverage.fromMap(_map(_data['coverage']));

  /// Resúmenes cortos por sección (cultura, liderazgo, trabajo...).
  List<(String, String)> get sections => [
    for (final item in _list(_data['sections']))
      (_str(item['title']) ?? '', _str(item['summary']) ?? ''),
  ];

  // Resumen ejecutivo.
  String get headline => _str(_block('resumen_ejecutivo')['titular']) ?? '';
  String get validation =>
      _str(_block('resumen_ejecutivo')['veredicto_validacion']) ?? '';
  List<String> get keyPoints =>
      _strings(_block('resumen_ejecutivo')['lo_que_debe_saber']);
  String? get uncomfortableTruth =>
      _str(_block('resumen_ejecutivo')['verdad_incomoda']);

  // Calidad de datos.
  Map<String, dynamic> get _quality => _block('calidad_de_datos');
  int get leaderAnswers => _int(_quality['respuestas_lideres']);
  int get employeeAnswers => _int(_quality['respuestas_empleados']);
  int get requiredSample => _int(_quality['muestra_requerida']);
  num get sampleCoverage => _num(_quality['cobertura_muestra_pct']);
  String get confidence => _str(_quality['nivel_confianza']) ?? '';
  List<String> get qualityAlerts => _strings(_quality['alertas']);
  List<(String, num, num, String)> get areaRepresentation => [
    for (final item in _list(_quality['representatividad_por_area']))
      (
        _str(item['area']) ?? '',
        _num(item['pct_plantilla']),
        _num(item['pct_respuestas']),
        _str(item['estado']) ?? '',
      ),
  ];

  // ADN cultural.
  Map<String, dynamic> get _dna => _block('adn_cultural');
  String get archetype => _str(_dna['arquetipo']) ?? '';
  String get dnaDescription => _str(_dna['descripcion']) ?? '';
  List<String> get dominantValues => _strings(_dna['valores_dominantes']);
  List<String> get weakValues => _strings(_dna['valores_debiles']);
  int get cultureStrength => _int(_map(_dna['fuerza_cultural'])['indice']);
  String get cultureStrengthLevel =>
      _str(_map(_dna['fuerza_cultural'])['nivel']) ?? '';
  String get cultureStrengthReading =>
      _str(_map(_dna['fuerza_cultural'])['lectura']) ?? '';

  // Espejo de liderazgo.
  Map<String, dynamic> get _mirror => _block('espejo_liderazgo');
  int get alignment => _int(_mirror['indice_alineacion']);
  String get mirrorReading => _str(_mirror['lectura']) ?? '';
  List<CultureMirrorValue> get mirrorValues => [
    for (final item in _list(_mirror['por_valor']))
      CultureMirrorValue.fromMap(item),
  ];
  List<(String, String, String)> get blindSpots => [
    for (final item in _list(_mirror['puntos_ciegos']))
      (
        _str(item['descripcion']) ?? '',
        _str(item['evidencia']) ?? '',
        _str(item['impacto_en_contratacion']) ?? '',
      ),
  ];

  // Dicho contra hecho.
  Map<String, dynamic> get _said => _block('dicho_vs_hecho');
  int get leaderCoherence => _int(_said['coherencia_lideres']);
  int get employeeCoherence => _int(_said['coherencia_empleados']);
  String get saidReading => _str(_said['lectura']) ?? '';
  List<CultureDeclaredValue> get declaredValues => [
    for (final item in _list(_said['por_valor_declarado']))
      CultureDeclaredValue.fromMap(item),
  ];

  // Propuesta de valor real.
  Map<String, dynamic> get _offer => _block('propuesta_de_valor_real');
  List<String> get offered => _strings(_offer['lo_que_si_se_ofrece']);
  List<String> get notOffered => _strings(_offer['lo_que_no_se_ofrece']);
  List<(String, String)> get unconfirmedPromises => [
    for (final item in _list(_offer['promesas_no_confirmadas']))
      (_str(item['necesidad']) ?? '', _str(item['riesgo']) ?? ''),
  ];

  // Lectura de sinceridad.
  String? get sincerityReading =>
      _str(_block('lectura_de_sinceridad')['lectura']);

  // Voz de los empleados: (cita, valor, frecuencia %).
  List<(String, String, num)> _voices(String key) => [
    for (final item in _list(_block('voz_de_los_empleados')[key]))
      (
        _str(item['cita_anonima']) ?? _str(item['tema']) ?? '',
        _str(item['valor']) ?? '',
        _num(item['frecuencia_pct']),
      ),
  ];
  List<(String, String, num)> get doingWell => _voices('le_va_bien_al_que');
  List<(String, String, num)> get doingBadly => _voices('le_va_mal_al_que');

  // Implicaciones para contratar.
  Map<String, dynamic> get _hiring => _block('implicaciones_para_contratar');
  String get thrivingCandidate => _str(_hiring['candidato_que_prospera']) ?? '';
  String get atRiskCandidate => _str(_hiring['candidato_en_riesgo']) ?? '';
  String get honestMessage =>
      _str(_hiring['mensaje_honesto_para_candidatos']) ?? '';
  List<(String, String, String, String)> get hiringRisks => [
    for (final item in _list(_hiring['riesgos_de_contratacion']))
      (
        _str(item['riesgo']) ?? '',
        _str(item['probabilidad']) ?? '',
        _str(item['evidencia']) ?? '',
        _str(item['mitigacion']) ?? '',
      ),
  ];
  List<(String, String)> get interviewQuestions => [
    for (final item in _list(_hiring['preguntas_de_entrevista']))
      (_str(item['pregunta']) ?? '', _str(item['que_revela']) ?? ''),
  ];

  /// Recomendaciones: (prioridad, acción, responsable, plazo, indicador).
  List<(int, String, String, String, String)> get recommendations => [
    for (final item in _list(_informe['recomendaciones']))
      (
        _int(item['prioridad']),
        _str(item['accion']) ?? '',
        _str(item['responsable_sugerido']) ?? '',
        _str(item['plazo']) ?? '',
        _str(item['indicador_de_exito']) ?? '',
      ),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  // Sello TaleX.
  Map<String, dynamic> get _seal => _block('sello_taleX');
  String get sealStatus => _str(_seal['estado']) ?? validation;
  String get sealText => _str(_seal['texto_del_sello']) ?? '';
  List<String> get sealMet => _strings(_seal['condiciones_cumplidas']);
  List<String> get sealPending => _strings(_seal['condiciones_pendientes']);
  int? get sealMonths =>
      _seal['vigencia_meses'] is num ? _int(_seal['vigencia_meses']) : null;

  List<String> get limitations => _strings(_informe['limitaciones']);

  @override
  List<Object?> get props => [_data];
}

/// Limpia un texto del backend para mostrarlo tal cual: quita marcas técnicas
/// (tamaños de muestra "n=15", rangos de preguntas "C01–C08", clasificaciones
/// entre paréntesis) y cambia códigos por palabras.
String plainReportText(String text) => text
    .replaceAll(
      RegExp(r'\s*\((?:empleados|líderes|lideres)?\s*n\s*=\s*\d+\)'),
      '',
    )
    .replaceAll(
      RegExp(
        r'(?:Líderes|Lideres|Empleados|líderes|empleados)\s*n\s*=\s*\d+[;.]?\s*',
      ),
      '',
    )
    .replaceAll(RegExp(r'\bC\d{2}\s*[–-]\s*C\d{2}\.?\s*'), '')
    .replaceAll(
      RegExp(r'\s*\((?:moderada|alineado|crítica|critica|leve)\)'),
      '',
    )
    .replaceAll('no_validada', 'en camino')
    .replaceAll('se_vive', 'se vive')
    .replaceAll('solo_en_la_pared', 'solo en el papel')
    .replaceAll(RegExp(r'\s{2,}'), ' ')
    .trim();

/// "no_validada" → "No validada"; "30_dias" → "30 días".
String humanizeReportCode(String code) {
  final text = code
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\bdias\b'), 'días')
      .trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> _list(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
];

List<String> _strings(Object? value) => [
  if (value is List)
    for (final item in value)
      if ('$item'.trim().isNotEmpty) '$item'.trim(),
];

String? _str(Object? value) {
  final text = value == null ? '' : '$value'.trim();
  return text.isEmpty ? null : text;
}

num _num(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;

int _int(Object? value) => _num(value).round();
