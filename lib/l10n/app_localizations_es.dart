// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'TaleX';

  @override
  String get secureSignIn => 'Inicio de sesión seguro';

  @override
  String get workEmail => 'Correo electrónico';

  @override
  String get emailAddress => 'Correo electrónico';

  @override
  String get emailAddressHint => 'candidato@correo.com';

  @override
  String get validEmailAddressError => 'Ingresa un correo electrónico válido';

  @override
  String get emailHint => 'correo@ejemplo.com';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get continueWith => 'O continúa con';

  @override
  String get signInGoogle => 'Iniciar sesión con Google';

  @override
  String get signUpGoogle => 'Crear cuenta con Google';

  @override
  String get googleSignInError =>
      'No se pudo iniciar sesión con Google. Inténtalo nuevamente.';

  @override
  String get newToTalex => '¿Nuevo en TaleX?';

  @override
  String get createAccountLink => 'Crear cuenta';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get validEmailError => 'Ingresa un correo electrónico válido';

  @override
  String get passwordLengthError =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get resetEmailSent =>
      'Revisa tu correo para restablecer la contraseña.';

  @override
  String get createAccount => 'Crea tu cuenta';

  @override
  String get registerSubtitle => 'Crea tu cuenta para comenzar en TaleX.';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get fullNameHint => 'María Pérez';

  @override
  String get companyName => 'Nombre de la empresa';

  @override
  String get companyHint => 'Empresa S.A.S.';

  @override
  String get signUp => 'Registrarse';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get logIn => 'Inicia sesión';

  @override
  String get requiredField => 'Este campo es obligatorio';

  @override
  String get testimonial =>
      '“TaleX transformó nuestro proceso de selección y ayudó a nuestro equipo a tomar mejores decisiones.”';

  @override
  String welcomeUser(String name) {
    return 'Bienvenido, $name';
  }

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get dashboard => 'Panel principal';

  @override
  String get roles => 'Invitaciones';

  @override
  String get candidates => 'Personas habilitadas';

  @override
  String get assessments => 'Evaluaciones';

  @override
  String get managers => 'Equipo';

  @override
  String get reports => 'Reportes';

  @override
  String get settings => 'Configuración';

  @override
  String get support => 'Soporte';

  @override
  String get documentation => 'Documentación';

  @override
  String get searchHint => 'Buscar personas, invitaciones o evaluaciones...';

  @override
  String get overview => 'Resumen';

  @override
  String get overviewSubtitle =>
      'Seguimiento general de las evaluaciones asignadas por tu equipo.';

  @override
  String get generateReport => 'Generar reporte';

  @override
  String get newRole => 'Habilitar persona';

  @override
  String get activeRoles => 'Invitaciones enviadas';

  @override
  String get evaluatedCandidates => 'Pendientes de iniciar';

  @override
  String get averageFitScore => 'Evaluaciones en curso';

  @override
  String get hiringVelocity => 'Evaluaciones completadas';

  @override
  String get thisWeekChange => '+8 esta semana';

  @override
  String get thisMonthChange => '5 vencen próximamente';

  @override
  String get stableTopRoles => 'Actividad en tiempo real';

  @override
  String get daysFromQuarter => '+42 este mes';

  @override
  String get topMatches => 'Actividad reciente';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get candidate => 'Candidato';

  @override
  String get matchedRole => 'Evaluación';

  @override
  String get affinity => 'Estado';

  @override
  String get action => 'Acción';

  @override
  String get pendingActions => 'Acciones pendientes';

  @override
  String get reviewRequirements => 'Resultados listos para revisar';

  @override
  String get finalApproval => 'Invitaciones próximas a vencer';

  @override
  String get scheduleInterview => 'Evaluación interrumpida';

  @override
  String get statusCompleted => 'Completada';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get logicalReasoningAssessment => 'Razonamiento lógico';

  @override
  String get decisionMakingAssessment => 'Toma de decisiones';

  @override
  String get problemSolvingAssessment => 'Resolución de problemas';

  @override
  String get completedToday => 'Completada hoy';

  @override
  String get expiresTomorrow => '5 invitaciones vencen mañana';

  @override
  String get connectionInterrupted => 'Requiere seguimiento del reclutador';

  @override
  String get invitationsTitle => 'Invitaciones';

  @override
  String get invitationsSubtitle =>
      'Habilita personas y realiza seguimiento a sus evaluaciones.';

  @override
  String get enablePerson => 'Habilitar persona';

  @override
  String get enablePersonSubtitle =>
      'Asigna una evaluación y envía una invitación de acceso.';

  @override
  String get personName => 'Nombre de la persona';

  @override
  String get personNameHint => 'Nombre y apellido';

  @override
  String get selectAssessment => 'Evaluación asignada';

  @override
  String get invitationExpiry => 'Vigencia de la invitación';

  @override
  String daysValue(int count) {
    return '$count días';
  }

  @override
  String get optionalMessage => 'Mensaje opcional';

  @override
  String get optionalMessageHint => 'Agrega instrucciones para la persona...';

  @override
  String get sendInvitation => 'Enviar invitación';

  @override
  String get invitationSent =>
      'La persona fue habilitada y la invitación fue creada.';

  @override
  String get invitationResent =>
      'La invitación fue reenviada y su vigencia fue renovada.';

  @override
  String get invitationCancelled => 'La invitación fue cancelada.';

  @override
  String get noInvitations => 'Aún no hay personas habilitadas';

  @override
  String get noInvitationsDescription =>
      'Habilita la primera persona para asignarle una evaluación.';

  @override
  String expiresOn(String date) {
    return 'Vence: $date';
  }

  @override
  String get resend => 'Reenviar';

  @override
  String get cancelInvitation => 'Cancelar invitación';

  @override
  String get confirmCancellation =>
      '¿Deseas cancelar esta invitación? La persona perderá el acceso a la evaluación.';

  @override
  String get keepInvitation => 'Conservar';

  @override
  String get statusExpired => 'Vencida';

  @override
  String get statusCancelled => 'Cancelada';

  @override
  String get statusInterrupted => 'Interrumpida';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSubtitle =>
      'Administra tu organización, procesos de contratación y seguridad.';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get changesSaved => 'Los cambios se guardaron correctamente.';

  @override
  String get organizationProfile => 'Perfil de la organización';

  @override
  String get organizationDescription =>
      'Información que identifica a tu empresa dentro de TaleX.';

  @override
  String get organizationName => 'Nombre de la organización';

  @override
  String get industry => 'Industria';

  @override
  String get companySize => 'Tamaño de la empresa';

  @override
  String get timezone => 'Zona horaria';

  @override
  String get timezoneBogota => 'Bogotá (UTC-5)';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsDescription =>
      'Elige qué actualizaciones deseas recibir.';

  @override
  String get candidateUpdates => 'Actividad de evaluaciones';

  @override
  String get candidateUpdatesDescription =>
      'Avisos cuando una evaluación inicia, se completa o vence.';

  @override
  String get weeklyDigest => 'Resumen semanal';

  @override
  String get weeklyDigestDescription =>
      'Métricas y actividad del proceso cada lunes.';

  @override
  String get securityTitle => 'Seguridad y acceso';

  @override
  String get securityDescription =>
      'Protege el acceso de tu equipo a la plataforma.';

  @override
  String get twoFactorAuth => 'Autenticación de dos factores';

  @override
  String get twoFactorDescription =>
      'Solicita un segundo factor a los administradores.';

  @override
  String get sessionTimeout => 'Tiempo de sesión';

  @override
  String get manageMembers => 'Administrar miembros';

  @override
  String get technologyIndustry => 'Tecnología';

  @override
  String get employeesRange => '51–200 empleados';

  @override
  String get minutes30 => '30 minutos';

  @override
  String get adminCommandCenter => 'Centro de mando';

  @override
  String get adminCommandSubtitle =>
      'Una lectura ejecutiva de TaleX: operación, clientes y crecimiento.';

  @override
  String get adminCompanies => 'Empresas';

  @override
  String get adminProcesses => 'Procesos';

  @override
  String get adminPeople => 'Personas';

  @override
  String get adminAffinity => 'Afinidad';

  @override
  String get adminCommercial => 'Comercial';

  @override
  String get adminSales => 'Ventas';

  @override
  String get adminCultureLeads => 'Leads cultura';

  @override
  String get adminCultureLeadsSubtitle =>
      'Prospectos del diagnóstico de la landing /micultura. No se crea empresa ni membresía.';

  @override
  String get adminCultureLeadsEmpty => 'Todavía no hay leads de cultura.';

  @override
  String get cultureLeadEmployees => 'Empleados';

  @override
  String get cultureLeadTraits => 'Rasgos culturales';

  @override
  String get cultureLeadComment => 'Comentario';

  @override
  String get cultureLeadUtm => 'UTM';

  @override
  String get cultureLeadStatusNew => 'Nuevo';

  @override
  String get cultureLeadStatusContacted => 'Contactado';

  @override
  String get cultureLeadStatusQualified => 'Calificado';

  @override
  String get cultureLeadStatusDiscarded => 'Descartado';

  @override
  String get adminAnalytics => 'Analytics';

  @override
  String get adminAlerts => 'Alertas';

  @override
  String get adminXebec => 'Xebec';

  @override
  String get adminSettings => 'Configuración';

  @override
  String get adminSearchHint => 'Buscar empresas, procesos o personas...';

  @override
  String get kpiTotalCompanies => 'Empresas totales';

  @override
  String get kpiActiveCompanies => 'Empresas activas';

  @override
  String get kpiEvaluatedPeople => 'Personas evaluadas';

  @override
  String get kpiCompletedEvaluations => 'Evaluaciones completadas';

  @override
  String get kpiAffinities => 'Afinidades detectadas';

  @override
  String get kpiPeriodSales => 'Ventas del periodo';

  @override
  String get kpiMrr => 'MRR';

  @override
  String get kpiAtRisk => 'Empresas en riesgo';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get noActivity => 'Aún no hay actividad registrada.';

  @override
  String get talexFunnel => 'Embudo TaleX';

  @override
  String get funnelCompanies => 'Empresas';

  @override
  String get funnelProcesses => 'Procesos';

  @override
  String get funnelInvited => 'Personas invitadas';

  @override
  String get funnelStarted => 'Evaluaciones iniciadas';

  @override
  String get funnelCompleted => 'Evaluaciones completadas';

  @override
  String get funnelAffinities => 'Afinidades detectadas';

  @override
  String get funnelDecisions => 'Resultados / decisiones';

  @override
  String get noData => 'Sin datos';

  @override
  String get noInformationYet => 'Aún no hay información.';

  @override
  String get retry => 'Reintentar';

  @override
  String get splashVerifyingSession => 'Verificando tu sesión';

  @override
  String get splashSigningIn => 'Iniciando sesión';

  @override
  String get splashLoadingSettings => 'Cargando tus configuraciones';

  @override
  String get splashPreparingWorkspace => 'Preparando tu espacio de trabajo';

  @override
  String get splashSigningOut => 'Cerrando sesión de forma segura';

  @override
  String get splashValidatingInvite => 'Validando tu invitación';

  @override
  String get splashPreparingAssessment => 'Preparando tu evaluación';

  @override
  String get newCompany => 'Nueva empresa';

  @override
  String get newProcess => 'Nuevo proceso';

  @override
  String get newPerson => 'Registrar persona';

  @override
  String get newDeal => 'Nueva oportunidad';

  @override
  String get newSale => 'Registrar venta';

  @override
  String get companyStatusActive => 'Activa';

  @override
  String get companyStatusOnboarding => 'En onboarding';

  @override
  String get companyStatusInactive => 'Inactiva';

  @override
  String get companyStatusAtRisk => 'En riesgo';

  @override
  String get companyStatusSuspended => 'Suspendida';

  @override
  String get processStatusActive => 'Activo';

  @override
  String get processStatusClosed => 'Cerrado';

  @override
  String get evaluationInvited => 'Invitada';

  @override
  String get evaluationStarted => 'Iniciada';

  @override
  String get evaluationInProgress => 'En progreso';

  @override
  String get evaluationCompleted => 'Completada';

  @override
  String get evaluationAbandoned => 'Abandonada';

  @override
  String get affinityHigh => 'Afinidad alta';

  @override
  String get affinityMedium => 'Afinidad media';

  @override
  String get affinityLow => 'Afinidad baja';

  @override
  String get affinityUnknown => 'Sin clasificar';

  @override
  String get dealProspect => 'Prospecto';

  @override
  String get dealContacted => 'Contactado';

  @override
  String get dealMeeting => 'Reunión';

  @override
  String get dealProposal => 'Propuesta';

  @override
  String get dealNegotiation => 'Negociación';

  @override
  String get dealClient => 'Cliente';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterArchived => 'Archivadas';

  @override
  String get companyActions => 'Acciones de la empresa';

  @override
  String get disableCompany => 'Inhabilitar';

  @override
  String get enableCompany => 'Reactivar';

  @override
  String get archiveCompany => 'Quitar de la vista';

  @override
  String get restoreCompany => 'Restaurar a la vista';

  @override
  String get disableCompanyTitle => 'Inhabilitar empresa';

  @override
  String get disableCompanyBody =>
      'La empresa dejará de operar en TaleX. Los datos se conservan. ¿Confirmas?';

  @override
  String get enableCompanyTitle => 'Reactivar empresa';

  @override
  String get enableCompanyBody =>
      'La empresa volverá a estar activa y su equipo podrá entrar. ¿Confirmas?';

  @override
  String get archiveCompanyTitle => 'Quitar de la vista';

  @override
  String get archiveCompanyBody =>
      'No se borra nada. La empresa deja de verse en el listado principal y queda en Archivadas. ¿Confirmas?';

  @override
  String get restoreCompanyTitle => 'Restaurar empresa';

  @override
  String get restoreCompanyBody =>
      'La empresa volverá a aparecer en el listado. ¿Confirmas?';

  @override
  String get confirmAction => 'Confirmar';

  @override
  String get noArchivedCompanies => 'No hay empresas archivadas.';

  @override
  String get errorCompanyDisabled =>
      'Esta empresa está inhabilitada. Un SuperAdmin puede reactivarla.';

  @override
  String get lastActivity => 'Última actividad';

  @override
  String get joinedAt => 'Incorporación';

  @override
  String get openDetail => 'Abrir detalle';

  @override
  String get backToCompanies => 'Volver a empresas';

  @override
  String get backToPeople => 'Volver a personas';

  @override
  String get backToProcesses => 'Volver a procesos';

  @override
  String get presentedPeople => 'Ya presentaron';

  @override
  String get pendingPeople => 'Pendientes';

  @override
  String get visitWebsite => 'Visitar sitio web';

  @override
  String get editCompany => 'Editar empresa';

  @override
  String get companyOverview => 'Resumen';

  @override
  String get companyCommercial => 'Comercial';

  @override
  String get companyMetrics => 'Utilización';

  @override
  String get noCompanies => 'Todavía no hay empresas en TaleX.';

  @override
  String get noProcesses => 'No hay procesos para mostrar.';

  @override
  String get noPeople =>
      'No hay personas evaluadas para mostrar. No se exponen respuestas sensibles.';

  @override
  String get noDeals => 'No hay oportunidades comerciales.';

  @override
  String get noSales => 'No hay ventas registradas en este periodo.';

  @override
  String get noAlerts => 'No hay alertas calculadas con los datos actuales.';

  @override
  String get period7 => '7 días';

  @override
  String get period30 => '30 días';

  @override
  String get period90 => '90 días';

  @override
  String get period12m => '12 meses';

  @override
  String get completionRate => 'Tasa de finalización';

  @override
  String get suggestedAction => 'Acción sugerida';

  @override
  String get xebecSubtitle =>
      'Xebec responde con el contexto real del centro de mando.';

  @override
  String get xebecPlaceholder => '¿Cómo está TaleX?';

  @override
  String get xebecEmpty =>
      'Pregunta por el estado de TaleX, empresas en riesgo u oportunidades. Xebec usa métricas reales, no suposiciones.';

  @override
  String get askXebec => 'Preguntar';

  @override
  String get adminSettingsSubtitle =>
      'Usuarios, roles y parámetros reales del sistema. Nada ficticio.';

  @override
  String get superAdminHelp =>
      'El SuperAdmin se eleva si su correo está en config/superadmin.emails o si el documento de usuario ya tiene role=superadmin. Las credenciales viven en Firebase Auth; cámbialas con recuperación de contraseña o la consola.';

  @override
  String get adminUsers => 'Usuarios';

  @override
  String get roleLabel => 'Rol';

  @override
  String get adminSaved => 'Los cambios se guardaron en TaleX.';

  @override
  String get amount => 'Importe';

  @override
  String get plan => 'Plan';

  @override
  String get owner => 'Responsable';

  @override
  String get nextAction => 'Próxima acción';

  @override
  String get product => 'Producto o servicio';

  @override
  String get recurring => 'Recurrente (MRR)';

  @override
  String get estimatedValue => 'Valor estimado';

  @override
  String get affinityScore => 'Puntaje de afinidad (0-100)';

  @override
  String get statusLabel => 'Estado';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityLow => 'Baja';

  @override
  String get alertRisk => 'Riesgo';

  @override
  String get alertOperational => 'Operacional';

  @override
  String get alertCommercial => 'Comercial';

  @override
  String get alertProduct => 'Producto';

  @override
  String get alertOpportunity => 'Oportunidad';

  @override
  String get salesPeriod => 'Ventas del periodo';

  @override
  String get salesCumulative => 'Ventas acumuladas';

  @override
  String get newCustomers => 'Clientes en el periodo';

  @override
  String get averageTicket => 'Ticket promedio';

  @override
  String get growth => 'Crecimiento vs periodo anterior';

  @override
  String get activityByDay => 'Actividad por día';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription =>
      'Elige el idioma de la interfaz. El cambio se aplica de inmediato.';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get vacancy => 'Vacante';

  @override
  String get createVacancy => 'Crear vacante';

  @override
  String get createRespondent => 'Crear encuestado';

  @override
  String get activationPin => 'PIN de activación';

  @override
  String pinGenerated(String pin) {
    return 'Empresa creada. PIN de primer acceso: $pin.';
  }

  @override
  String invitePinReady(String pin) {
    return 'PIN de primer acceso: $pin.';
  }

  @override
  String get nit => 'NIT';

  @override
  String get sector => 'Sector';

  @override
  String get city => 'Ciudad';

  @override
  String get website => 'Sitio web';

  @override
  String get logoUrl => 'URL del logo';

  @override
  String get description => 'Descripción';

  @override
  String get companyDna => 'ADN de la empresa';

  @override
  String get companyValues => 'Valores';

  @override
  String get companyCulture => 'Cultura';

  @override
  String get standoutPeople => '¿Qué destaca del personal?';

  @override
  String get skipCompanyDna =>
      'Omitir el ADN de la empresa por ahora. La organización podrá completarlo después.';

  @override
  String get country => 'País';

  @override
  String get department => 'Departamento';

  @override
  String get divisionState => 'Estado';

  @override
  String get divisionCommunity => 'Comunidad autónoma';

  @override
  String get divisionRegion => 'Estado / departamento / región';

  @override
  String get cityMunicipality => 'Ciudad / municipio';

  @override
  String get searchLocation => 'Escribe para buscar...';

  @override
  String get searchCountry => 'Buscar país...';

  @override
  String get searchDivision => 'Buscar división...';

  @override
  String get searchCity => 'Buscar ciudad...';

  @override
  String get locationLoadError =>
      'No pudimos cargar las ubicaciones. Intenta nuevamente.';

  @override
  String get locationNoResults => 'No hay resultados para esa búsqueda.';

  @override
  String get locationSelectCountryFirst => 'Primero elige un país';

  @override
  String get provisionStepCompany => 'Empresa';

  @override
  String get provisionStepDna => 'ADN';

  @override
  String get provisionStepInvite => 'Invitación';

  @override
  String get pasteLogoUrl => 'Pegar URL del logo';

  @override
  String get selectLogoFile => 'Seleccionar archivo';

  @override
  String get logoPreview => 'Vista previa del logo';

  @override
  String get sectorFinance => 'Financiero';

  @override
  String get sectorHealth => 'Salud';

  @override
  String get sectorEducation => 'Educación';

  @override
  String get sectorManufacturing => 'Manufactura';

  @override
  String get sectorRetail => 'Comercio';

  @override
  String get sectorServices => 'Servicios';

  @override
  String get sectorConstruction => 'Construcción';

  @override
  String get sectorEnergy => 'Energía';

  @override
  String get sectorAgribusiness => 'Agroindustria';

  @override
  String get sectorGovernment => 'Gobierno';

  @override
  String get sectorOther => 'Otro';

  @override
  String get size1to10 => '1–10 empleados';

  @override
  String get size11to50 => '11–50 empleados';

  @override
  String get size201to500 => '201–500 empleados';

  @override
  String get size500plus => 'Más de 500 empleados';

  @override
  String get emailSent => 'El correo de invitación se envió correctamente.';

  @override
  String get errorEmailNotConfigured =>
      'La empresa se creó, pero falta configurar SMTP para enviar correos. El PIN quedó en pantalla.';

  @override
  String get errorEmailSendFailed =>
      'La empresa se creó, pero el correo no se pudo enviar. Revisa spam o la configuración SMTP. El PIN quedó en pantalla.';

  @override
  String get completeCompanyDnaTitle => 'Completa el ADN de la empresa';

  @override
  String get completeCompanyDnaSubtitle =>
      'Antes de entrar al espacio, registra los valores, la cultura y lo que destaca del personal.';

  @override
  String get reviewCompanyDnaTitle => 'Verifica el ADN de la empresa';

  @override
  String get reviewCompanyDnaSubtitle =>
      'Revisa que estos datos describan bien a la organización. Si algo no cuadra, corrígelo antes de continuar.';

  @override
  String get confirmCompanyDna => 'Confirmar y continuar';

  @override
  String get dnaRequired =>
      'Completa valores, cultura y lo que destaca del personal.';

  @override
  String get soughtCharacteristics => 'Características buscadas';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get activateAccount => 'Activar cuenta';

  @override
  String get activateSubtitle =>
      'Usa el correo invitado y el PIN de 6 dígitos que llegó a esa bandeja. El PIN caduca a los 15 minutos.';

  @override
  String get activatePinHint =>
      '6 dígitos · válido 15 minutos. Usa el PIN del correo más reciente, no uno de una prueba anterior.';

  @override
  String get mustChangePasswordTitle => 'Crea tu contraseña';

  @override
  String get mustChangePasswordSubtitle =>
      'Esta contraseña es la que usarás de ahora en adelante para entrar a TaleX.';

  @override
  String get createPassword => 'Nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get documentNumber => 'Número de documento';

  @override
  String get activeVacancies => 'Vacantes activas';

  @override
  String get closedVacancies => 'Vacantes cerradas';

  @override
  String get pendingAssessments => 'Evaluaciones pendientes';

  @override
  String get completedAssessments => 'Evaluaciones completadas';

  @override
  String get noVacancies => 'Todavía no tienes vacantes creadas.';

  @override
  String get noCandidates => 'Todavía no hay encuestados en este proceso.';

  @override
  String get noTeamMembers => 'Todavía no hay personas en el equipo.';

  @override
  String get affinityWithCompany => 'Afinidad con la empresa';

  @override
  String get affinityWithVacancy => 'Afinidad con la vacante';

  @override
  String get likertStronglyDisagree => 'Muy en desacuerdo';

  @override
  String get likertDisagree => 'En desacuerdo';

  @override
  String get likertNeutral => 'Ni de acuerdo ni en desacuerdo';

  @override
  String get likertAgree => 'De acuerdo';

  @override
  String get likertStronglyAgree => 'Muy de acuerdo';

  @override
  String questionProgress(int current, int total) {
    return 'Pregunta $current de $total';
  }

  @override
  String get next => 'Siguiente';

  @override
  String get goBack => 'Anterior';

  @override
  String get finish => 'Finalizar';

  @override
  String get basicResult => 'Resultado básico';

  @override
  String get fullResultLocked =>
      'El resultado completo estará disponible cuando se habilite el acceso.';

  @override
  String get compare => 'Comparar';

  @override
  String get characteristic => 'Característica';

  @override
  String get team => 'Equipo';

  @override
  String get inviteRecruiter => 'Invitar al equipo';

  @override
  String get inviteTeamSubtitle =>
      'La persona recibirá un PIN de 6 dígitos al correo. Caduca a los 15 minutos.';

  @override
  String get teamRole => 'Rol en la empresa';

  @override
  String get teamRoleCompanyAdmin => 'CEO';

  @override
  String get teamRoleCompanyLead => 'Administrador';

  @override
  String get teamRolePeopleOps => 'Recursos humanos';

  @override
  String get teamRoleRecruiter => 'Reclutamiento';

  @override
  String get teamRoleHiringManager => 'Líder técnico';

  @override
  String get teamRoleHint =>
      'CEO y administrador pueden invitar al resto del equipo. Recursos humanos, reclutamiento y líder técnico trabajan vacantes y candidatos.';

  @override
  String get vacanciesSubtitle =>
      'Crea y da contexto a las vacantes de tu proceso. La ubicación de la vacante no cambia el perfil de la empresa.';

  @override
  String get teamSubtitle => 'Personas con acceso a TaleX en tu empresa.';

  @override
  String get workModeOnsite => 'Presencial';

  @override
  String get workModeRemote => 'Virtual';

  @override
  String get workModeHybrid => 'Híbrida';

  @override
  String get workModeHint =>
      'Si es virtual, la ciudad es opcional. Si es presencial o híbrida, usa la ubicación de la empresa y ajústala solo para esta vacante.';

  @override
  String get vacancyCityOptional => 'Ciudad de referencia (opcional)';

  @override
  String get seniorityHint =>
      'Indica la experiencia esperada para el rol. No entra en el cálculo de afinidad.';

  @override
  String get seniorityJunior => 'Inicial';

  @override
  String get seniorityMid => 'Intermedio';

  @override
  String get senioritySenior => 'Con experiencia';

  @override
  String get seniorityLead => 'Liderazgo';

  @override
  String get contractIndefinite => 'Indefinido';

  @override
  String get contractFixed => 'Término fijo';

  @override
  String get contractServices => 'Prestación de servicios';

  @override
  String get contractInternship => 'Práctica o pasantía';

  @override
  String get contractTemporary => 'Temporal';

  @override
  String get areaPeople => 'Personas y cultura';

  @override
  String get areaFinanceOps => 'Finanzas';

  @override
  String get areaOperations => 'Operaciones';

  @override
  String get areaCommercial => 'Comercial';

  @override
  String get areaCustomer => 'Atención a clientes';

  @override
  String get areaAdmin => 'Administración';

  @override
  String get areaEngineering => 'Ingeniería y desarrollo';

  @override
  String get areaProduct => 'Producto';

  @override
  String get areaData => 'Datos y analítica';

  @override
  String get areaSupport => 'Soporte';

  @override
  String get areaRisk => 'Riesgo y cumplimiento';

  @override
  String get areaAccounting => 'Contabilidad';

  @override
  String get areaClinical => 'Clínica';

  @override
  String get areaCare => 'Cuidado y atención';

  @override
  String get areaAcademic => 'Académica';

  @override
  String get areaTraining => 'Formación';

  @override
  String get areaProduction => 'Producción';

  @override
  String get areaQuality => 'Calidad';

  @override
  String get areaMaintenance => 'Mantenimiento';

  @override
  String get areaStore => 'Punto de venta';

  @override
  String get areaLogistics => 'Logística';

  @override
  String get areaProjects => 'Proyectos';

  @override
  String get areaField => 'Campo u obra';

  @override
  String get areaPublicService => 'Servicio público';

  @override
  String get vacancyAreaHint =>
      'Las áreas cambian según el sector de la empresa. Elige la más cercana al rol.';

  @override
  String get invitationUsed => 'Activada';

  @override
  String get invitationPending => 'Invitación pendiente';

  @override
  String get statusInReview => 'En revisión';

  @override
  String get statusShortlisted => 'Preseleccionado';

  @override
  String get statusInterview => 'Entrevista';

  @override
  String get statusFinalist => 'Finalista';

  @override
  String get statusHired => 'Contratado';

  @override
  String get statusRejected => 'No seleccionado';

  @override
  String get vacancyName => 'Nombre de la vacante';

  @override
  String get vacancyArea => 'Área';

  @override
  String get workMode => 'Modalidad';

  @override
  String get contractType => 'Tipo de contrato';

  @override
  String get seniority => 'Nivel';

  @override
  String get roleProfile => 'Perfil buscado';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get companyProfile => 'Perfil de empresa';

  @override
  String get vacancyInsights => 'Lectura de la vacante';

  @override
  String get vacancyInsightsEmpty =>
      'Aún no hay suficiente información para mostrar una lectura de esta vacante.';

  @override
  String vacancyInsightsCounts(int invited, int started, int completed) {
    return '$invited invitados · $started en curso · $completed completaron la evaluación.';
  }

  @override
  String get dnaSelectSeveral =>
      'Puedes elegir varias opciones. Si agregas una que no estaba en la lista, también puedes quitarla.';

  @override
  String get removeCustomOption => 'Eliminar esta opción';

  @override
  String get results => 'Resultados';

  @override
  String get resultsSubtitle =>
      'Lectura de afinidad de las personas que ya se presentaron. Aquí verás el detalle cuando la metodología complete la ficha.';

  @override
  String get compareHint =>
      'El recuadro a la izquierda sirve para elegir dos o más personas y usar Comparar. No cambia el estado del proceso.';

  @override
  String get affinityCompany => 'Empresa';

  @override
  String get affinityVacancy => 'Vacante';

  @override
  String get affinityUnknownHint =>
      'Todavía no hay evaluación completa, por eso la afinidad no está clasificada.';

  @override
  String get affinityMockNote =>
      'Análisis generado con IA a partir de la encuesta, que es la misma para todas las empresas. Es información de apoyo: TaleX no toma decisiones de contratación ni descarta personas. La decisión final corresponde a tu equipo.';

  @override
  String get affinityAnalysisNone =>
      'Esta evaluación todavía no tiene análisis de afinidad.';

  @override
  String get affinityAnalysisPending =>
      'Estamos analizando las respuestas de la encuesta. Puede tardar unos segundos.';

  @override
  String get affinityAnalysisFailed =>
      'No pudimos completar el análisis de afinidad en este momento. Puedes intentarlo de nuevo.';

  @override
  String get affinityAnalysisMissingDna =>
      'Todavía no hay información suficiente de la encuesta para completar el análisis.';

  @override
  String get affinityAnalysisIncompleteAnswers =>
      'La evaluación no tiene suficientes respuestas para analizar la afinidad.';

  @override
  String get affinityAnalyzeAction => 'Analizar afinidad';

  @override
  String get affinityReanalyzeAction => 'Volver a analizar';

  @override
  String get affinityAlignmentsTitle => 'Dónde hay afinidad';

  @override
  String get affinityDifferencesTitle =>
      'Aspectos que podrían generar dificultades';

  @override
  String get affinityTopicsTitle => 'Temas para conversar en la entrevista';

  @override
  String get affinityGuidanceTitle => 'Orientación para Recursos Humanos';

  @override
  String get affinityDataGapsTitle => 'Información que faltó';

  @override
  String affinityScoreValue(int score) {
    return 'Puntaje $score/100';
  }

  @override
  String get continueAction => 'Continuar';

  @override
  String get respondentWelcomeTitle => 'Quiero conocerte bien';

  @override
  String get respondentWelcomeBody =>
      'Hola. Soy TaleXito. Esta encuesta es la misma para todas las empresas. Yo recibo tus respuestas para conocer mejor cómo te gusta trabajar. El resultado no lo determino yo: una persona especializada te lo contará más adelante.';

  @override
  String get respondentWelcomeAction => 'Listo';

  @override
  String respondentHello(String name) {
    return 'Hola, $name';
  }

  @override
  String get respondentHomeTitle => 'Tu evaluación de afinidad';

  @override
  String get respondentHomeSubtitle =>
      'TaleX no decide si te contratan. Mide qué tan cerca estás del perfil que la empresa describió para esta vacante.';

  @override
  String get respondentDuration =>
      'Reserva unos 40 minutos en un lugar tranquilo. Puedes avanzar con calma.';

  @override
  String get respondentLikertHint =>
      'En la mayoría de preguntas verás dos frases, una a cada lado. Elige el recuadro que quede más cerca de la que mejor te describe. No hay respuestas correctas o incorrectas.';

  @override
  String get startAssessment => 'Iniciar evaluación';

  @override
  String get assignedVacancy => 'Vacante asignada';

  @override
  String get viewFullSummary => 'Ver resumen orientativo';

  @override
  String get hideFullSummary => 'Ocultar resumen';

  @override
  String get fullSummaryTitle => 'Resumen orientativo';

  @override
  String get fullSummaryIntro =>
      'Esta vista es una maqueta de cómo se verá la lectura. Las dimensiones de abajo son de ejemplo hasta que TaleX entregue el detalle real.';

  @override
  String get dimensionCommunication => 'Comunicación';

  @override
  String get dimensionAdaptability => 'Adaptabilidad';

  @override
  String get dimensionCollaboration => 'Colaboración';

  @override
  String get dimensionInitiative => 'Iniciativa';

  @override
  String get veryHigh => 'Muy alta';

  @override
  String get resultThanks =>
      'Gracias por completar la evaluación. La empresa podrá ver tu afinidad con su cultura y con esta vacante.';

  @override
  String get newAssessment => 'Nueva evaluación';

  @override
  String get pendingAssessmentNotification =>
      'Tienes una evaluación pendiente.';

  @override
  String get assessmentCompletedNotification => 'La evaluación fue completada.';

  @override
  String get newVacancyNotification => 'Se creó una nueva vacante.';

  @override
  String get newActivityNotification => 'Hay nueva actividad en TaleX.';

  @override
  String get errorNeedSignIn => 'Necesitas iniciar sesión.';

  @override
  String get errorNeedAuthEmail => 'Necesitas un correo autenticado.';

  @override
  String get errorPermissionDenied => 'No tienes permiso para esta operación.';

  @override
  String get errorUnexpected =>
      'No se pudo completar la operación. Inténtalo nuevamente.';

  @override
  String get errorApiUnavailable =>
      'No se pudo conectar con TaleX. No puedes entrar hasta que la API responda.';

  @override
  String get errorCompanyNotFound => 'No se encontró la empresa.';

  @override
  String get errorRespondentExists =>
      'Ya existe un encuestado con este correo en la vacante.';

  @override
  String get errorInviteMissing => 'No hay una invitación para este correo.';

  @override
  String get errorInviteUsed => 'Esta invitación ya fue utilizada.';

  @override
  String get errorInviteInvalid => 'El enlace de invitación no es válido.';

  @override
  String get errorInviteExpired =>
      'El enlace caducó. Pide una invitación nueva.';

  @override
  String get errorInvalidPin => 'El PIN no es válido.';

  @override
  String get errorPinExpired =>
      'El PIN caducó. Pide una invitación nueva; dura 15 minutos.';

  @override
  String get errorDocumentMismatch =>
      'El documento no coincide con la invitación.';

  @override
  String get errorAssessmentMissing => 'No hay una evaluación asignada.';

  @override
  String get errorDocumentPasswordTooShort =>
      'El número de documento debe tener al menos 6 caracteres para usarse como contraseña.';

  @override
  String get registerPinHint => 'PIN de 6 dígitos que llegó al correo';

  @override
  String get googlePinTitle => 'Ingresa el PIN del correo';

  @override
  String get googlePinSubtitle =>
      'Tu cuenta de Google ya está lista. Confirma el PIN de 6 dígitos para vincular la invitación.';

  @override
  String addCustomOption(String value) {
    return 'Agregar \"$value\"';
  }

  @override
  String get searchOrAdd => 'Escribe para buscar o agregar...';

  @override
  String get customAreaLabel => 'Nombre del área';

  @override
  String get areaOther => 'Otra';

  @override
  String get dnaValueIntegrity => 'Integridad';

  @override
  String get dnaValueRespect => 'Respeto';

  @override
  String get dnaValueCollaboration => 'Colaboración';

  @override
  String get dnaValueInnovation => 'Innovación';

  @override
  String get dnaValueExcellence => 'Excelencia';

  @override
  String get dnaValueEmpathy => 'Empatía';

  @override
  String get dnaCultureClose => 'Cercana y humana';

  @override
  String get dnaCultureFormal => 'Formal y estructurada';

  @override
  String get dnaCultureLearning => 'Aprendizaje continuo';

  @override
  String get dnaCultureAgile => 'Ágil';

  @override
  String get dnaCultureAutonomous => 'Autónoma';

  @override
  String get dnaStandoutOwnership => 'Sentido de dueño';

  @override
  String get dnaStandoutCommunication => 'Comunicación clara';

  @override
  String get dnaStandoutAdaptability => 'Adaptabilidad';

  @override
  String get dnaStandoutInitiative => 'Iniciativa';

  @override
  String get dnaStandoutTeamwork => 'Trabajo en equipo';

  @override
  String get assessmentKindLabel => 'Esta es tu evaluación';

  @override
  String get assessmentKindAffinity => 'Afinidad';

  @override
  String get assessmentKindFit => 'Fit';

  @override
  String get sentByCompany => 'Te la envió';

  @override
  String respondentQuestionCount(int count) {
    return 'En total son $count preguntas.';
  }

  @override
  String get assessmentFinishedTitle => 'TaleXito ya recibió tus respuestas';

  @override
  String get assessmentFinishedBody =>
      'TaleXito se encarga de recibir la información. No determina el resultado. Una persona especializada te lo dirá más adelante.';

  @override
  String get surveyResultRequest => 'Quiero conocer mis resultados';

  @override
  String get surveyResultRequested =>
      'Gracias por hacernos saber eso. El resultado se demora un poco. Una persona especializada se encarga de eso.';

  @override
  String get companyProfileSubtitle => 'Datos generales de la empresa.';

  @override
  String get downloadPdf => 'Descargar informe PDF';

  @override
  String get candidateResultTitle => 'Informe de resultados';

  @override
  String get editCandidate => 'Editar candidato';

  @override
  String get deleteCandidate => 'Eliminar candidato';

  @override
  String deleteCandidateConfirm(String name) {
    return '¿Eliminar a $name? Se borrarán sus respuestas y su enlace de invitación dejará de funcionar. Esta acción no se puede deshacer.';
  }

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get candidateUpdated => 'Candidato actualizado.';

  @override
  String get candidateDeleted => 'Candidato eliminado.';

  @override
  String get backToResults => 'Volver';

  @override
  String get candidatesSubtitle =>
      'Personas invitadas a evaluar afinidad con tus vacantes.';

  @override
  String get candidateProcessStatus => 'Estado del proceso';

  @override
  String get respondentInviteHint =>
      'La persona recibirá un correo con un enlace para presentar la prueba de inmediato. Cuando la complete, verás el estado y el resultado aquí.';

  @override
  String get firstAccessCompany => 'Primer acceso';

  @override
  String get assessmentSignInHint =>
      'Si te invitaron a una evaluación, usa el enlace del correo para comenzar la prueba. No necesitas registrarte con un PIN.';

  @override
  String get respondentInviteSent =>
      'Invitación lista. El candidato recibe un enlace por correo para presentar la prueba.';

  @override
  String get recoverPasswordTitle => 'Recuperar acceso';

  @override
  String get recoverPasswordSubtitle =>
      'Escribe el correo de tu cuenta TaleX. Te enviaremos un PIN de 6 dígitos para continuar.';

  @override
  String get recoverContinue => 'Enviar PIN';

  @override
  String get recoverPinTitle => 'Revisa tu correo';

  @override
  String get recoverPinSubtitle =>
      'Te enviamos un PIN. Ingrésalo para actualizar tu contraseña.';

  @override
  String get recoverPinHint =>
      '6 dígitos · válido 15 minutos. Revisa también spam. Si no pediste este cambio, ignora el mensaje.';

  @override
  String get recoverPinSent => 'Enviamos un PIN a tu correo.';

  @override
  String get recoverVerifyPin => 'Verificar PIN';

  @override
  String get recoverResendPin => 'Reenviar PIN';

  @override
  String get recoverUpdatePassword => 'Actualizar contraseña';

  @override
  String get recoverSuccessTitle => 'Contraseña actualizada';

  @override
  String get recoverSuccessBody =>
      'Ya puedes iniciar sesión en TaleX con tu nueva contraseña.';

  @override
  String get errorResetCooldown => 'Espera un minuto antes de pedir otro PIN.';

  @override
  String get errorResetTooManyAttempts =>
      'Demasiados intentos. Espera un momento e inténtalo de nuevo.';

  @override
  String dashboardReadyToReview(int count) {
    return '$count evaluaciones listas para revisar';
  }

  @override
  String dashboardPendingToStart(int count) {
    return '$count personas aún no inician la evaluación';
  }

  @override
  String dashboardStalledAssessments(int count) {
    return '$count evaluaciones detenidas más de 24 h';
  }

  @override
  String get dashboardRecentEmpty =>
      'Todavía no hay actividad de encuestados en este espacio.';

  @override
  String get dashboardAlertsEmpty =>
      'No hay alertas pendientes en este momento.';

  @override
  String get errorAccountNotFound =>
      'No hay una cuenta TaleX con este correo. Si te invitaron, entra por Primer acceso con el PIN.';

  @override
  String get adminQuestions => 'Encuesta de afinidad';

  @override
  String get adminQuestionsSubtitle =>
      'Preguntas que responde el candidato. Puedes verlas, editarlas y actualizarlas.';

  @override
  String get adminCultureSurvey => 'Encuesta de cultura';

  @override
  String get adminCultureSurveySubtitle =>
      'Formulario de valores y cultura de la empresa. Sube el archivo una vez; después solo se edita.';

  @override
  String get adminCultureSurveyEmpty =>
      'Todavía no hay preguntas de cultura. Sube un archivo CSV o JSON para cargarlas.';

  @override
  String get adminSurveys => 'Encuestas';

  @override
  String get adminSurveysCultureVs => 'Cultura candidato vs empresa';

  @override
  String get adminSurveysMyCulture => 'Mi cultura';

  @override
  String get adminMyCultureSubtitle =>
      'Empresas que llegaron por la landing /micultura, con lo que respondieron sobre su cultura.';

  @override
  String get adminMyCultureRefresh => 'Actualizar';

  @override
  String get adminMyCultureError =>
      'No pudimos cargar los datos de Mi cultura.';

  @override
  String get adminMyCultureEmpty => 'Todavía no hay respuestas de Mi cultura.';

  @override
  String get adminMyCultureNoResults =>
      'Ninguna empresa coincide con la búsqueda.';

  @override
  String get adminMyCultureSearch => 'Buscar por empresa, contacto o correo...';

  @override
  String get adminMyCultureOrganizations => 'Empresas';

  @override
  String get adminMyCultureLeads => 'Leads';

  @override
  String get adminMyCultureResponded => 'Respondieron';

  @override
  String get adminMyCultureUnassigned => 'Sin empresa asignada';

  @override
  String get adminMyCultureLastLead => 'Último lead';

  @override
  String get adminMyCultureComments => 'Comentarios';

  @override
  String get adminMyCultureRespondedBadge => 'Respondió';

  @override
  String get adminMyCulturePending => 'Pendiente';

  @override
  String get adminMyCultureEmailSent => 'Correo enviado';

  @override
  String get adminMyCultureEmailSkipped => 'Correo omitido';

  @override
  String get adminMyCultureEmailFailed => 'Correo fallido';

  @override
  String adminMyCultureLeadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leads',
      one: '1 lead',
    );
    return '$_temp0';
  }

  @override
  String adminMyCultureRespondedCount(int responded, int total) {
    return '$responded de $total respondieron';
  }

  @override
  String get cultureQuestionsOpen => 'Preguntas';

  @override
  String get cultureSurveyPreview => 'Vista previa de la encuesta';

  @override
  String get cultureSurveyDemo => 'Ver demo de la encuesta';

  @override
  String get cultureSurveyDemoCopy => 'Copiar enlace demo';

  @override
  String get cultureSurveyDemoCopied =>
      'Enlace demo copiado. Al abrirlo no se envían respuestas.';

  @override
  String get cultureQuestionsTitle => 'Preguntas de Mi cultura';

  @override
  String get cultureQuestionsSubtitle =>
      'Banco de preguntas de la encuesta que responden los colaboradores de cada empresa.';

  @override
  String get cultureQuestionsBack => 'Volver a Mi cultura';

  @override
  String get cultureQuestionsNew => 'Nueva pregunta';

  @override
  String get cultureQuestionsEditSurvey => 'Título e intro';

  @override
  String get cultureQuestionsShowInactive => 'Mostrar desactivadas';

  @override
  String get cultureQuestionsSearch =>
      'Buscar por código, nombre, enunciado o sección...';

  @override
  String get cultureQuestionsEmpty => 'Todavía no hay preguntas de cultura.';

  @override
  String get cultureQuestionsNoResults =>
      'Ninguna pregunta coincide con la búsqueda.';

  @override
  String get cultureQuestionsInactive => 'Desactivada';

  @override
  String get cultureQuestionsRequiredBadge => 'Obligatoria';

  @override
  String get cultureQuestionsSurveyTitle => 'Título de la encuesta';

  @override
  String get cultureQuestionsSurveyIntro => 'Introducción';

  @override
  String get cultureQuestionsSurveyNoTitle => 'Sin título configurado';

  @override
  String get cultureQuestionsCode => 'Código';

  @override
  String get cultureQuestionsName => 'Nombre';

  @override
  String get cultureQuestionsStatement => 'Enunciado';

  @override
  String get cultureQuestionsInstruction => 'Instrucción';

  @override
  String get cultureQuestionsFormat => 'Formato';

  @override
  String get cultureQuestionsOptionsSource => 'Origen de opciones';

  @override
  String get cultureQuestionsSection => 'Sección (clave)';

  @override
  String get cultureQuestionsSectionTitle => 'Título de la sección';

  @override
  String get cultureQuestionsTechnique => 'Técnica';

  @override
  String get cultureQuestionsRequiredField => 'Obligatoria';

  @override
  String get cultureQuestionsActive => 'Activa';

  @override
  String get cultureQuestionsOptions => 'Opciones';

  @override
  String get cultureQuestionsOptionId => 'ID';

  @override
  String get cultureQuestionsOptionLabel => 'Texto';

  @override
  String get cultureQuestionsOptionDimension => 'Dimensión';

  @override
  String get cultureQuestionsAddOption => 'Agregar opción';

  @override
  String get cultureQuestionsRemoveOption => 'Quitar opción';

  @override
  String get cultureQuestionsOptionIdTaken => 'ID repetido';

  @override
  String get cultureQuestionsUsed => 'Usados en el banco:';

  @override
  String cultureQuestionsDeleteBody(String code) {
    return '¿Eliminar la pregunta $code? Si solo quieres ocultarla, desactívala.';
  }

  @override
  String get cultureQuestionsErrorLoad =>
      'No pudimos cargar las preguntas de cultura.';

  @override
  String get cultureQuestionsErrorGeneric => 'No pudimos guardar el cambio.';

  @override
  String get cultureQuestionsErrorSignIn =>
      'Tu sesión venció. Vuelve a iniciar sesión.';

  @override
  String get cultureQuestionsErrorPermission =>
      'Solo el superadmin puede cambiar las preguntas.';

  @override
  String get cultureQuestionsErrorNotFound =>
      'Esa pregunta ya no existe. Recarga la lista.';

  @override
  String get cultureQuestionsErrorDuplicate =>
      'Ya existe una pregunta con ese código.';

  @override
  String cultureQuestionsErrorInvalid(String detail) {
    return 'Revisa la pregunta: $detail';
  }

  @override
  String get cultureQuestionsErrorInvalidGeneric =>
      'Falta un dato o hay uno inválido en la pregunta.';

  @override
  String get cultureQuestionsErrorCodesMismatch =>
      'El banco cambió mientras reordenabas. Recarga la lista e inténtalo de nuevo.';

  @override
  String get cultureQuestionsErrorNotDeployed =>
      'El servidor todavía no tiene las preguntas de cultura publicadas. Cuando el backend las suba, aparecerán aquí.';

  @override
  String get adminQuestionsUploadFile => 'Subir archivo';

  @override
  String get adminQuestionsFrontCultura => 'Cultura vivida';

  @override
  String get adminQuestionsFrontLiderazgo => 'Liderazgo';

  @override
  String get adminQuestionsFrontTrabajo => 'Forma de trabajar';

  @override
  String get adminQuestionsFrontPersonas => 'Personas';

  @override
  String get adminQuestionsFrontApertura => 'Comentarios abiertos';

  @override
  String get adminQuestionsFormatScale => 'Escala';

  @override
  String get adminQuestionsFormatText => 'Texto abierto';

  @override
  String get adminQuestionsFormatSingle => 'Opción única';

  @override
  String get adminQuestionsFormatMulti => 'Opción múltiple';

  @override
  String get adminQuestionsNew => 'Nueva pregunta';

  @override
  String get adminQuestionsEdit => 'Editar pregunta';

  @override
  String get adminQuestionsPreview => 'Vista previa';

  @override
  String get affinityDemoCompany => 'Empresa de ejemplo';

  @override
  String get affinityDemoCompanyDescription =>
      'Así se ve la descripción de la empresa que envía la evaluación.';

  @override
  String get affinityDemoVacancy => 'Vacante de ejemplo';

  @override
  String get affinityDemoCandidate => 'Ana Demo';

  @override
  String get adminQuestionsDemo => 'Ver demo';

  @override
  String get adminQuestionsPreviewTitle => 'Vista previa de la encuesta';

  @override
  String get adminQuestionsPreviewNote =>
      'Simulación: las respuestas no se guardan.';

  @override
  String get adminQuestionsPreviewEmpty =>
      'No hay preguntas activas para mostrar.';

  @override
  String get adminQuestionsEmpty => 'Todavía no hay preguntas en Firebase.';

  @override
  String adminQuestionsSeed(int count) {
    return 'Cargar las $count preguntas base';
  }

  @override
  String get adminQuestionsNoResults =>
      'Ninguna pregunta coincide con el filtro.';

  @override
  String get adminQuestionsSearch =>
      'Buscar por código, dimensión o enunciado...';

  @override
  String get adminQuestionsAll => 'Todas';

  @override
  String adminQuestionsSummary(int active, int total) {
    return '$active activas de $total';
  }

  @override
  String get adminQuestionsFrontValues => '1 · Valores';

  @override
  String get adminQuestionsFrontNeeds => '2 · Necesidades';

  @override
  String get adminQuestionsFrontCapabilities => '3 · Capacidades';

  @override
  String get adminQuestionsFormatPair => 'Par de enunciados';

  @override
  String get adminQuestionsFormatExperience => 'Enunciado de experiencia';

  @override
  String get adminQuestionsCode => 'Código';

  @override
  String get adminQuestionsFront => 'Frente';

  @override
  String get adminQuestionsFormat => 'Formato';

  @override
  String get adminQuestionsDimension => 'Dimensión';

  @override
  String get adminQuestionsDimensionA => 'Dimensión A';

  @override
  String get adminQuestionsDimensionB => 'Dimensión B';

  @override
  String get adminQuestionsInstruction => 'Instrucción';

  @override
  String get adminQuestionsStatement => 'Enunciado';

  @override
  String get adminQuestionsStatementA => 'Enunciado A';

  @override
  String get adminQuestionsStatementB => 'Enunciado B';

  @override
  String adminQuestionsOption(int number) {
    return 'Opción $number';
  }

  @override
  String get adminQuestionsTimeLimit => 'Tiempo límite (segundos)';

  @override
  String get adminQuestionsTimeLimitHint => 'Vacío = sin límite';

  @override
  String get adminQuestionsNoLimit => 'Sin límite';

  @override
  String adminQuestionsSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminQuestionsActive => 'Activa';

  @override
  String get adminQuestionsInactive => 'Inactiva';

  @override
  String get adminQuestionsRequired => 'Este campo es obligatorio.';

  @override
  String get adminQuestionsCodeTaken =>
      'Ya existe una pregunta con este código.';

  @override
  String get adminQuestionsInvalidTime =>
      'Escribe un número entero mayor que cero.';

  @override
  String get adminQuestionsDeleteTitle => 'Eliminar pregunta';

  @override
  String adminQuestionsDeleteBody(String code) {
    return 'Se eliminará $code de Firebase. Esta acción no se puede deshacer.';
  }

  @override
  String get adminQuestionsDelete => 'Eliminar';

  @override
  String get adminQuestionsMoveUp => 'Subir';

  @override
  String get adminQuestionsMoveDown => 'Bajar';

  @override
  String get adminQuestionsError =>
      'No se pudo completar la operación en Firebase.';

  @override
  String get adminQuestionsRestart => 'Reiniciar';

  @override
  String get adminQuestionsDeviceMobile => 'Móvil';

  @override
  String get adminQuestionsDeviceDesktop => 'Escritorio';

  @override
  String get adminQuestionsTimeUp => 'Tiempo agotado';

  @override
  String get assessmentPairInstruction =>
      '¿Cuál de las dos frases lo describe mejor a usted?';

  @override
  String get assessmentNeedInstruction =>
      'Si tuviera que elegir, ¿cuál de las dos es más importante para usted en un empleo?';

  @override
  String get assessmentExperienceInstruction =>
      'Pensando en sus trabajos o proyectos de los últimos tres años, ¿con qué frecuencia le ha ocurrido lo siguiente?';

  @override
  String get assessmentPairScaleHint =>
      'Toque la frase con la que más se identifica, o elija un punto de la escala.';

  @override
  String get assessmentStatementA => 'Frase A';

  @override
  String get assessmentStatementB => 'Frase B';

  @override
  String get pairScale1 => 'Claramente la A';

  @override
  String get pairScale2 => 'Más la A que la B';

  @override
  String get pairScale3 => 'Ambas por igual';

  @override
  String get pairScale4 => 'Más la B que la A';

  @override
  String get pairScale5 => 'Claramente la B';

  @override
  String get frequencyScale1 => 'Nunca';

  @override
  String get frequencyScale2 => 'Rara vez';

  @override
  String get frequencyScale3 => 'Algunas veces';

  @override
  String get frequencyScale4 => 'Con frecuencia';

  @override
  String get frequencyScale5 => 'Siempre';

  @override
  String get adminRoleSuperadmin => 'Superadmin';

  @override
  String get adminRoleSuperadminHelp => 'Acceso total al panel de TaleX.';

  @override
  String get adminRoleUser => 'Usuario';

  @override
  String get adminRoleUserHelp =>
      'Acceso estándar, sin panel de administración.';

  @override
  String get adminRoleChange => 'Cambiar rol';

  @override
  String get adminQuestionsImport => 'Importar CSV';

  @override
  String get adminQuestionsImportTitle => 'Importar preguntas';

  @override
  String adminQuestionsImportBody(int total, int created, int replaced) {
    return 'El archivo trae $total preguntas: $created nuevas y $replaced que reemplazan a las que ya existen con el mismo código.';
  }

  @override
  String get adminQuestionsImportAction => 'Importar';

  @override
  String get adminQuestionsCsvUnreadable =>
      'No se pudo leer el archivo. Debe ser un CSV.';

  @override
  String get adminQuestionsCsvEmpty => 'El archivo no tiene preguntas.';

  @override
  String adminQuestionsCsvMissingColumns(String columns) {
    return 'Faltan columnas obligatorias en el CSV: $columns.';
  }

  @override
  String adminQuestionsCsvInvalidRow(int row) {
    return 'Fila $row: falta el código o el enunciado A.';
  }

  @override
  String adminQuestionsCsvDuplicate(int row, String code) {
    return 'Fila $row: el código $code está repetido en el archivo.';
  }

  @override
  String get adminQuestionsDeleteAll => 'Eliminar todas';

  @override
  String get adminQuestionsDeleteAllTitle => 'Eliminar todas las preguntas';

  @override
  String adminQuestionsDeleteAllBody(int count) {
    return 'Se eliminarán las $count preguntas de Firebase. Esta acción no se puede deshacer.';
  }

  @override
  String get adminQuestionsUploading => 'Cargando preguntas…';

  @override
  String get adminQuestionsDeleting => 'Eliminando preguntas…';

  @override
  String adminQuestionsUploaded(int count) {
    return '$count preguntas cargadas en TaleX.';
  }

  @override
  String get adminQuestionsDeletedAll => 'Se eliminaron todas las preguntas.';
}
