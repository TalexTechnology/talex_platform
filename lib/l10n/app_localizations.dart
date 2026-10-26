import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'TaleX'**
  String get appName;

  /// No description provided for @secureSignIn.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión seguro'**
  String get secureSignIn;

  /// No description provided for @workEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get workEmail;

  /// No description provided for @emailAddress.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailAddress;

  /// No description provided for @emailAddressHint.
  ///
  /// In es, this message translates to:
  /// **'candidato@correo.com'**
  String get emailAddressHint;

  /// No description provided for @validEmailAddressError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido'**
  String get validEmailAddressError;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'correo@ejemplo.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @continueWith.
  ///
  /// In es, this message translates to:
  /// **'O continúa con'**
  String get continueWith;

  /// No description provided for @signInGoogle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Google'**
  String get signInGoogle;

  /// No description provided for @signUpGoogle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta con Google'**
  String get signUpGoogle;

  /// No description provided for @googleSignInError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Google. Inténtalo nuevamente.'**
  String get googleSignInError;

  /// No description provided for @newToTalex.
  ///
  /// In es, this message translates to:
  /// **'¿Nuevo en TaleX?'**
  String get newToTalex;

  /// No description provided for @createAccountLink.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccountLink;

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos del servicio'**
  String get termsOfService;

  /// No description provided for @validEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido'**
  String get validEmailError;

  /// No description provided for @passwordLengthError.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordLengthError;

  /// No description provided for @resetEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo para restablecer la contraseña.'**
  String get resetEmailSent;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta para comenzar en TaleX.'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In es, this message translates to:
  /// **'María Pérez'**
  String get fullNameHint;

  /// No description provided for @companyName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la empresa'**
  String get companyName;

  /// No description provided for @companyHint.
  ///
  /// In es, this message translates to:
  /// **'Empresa S.A.S.'**
  String get companyHint;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get alreadyHaveAccount;

  /// No description provided for @logIn.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get logIn;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get requiredField;

  /// No description provided for @testimonial.
  ///
  /// In es, this message translates to:
  /// **'“TaleX transformó nuestro proceso de selección y ayudó a nuestro equipo a tomar mejores decisiones.”'**
  String get testimonial;

  /// No description provided for @welcomeUser.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido, {name}'**
  String welcomeUser(String name);

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @dashboard.
  ///
  /// In es, this message translates to:
  /// **'Panel principal'**
  String get dashboard;

  /// No description provided for @roles.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones'**
  String get roles;

  /// No description provided for @candidates.
  ///
  /// In es, this message translates to:
  /// **'Personas habilitadas'**
  String get candidates;

  /// No description provided for @assessments.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones'**
  String get assessments;

  /// No description provided for @managers.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get managers;

  /// No description provided for @reports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @support.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get support;

  /// No description provided for @documentation.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get documentation;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar personas, invitaciones o evaluaciones...'**
  String get searchHint;

  /// No description provided for @overview.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get overview;

  /// No description provided for @overviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento general de las evaluaciones asignadas por tu equipo.'**
  String get overviewSubtitle;

  /// No description provided for @generateReport.
  ///
  /// In es, this message translates to:
  /// **'Generar reporte'**
  String get generateReport;

  /// No description provided for @newRole.
  ///
  /// In es, this message translates to:
  /// **'Habilitar persona'**
  String get newRole;

  /// No description provided for @activeRoles.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones enviadas'**
  String get activeRoles;

  /// No description provided for @evaluatedCandidates.
  ///
  /// In es, this message translates to:
  /// **'Pendientes de iniciar'**
  String get evaluatedCandidates;

  /// No description provided for @averageFitScore.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones en curso'**
  String get averageFitScore;

  /// No description provided for @hiringVelocity.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones completadas'**
  String get hiringVelocity;

  /// No description provided for @thisWeekChange.
  ///
  /// In es, this message translates to:
  /// **'+8 esta semana'**
  String get thisWeekChange;

  /// No description provided for @thisMonthChange.
  ///
  /// In es, this message translates to:
  /// **'5 vencen próximamente'**
  String get thisMonthChange;

  /// No description provided for @stableTopRoles.
  ///
  /// In es, this message translates to:
  /// **'Actividad en tiempo real'**
  String get stableTopRoles;

  /// No description provided for @daysFromQuarter.
  ///
  /// In es, this message translates to:
  /// **'+42 este mes'**
  String get daysFromQuarter;

  /// No description provided for @topMatches.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get topMatches;

  /// No description provided for @viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get viewAll;

  /// No description provided for @candidate.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get candidate;

  /// No description provided for @matchedRole.
  ///
  /// In es, this message translates to:
  /// **'Evaluación'**
  String get matchedRole;

  /// No description provided for @affinity.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get affinity;

  /// No description provided for @action.
  ///
  /// In es, this message translates to:
  /// **'Acción'**
  String get action;

  /// No description provided for @pendingActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones pendientes'**
  String get pendingActions;

  /// No description provided for @reviewRequirements.
  ///
  /// In es, this message translates to:
  /// **'Resultados listos para revisar'**
  String get reviewRequirements;

  /// No description provided for @finalApproval.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones próximas a vencer'**
  String get finalApproval;

  /// No description provided for @scheduleInterview.
  ///
  /// In es, this message translates to:
  /// **'Evaluación interrumpida'**
  String get scheduleInterview;

  /// No description provided for @statusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get statusCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get statusInProgress;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @logicalReasoningAssessment.
  ///
  /// In es, this message translates to:
  /// **'Razonamiento lógico'**
  String get logicalReasoningAssessment;

  /// No description provided for @decisionMakingAssessment.
  ///
  /// In es, this message translates to:
  /// **'Toma de decisiones'**
  String get decisionMakingAssessment;

  /// No description provided for @problemSolvingAssessment.
  ///
  /// In es, this message translates to:
  /// **'Resolución de problemas'**
  String get problemSolvingAssessment;

  /// No description provided for @completedToday.
  ///
  /// In es, this message translates to:
  /// **'Completada hoy'**
  String get completedToday;

  /// No description provided for @expiresTomorrow.
  ///
  /// In es, this message translates to:
  /// **'5 invitaciones vencen mañana'**
  String get expiresTomorrow;

  /// No description provided for @connectionInterrupted.
  ///
  /// In es, this message translates to:
  /// **'Requiere seguimiento del reclutador'**
  String get connectionInterrupted;

  /// No description provided for @invitationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones'**
  String get invitationsTitle;

  /// No description provided for @invitationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Habilita personas y realiza seguimiento a sus evaluaciones.'**
  String get invitationsSubtitle;

  /// No description provided for @enablePerson.
  ///
  /// In es, this message translates to:
  /// **'Habilitar persona'**
  String get enablePerson;

  /// No description provided for @enablePersonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Asigna una evaluación y envía una invitación de acceso.'**
  String get enablePersonSubtitle;

  /// No description provided for @personName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la persona'**
  String get personName;

  /// No description provided for @personNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre y apellido'**
  String get personNameHint;

  /// No description provided for @selectAssessment.
  ///
  /// In es, this message translates to:
  /// **'Evaluación asignada'**
  String get selectAssessment;

  /// No description provided for @invitationExpiry.
  ///
  /// In es, this message translates to:
  /// **'Vigencia de la invitación'**
  String get invitationExpiry;

  /// No description provided for @daysValue.
  ///
  /// In es, this message translates to:
  /// **'{count} días'**
  String daysValue(int count);

  /// No description provided for @optionalMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje opcional'**
  String get optionalMessage;

  /// No description provided for @optionalMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega instrucciones para la persona...'**
  String get optionalMessageHint;

  /// No description provided for @sendInvitation.
  ///
  /// In es, this message translates to:
  /// **'Enviar invitación'**
  String get sendInvitation;

  /// No description provided for @invitationSent.
  ///
  /// In es, this message translates to:
  /// **'La persona fue habilitada y la invitación fue creada.'**
  String get invitationSent;

  /// No description provided for @invitationResent.
  ///
  /// In es, this message translates to:
  /// **'La invitación fue reenviada y su vigencia fue renovada.'**
  String get invitationResent;

  /// No description provided for @invitationCancelled.
  ///
  /// In es, this message translates to:
  /// **'La invitación fue cancelada.'**
  String get invitationCancelled;

  /// No description provided for @noInvitations.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay personas habilitadas'**
  String get noInvitations;

  /// No description provided for @noInvitationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Habilita la primera persona para asignarle una evaluación.'**
  String get noInvitationsDescription;

  /// No description provided for @expiresOn.
  ///
  /// In es, this message translates to:
  /// **'Vence: {date}'**
  String expiresOn(String date);

  /// No description provided for @resend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar'**
  String get resend;

  /// No description provided for @cancelInvitation.
  ///
  /// In es, this message translates to:
  /// **'Cancelar invitación'**
  String get cancelInvitation;

  /// No description provided for @confirmCancellation.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas cancelar esta invitación? La persona perderá el acceso a la evaluación.'**
  String get confirmCancellation;

  /// No description provided for @keepInvitation.
  ///
  /// In es, this message translates to:
  /// **'Conservar'**
  String get keepInvitation;

  /// No description provided for @statusExpired.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get statusExpired;

  /// No description provided for @statusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get statusCancelled;

  /// No description provided for @statusInterrupted.
  ///
  /// In es, this message translates to:
  /// **'Interrumpida'**
  String get statusInterrupted;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Administra tu organización, procesos de contratación y seguridad.'**
  String get settingsSubtitle;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @changesSaved.
  ///
  /// In es, this message translates to:
  /// **'Los cambios se guardaron correctamente.'**
  String get changesSaved;

  /// No description provided for @organizationProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de la organización'**
  String get organizationProfile;

  /// No description provided for @organizationDescription.
  ///
  /// In es, this message translates to:
  /// **'Información que identifica a tu empresa dentro de TaleX.'**
  String get organizationDescription;

  /// No description provided for @organizationName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la organización'**
  String get organizationName;

  /// No description provided for @industry.
  ///
  /// In es, this message translates to:
  /// **'Industria'**
  String get industry;

  /// No description provided for @companySize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de la empresa'**
  String get companySize;

  /// No description provided for @timezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get timezone;

  /// No description provided for @timezoneBogota.
  ///
  /// In es, this message translates to:
  /// **'Bogotá (UTC-5)'**
  String get timezoneBogota;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige qué actualizaciones deseas recibir.'**
  String get notificationsDescription;

  /// No description provided for @candidateUpdates.
  ///
  /// In es, this message translates to:
  /// **'Actividad de evaluaciones'**
  String get candidateUpdates;

  /// No description provided for @candidateUpdatesDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos cuando una evaluación inicia, se completa o vence.'**
  String get candidateUpdatesDescription;

  /// No description provided for @weeklyDigest.
  ///
  /// In es, this message translates to:
  /// **'Resumen semanal'**
  String get weeklyDigest;

  /// No description provided for @weeklyDigestDescription.
  ///
  /// In es, this message translates to:
  /// **'Métricas y actividad del proceso cada lunes.'**
  String get weeklyDigestDescription;

  /// No description provided for @securityTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguridad y acceso'**
  String get securityTitle;

  /// No description provided for @securityDescription.
  ///
  /// In es, this message translates to:
  /// **'Protege el acceso de tu equipo a la plataforma.'**
  String get securityDescription;

  /// No description provided for @twoFactorAuth.
  ///
  /// In es, this message translates to:
  /// **'Autenticación de dos factores'**
  String get twoFactorAuth;

  /// No description provided for @twoFactorDescription.
  ///
  /// In es, this message translates to:
  /// **'Solicita un segundo factor a los administradores.'**
  String get twoFactorDescription;

  /// No description provided for @sessionTimeout.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de sesión'**
  String get sessionTimeout;

  /// No description provided for @manageMembers.
  ///
  /// In es, this message translates to:
  /// **'Administrar miembros'**
  String get manageMembers;

  /// No description provided for @technologyIndustry.
  ///
  /// In es, this message translates to:
  /// **'Tecnología'**
  String get technologyIndustry;

  /// No description provided for @employeesRange.
  ///
  /// In es, this message translates to:
  /// **'51–200 empleados'**
  String get employeesRange;

  /// No description provided for @minutes30.
  ///
  /// In es, this message translates to:
  /// **'30 minutos'**
  String get minutes30;

  /// No description provided for @adminCommandCenter.
  ///
  /// In es, this message translates to:
  /// **'Centro de mando'**
  String get adminCommandCenter;

  /// No description provided for @adminCommandSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Una lectura ejecutiva de TaleX: operación, clientes y crecimiento.'**
  String get adminCommandSubtitle;

  /// No description provided for @adminCompanies.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get adminCompanies;

  /// No description provided for @adminProcesses.
  ///
  /// In es, this message translates to:
  /// **'Procesos'**
  String get adminProcesses;

  /// No description provided for @adminPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get adminPeople;

  /// No description provided for @adminAffinity.
  ///
  /// In es, this message translates to:
  /// **'Afinidad'**
  String get adminAffinity;

  /// No description provided for @adminCommercial.
  ///
  /// In es, this message translates to:
  /// **'Comercial'**
  String get adminCommercial;

  /// No description provided for @adminSales.
  ///
  /// In es, this message translates to:
  /// **'Ventas'**
  String get adminSales;

  /// No description provided for @adminCultureLeads.
  ///
  /// In es, this message translates to:
  /// **'Leads cultura'**
  String get adminCultureLeads;

  /// No description provided for @adminCultureLeadsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Prospectos del diagnóstico de la landing /micultura. No se crea empresa ni membresía.'**
  String get adminCultureLeadsSubtitle;

  /// No description provided for @adminCultureLeadsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay leads de cultura.'**
  String get adminCultureLeadsEmpty;

  /// No description provided for @cultureLeadEmployees.
  ///
  /// In es, this message translates to:
  /// **'Empleados'**
  String get cultureLeadEmployees;

  /// No description provided for @cultureLeadTraits.
  ///
  /// In es, this message translates to:
  /// **'Rasgos culturales'**
  String get cultureLeadTraits;

  /// No description provided for @cultureLeadComment.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get cultureLeadComment;

  /// No description provided for @cultureLeadUtm.
  ///
  /// In es, this message translates to:
  /// **'UTM'**
  String get cultureLeadUtm;

  /// No description provided for @cultureLeadStatusNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get cultureLeadStatusNew;

  /// No description provided for @cultureLeadStatusContacted.
  ///
  /// In es, this message translates to:
  /// **'Contactado'**
  String get cultureLeadStatusContacted;

  /// No description provided for @cultureLeadStatusQualified.
  ///
  /// In es, this message translates to:
  /// **'Calificado'**
  String get cultureLeadStatusQualified;

  /// No description provided for @cultureLeadStatusDiscarded.
  ///
  /// In es, this message translates to:
  /// **'Descartado'**
  String get cultureLeadStatusDiscarded;

  /// No description provided for @adminAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Analytics'**
  String get adminAnalytics;

  /// No description provided for @adminAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get adminAlerts;

  /// No description provided for @adminXebec.
  ///
  /// In es, this message translates to:
  /// **'Xebec'**
  String get adminXebec;

  /// No description provided for @adminSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get adminSettings;

  /// No description provided for @adminSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar empresas, procesos o personas...'**
  String get adminSearchHint;

  /// No description provided for @kpiTotalCompanies.
  ///
  /// In es, this message translates to:
  /// **'Empresas totales'**
  String get kpiTotalCompanies;

  /// No description provided for @kpiActiveCompanies.
  ///
  /// In es, this message translates to:
  /// **'Empresas activas'**
  String get kpiActiveCompanies;

  /// No description provided for @kpiEvaluatedPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas evaluadas'**
  String get kpiEvaluatedPeople;

  /// No description provided for @kpiCompletedEvaluations.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones completadas'**
  String get kpiCompletedEvaluations;

  /// No description provided for @kpiAffinities.
  ///
  /// In es, this message translates to:
  /// **'Afinidades detectadas'**
  String get kpiAffinities;

  /// No description provided for @kpiPeriodSales.
  ///
  /// In es, this message translates to:
  /// **'Ventas del periodo'**
  String get kpiPeriodSales;

  /// No description provided for @kpiMrr.
  ///
  /// In es, this message translates to:
  /// **'MRR'**
  String get kpiMrr;

  /// No description provided for @kpiAtRisk.
  ///
  /// In es, this message translates to:
  /// **'Empresas en riesgo'**
  String get kpiAtRisk;

  /// No description provided for @recentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get recentActivity;

  /// No description provided for @noActivity.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay actividad registrada.'**
  String get noActivity;

  /// No description provided for @talexFunnel.
  ///
  /// In es, this message translates to:
  /// **'Embudo TaleX'**
  String get talexFunnel;

  /// No description provided for @funnelCompanies.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get funnelCompanies;

  /// No description provided for @funnelProcesses.
  ///
  /// In es, this message translates to:
  /// **'Procesos'**
  String get funnelProcesses;

  /// No description provided for @funnelInvited.
  ///
  /// In es, this message translates to:
  /// **'Personas invitadas'**
  String get funnelInvited;

  /// No description provided for @funnelStarted.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones iniciadas'**
  String get funnelStarted;

  /// No description provided for @funnelCompleted.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones completadas'**
  String get funnelCompleted;

  /// No description provided for @funnelAffinities.
  ///
  /// In es, this message translates to:
  /// **'Afinidades detectadas'**
  String get funnelAffinities;

  /// No description provided for @funnelDecisions.
  ///
  /// In es, this message translates to:
  /// **'Resultados / decisiones'**
  String get funnelDecisions;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get noData;

  /// No description provided for @noInformationYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay información.'**
  String get noInformationYet;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @splashVerifyingSession.
  ///
  /// In es, this message translates to:
  /// **'Verificando tu sesión'**
  String get splashVerifyingSession;

  /// No description provided for @splashSigningIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciando sesión'**
  String get splashSigningIn;

  /// No description provided for @splashLoadingSettings.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus configuraciones'**
  String get splashLoadingSettings;

  /// No description provided for @splashPreparingWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu espacio de trabajo'**
  String get splashPreparingWorkspace;

  /// No description provided for @splashSigningOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrando sesión de forma segura'**
  String get splashSigningOut;

  /// No description provided for @splashValidatingInvite.
  ///
  /// In es, this message translates to:
  /// **'Validando tu invitación'**
  String get splashValidatingInvite;

  /// No description provided for @splashPreparingAssessment.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu evaluación'**
  String get splashPreparingAssessment;

  /// No description provided for @newCompany.
  ///
  /// In es, this message translates to:
  /// **'Nueva empresa'**
  String get newCompany;

  /// No description provided for @newProcess.
  ///
  /// In es, this message translates to:
  /// **'Nuevo proceso'**
  String get newProcess;

  /// No description provided for @newPerson.
  ///
  /// In es, this message translates to:
  /// **'Registrar persona'**
  String get newPerson;

  /// No description provided for @newDeal.
  ///
  /// In es, this message translates to:
  /// **'Nueva oportunidad'**
  String get newDeal;

  /// No description provided for @newSale.
  ///
  /// In es, this message translates to:
  /// **'Registrar venta'**
  String get newSale;

  /// No description provided for @companyStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get companyStatusActive;

  /// No description provided for @companyStatusOnboarding.
  ///
  /// In es, this message translates to:
  /// **'En onboarding'**
  String get companyStatusOnboarding;

  /// No description provided for @companyStatusInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactiva'**
  String get companyStatusInactive;

  /// No description provided for @companyStatusAtRisk.
  ///
  /// In es, this message translates to:
  /// **'En riesgo'**
  String get companyStatusAtRisk;

  /// No description provided for @companyStatusSuspended.
  ///
  /// In es, this message translates to:
  /// **'Suspendida'**
  String get companyStatusSuspended;

  /// No description provided for @processStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get processStatusActive;

  /// No description provided for @processStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get processStatusClosed;

  /// No description provided for @evaluationInvited.
  ///
  /// In es, this message translates to:
  /// **'Invitada'**
  String get evaluationInvited;

  /// No description provided for @evaluationStarted.
  ///
  /// In es, this message translates to:
  /// **'Iniciada'**
  String get evaluationStarted;

  /// No description provided for @evaluationInProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get evaluationInProgress;

  /// No description provided for @evaluationCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get evaluationCompleted;

  /// No description provided for @evaluationAbandoned.
  ///
  /// In es, this message translates to:
  /// **'Abandonada'**
  String get evaluationAbandoned;

  /// No description provided for @affinityHigh.
  ///
  /// In es, this message translates to:
  /// **'Afinidad alta'**
  String get affinityHigh;

  /// No description provided for @affinityMedium.
  ///
  /// In es, this message translates to:
  /// **'Afinidad media'**
  String get affinityMedium;

  /// No description provided for @affinityLow.
  ///
  /// In es, this message translates to:
  /// **'Afinidad baja'**
  String get affinityLow;

  /// No description provided for @affinityUnknown.
  ///
  /// In es, this message translates to:
  /// **'Sin clasificar'**
  String get affinityUnknown;

  /// No description provided for @dealProspect.
  ///
  /// In es, this message translates to:
  /// **'Prospecto'**
  String get dealProspect;

  /// No description provided for @dealContacted.
  ///
  /// In es, this message translates to:
  /// **'Contactado'**
  String get dealContacted;

  /// No description provided for @dealMeeting.
  ///
  /// In es, this message translates to:
  /// **'Reunión'**
  String get dealMeeting;

  /// No description provided for @dealProposal.
  ///
  /// In es, this message translates to:
  /// **'Propuesta'**
  String get dealProposal;

  /// No description provided for @dealNegotiation.
  ///
  /// In es, this message translates to:
  /// **'Negociación'**
  String get dealNegotiation;

  /// No description provided for @dealClient.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get dealClient;

  /// No description provided for @filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get filterAll;

  /// No description provided for @filterArchived.
  ///
  /// In es, this message translates to:
  /// **'Archivadas'**
  String get filterArchived;

  /// No description provided for @companyActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones de la empresa'**
  String get companyActions;

  /// No description provided for @disableCompany.
  ///
  /// In es, this message translates to:
  /// **'Inhabilitar'**
  String get disableCompany;

  /// No description provided for @enableCompany.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get enableCompany;

  /// No description provided for @archiveCompany.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la vista'**
  String get archiveCompany;

  /// No description provided for @restoreCompany.
  ///
  /// In es, this message translates to:
  /// **'Restaurar a la vista'**
  String get restoreCompany;

  /// No description provided for @disableCompanyTitle.
  ///
  /// In es, this message translates to:
  /// **'Inhabilitar empresa'**
  String get disableCompanyTitle;

  /// No description provided for @disableCompanyBody.
  ///
  /// In es, this message translates to:
  /// **'La empresa dejará de operar en TaleX. Los datos se conservan. ¿Confirmas?'**
  String get disableCompanyBody;

  /// No description provided for @enableCompanyTitle.
  ///
  /// In es, this message translates to:
  /// **'Reactivar empresa'**
  String get enableCompanyTitle;

  /// No description provided for @enableCompanyBody.
  ///
  /// In es, this message translates to:
  /// **'La empresa volverá a estar activa y su equipo podrá entrar. ¿Confirmas?'**
  String get enableCompanyBody;

  /// No description provided for @archiveCompanyTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la vista'**
  String get archiveCompanyTitle;

  /// No description provided for @archiveCompanyBody.
  ///
  /// In es, this message translates to:
  /// **'No se borra nada. La empresa deja de verse en el listado principal y queda en Archivadas. ¿Confirmas?'**
  String get archiveCompanyBody;

  /// No description provided for @restoreCompanyTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar empresa'**
  String get restoreCompanyTitle;

  /// No description provided for @restoreCompanyBody.
  ///
  /// In es, this message translates to:
  /// **'La empresa volverá a aparecer en el listado. ¿Confirmas?'**
  String get restoreCompanyBody;

  /// No description provided for @confirmAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirmAction;

  /// No description provided for @noArchivedCompanies.
  ///
  /// In es, this message translates to:
  /// **'No hay empresas archivadas.'**
  String get noArchivedCompanies;

  /// No description provided for @errorCompanyDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta empresa está inhabilitada. Un SuperAdmin puede reactivarla.'**
  String get errorCompanyDisabled;

  /// No description provided for @lastActivity.
  ///
  /// In es, this message translates to:
  /// **'Última actividad'**
  String get lastActivity;

  /// No description provided for @joinedAt.
  ///
  /// In es, this message translates to:
  /// **'Incorporación'**
  String get joinedAt;

  /// No description provided for @openDetail.
  ///
  /// In es, this message translates to:
  /// **'Abrir detalle'**
  String get openDetail;

  /// No description provided for @backToCompanies.
  ///
  /// In es, this message translates to:
  /// **'Volver a empresas'**
  String get backToCompanies;

  /// No description provided for @backToPeople.
  ///
  /// In es, this message translates to:
  /// **'Volver a personas'**
  String get backToPeople;

  /// No description provided for @backToProcesses.
  ///
  /// In es, this message translates to:
  /// **'Volver a procesos'**
  String get backToProcesses;

  /// No description provided for @presentedPeople.
  ///
  /// In es, this message translates to:
  /// **'Ya presentaron'**
  String get presentedPeople;

  /// No description provided for @pendingPeople.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pendingPeople;

  /// No description provided for @visitWebsite.
  ///
  /// In es, this message translates to:
  /// **'Visitar sitio web'**
  String get visitWebsite;

  /// No description provided for @editCompany.
  ///
  /// In es, this message translates to:
  /// **'Editar empresa'**
  String get editCompany;

  /// No description provided for @companyOverview.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get companyOverview;

  /// No description provided for @companyCommercial.
  ///
  /// In es, this message translates to:
  /// **'Comercial'**
  String get companyCommercial;

  /// No description provided for @companyMetrics.
  ///
  /// In es, this message translates to:
  /// **'Utilización'**
  String get companyMetrics;

  /// No description provided for @noCompanies.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay empresas en TaleX.'**
  String get noCompanies;

  /// No description provided for @noProcesses.
  ///
  /// In es, this message translates to:
  /// **'No hay procesos para mostrar.'**
  String get noProcesses;

  /// No description provided for @noPeople.
  ///
  /// In es, this message translates to:
  /// **'No hay personas evaluadas para mostrar. No se exponen respuestas sensibles.'**
  String get noPeople;

  /// No description provided for @noDeals.
  ///
  /// In es, this message translates to:
  /// **'No hay oportunidades comerciales.'**
  String get noDeals;

  /// No description provided for @noSales.
  ///
  /// In es, this message translates to:
  /// **'No hay ventas registradas en este periodo.'**
  String get noSales;

  /// No description provided for @noAlerts.
  ///
  /// In es, this message translates to:
  /// **'No hay alertas calculadas con los datos actuales.'**
  String get noAlerts;

  /// No description provided for @period7.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get period7;

  /// No description provided for @period30.
  ///
  /// In es, this message translates to:
  /// **'30 días'**
  String get period30;

  /// No description provided for @period90.
  ///
  /// In es, this message translates to:
  /// **'90 días'**
  String get period90;

  /// No description provided for @period12m.
  ///
  /// In es, this message translates to:
  /// **'12 meses'**
  String get period12m;

  /// No description provided for @completionRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de finalización'**
  String get completionRate;

  /// No description provided for @suggestedAction.
  ///
  /// In es, this message translates to:
  /// **'Acción sugerida'**
  String get suggestedAction;

  /// No description provided for @xebecSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Xebec responde con el contexto real del centro de mando.'**
  String get xebecSubtitle;

  /// No description provided for @xebecPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo está TaleX?'**
  String get xebecPlaceholder;

  /// No description provided for @xebecEmpty.
  ///
  /// In es, this message translates to:
  /// **'Pregunta por el estado de TaleX, empresas en riesgo u oportunidades. Xebec usa métricas reales, no suposiciones.'**
  String get xebecEmpty;

  /// No description provided for @askXebec.
  ///
  /// In es, this message translates to:
  /// **'Preguntar'**
  String get askXebec;

  /// No description provided for @adminSettingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usuarios, roles y parámetros reales del sistema. Nada ficticio.'**
  String get adminSettingsSubtitle;

  /// No description provided for @superAdminHelp.
  ///
  /// In es, this message translates to:
  /// **'El SuperAdmin se eleva si su correo está en config/superadmin.emails o si el documento de usuario ya tiene role=superadmin. Las credenciales viven en Firebase Auth; cámbialas con recuperación de contraseña o la consola.'**
  String get superAdminHelp;

  /// No description provided for @adminUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get adminUsers;

  /// No description provided for @roleLabel.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get roleLabel;

  /// No description provided for @adminSaved.
  ///
  /// In es, this message translates to:
  /// **'Los cambios se guardaron en TaleX.'**
  String get adminSaved;

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get amount;

  /// No description provided for @plan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @owner.
  ///
  /// In es, this message translates to:
  /// **'Responsable'**
  String get owner;

  /// No description provided for @nextAction.
  ///
  /// In es, this message translates to:
  /// **'Próxima acción'**
  String get nextAction;

  /// No description provided for @product.
  ///
  /// In es, this message translates to:
  /// **'Producto o servicio'**
  String get product;

  /// No description provided for @recurring.
  ///
  /// In es, this message translates to:
  /// **'Recurrente (MRR)'**
  String get recurring;

  /// No description provided for @estimatedValue.
  ///
  /// In es, this message translates to:
  /// **'Valor estimado'**
  String get estimatedValue;

  /// No description provided for @affinityScore.
  ///
  /// In es, this message translates to:
  /// **'Puntaje de afinidad (0-100)'**
  String get affinityScore;

  /// No description provided for @statusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get statusLabel;

  /// No description provided for @priorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get priorityLow;

  /// No description provided for @alertRisk.
  ///
  /// In es, this message translates to:
  /// **'Riesgo'**
  String get alertRisk;

  /// No description provided for @alertOperational.
  ///
  /// In es, this message translates to:
  /// **'Operacional'**
  String get alertOperational;

  /// No description provided for @alertCommercial.
  ///
  /// In es, this message translates to:
  /// **'Comercial'**
  String get alertCommercial;

  /// No description provided for @alertProduct.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get alertProduct;

  /// No description provided for @alertOpportunity.
  ///
  /// In es, this message translates to:
  /// **'Oportunidad'**
  String get alertOpportunity;

  /// No description provided for @salesPeriod.
  ///
  /// In es, this message translates to:
  /// **'Ventas del periodo'**
  String get salesPeriod;

  /// No description provided for @salesCumulative.
  ///
  /// In es, this message translates to:
  /// **'Ventas acumuladas'**
  String get salesCumulative;

  /// No description provided for @newCustomers.
  ///
  /// In es, this message translates to:
  /// **'Clientes en el periodo'**
  String get newCustomers;

  /// No description provided for @averageTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket promedio'**
  String get averageTicket;

  /// No description provided for @growth.
  ///
  /// In es, this message translates to:
  /// **'Crecimiento vs periodo anterior'**
  String get growth;

  /// No description provided for @activityByDay.
  ///
  /// In es, this message translates to:
  /// **'Actividad por día'**
  String get activityByDay;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige el idioma de la interfaz. El cambio se aplica de inmediato.'**
  String get languageDescription;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vacancy.
  ///
  /// In es, this message translates to:
  /// **'Vacante'**
  String get vacancy;

  /// No description provided for @createVacancy.
  ///
  /// In es, this message translates to:
  /// **'Crear vacante'**
  String get createVacancy;

  /// No description provided for @createRespondent.
  ///
  /// In es, this message translates to:
  /// **'Crear encuestado'**
  String get createRespondent;

  /// No description provided for @activationPin.
  ///
  /// In es, this message translates to:
  /// **'PIN de activación'**
  String get activationPin;

  /// No description provided for @pinGenerated.
  ///
  /// In es, this message translates to:
  /// **'Empresa creada. PIN de primer acceso: {pin}.'**
  String pinGenerated(String pin);

  /// No description provided for @invitePinReady.
  ///
  /// In es, this message translates to:
  /// **'PIN de primer acceso: {pin}.'**
  String invitePinReady(String pin);

  /// No description provided for @nit.
  ///
  /// In es, this message translates to:
  /// **'NIT'**
  String get nit;

  /// No description provided for @sector.
  ///
  /// In es, this message translates to:
  /// **'Sector'**
  String get sector;

  /// No description provided for @city.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get city;

  /// No description provided for @website.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get website;

  /// No description provided for @logoUrl.
  ///
  /// In es, this message translates to:
  /// **'URL del logo'**
  String get logoUrl;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @companyDna.
  ///
  /// In es, this message translates to:
  /// **'ADN de la empresa'**
  String get companyDna;

  /// No description provided for @companyValues.
  ///
  /// In es, this message translates to:
  /// **'Valores'**
  String get companyValues;

  /// No description provided for @companyCulture.
  ///
  /// In es, this message translates to:
  /// **'Cultura'**
  String get companyCulture;

  /// No description provided for @standoutPeople.
  ///
  /// In es, this message translates to:
  /// **'¿Qué destaca del personal?'**
  String get standoutPeople;

  /// No description provided for @skipCompanyDna.
  ///
  /// In es, this message translates to:
  /// **'Omitir el ADN de la empresa por ahora. La organización podrá completarlo después.'**
  String get skipCompanyDna;

  /// No description provided for @country.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get country;

  /// No description provided for @department.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get department;

  /// No description provided for @divisionState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get divisionState;

  /// No description provided for @divisionCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comunidad autónoma'**
  String get divisionCommunity;

  /// No description provided for @divisionRegion.
  ///
  /// In es, this message translates to:
  /// **'Estado / departamento / región'**
  String get divisionRegion;

  /// No description provided for @cityMunicipality.
  ///
  /// In es, this message translates to:
  /// **'Ciudad / municipio'**
  String get cityMunicipality;

  /// No description provided for @searchLocation.
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar...'**
  String get searchLocation;

  /// No description provided for @searchCountry.
  ///
  /// In es, this message translates to:
  /// **'Buscar país...'**
  String get searchCountry;

  /// No description provided for @searchDivision.
  ///
  /// In es, this message translates to:
  /// **'Buscar división...'**
  String get searchDivision;

  /// No description provided for @searchCity.
  ///
  /// In es, this message translates to:
  /// **'Buscar ciudad...'**
  String get searchCity;

  /// No description provided for @locationLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las ubicaciones. Intenta nuevamente.'**
  String get locationLoadError;

  /// No description provided for @locationNoResults.
  ///
  /// In es, this message translates to:
  /// **'No hay resultados para esa búsqueda.'**
  String get locationNoResults;

  /// No description provided for @locationSelectCountryFirst.
  ///
  /// In es, this message translates to:
  /// **'Primero elige un país'**
  String get locationSelectCountryFirst;

  /// No description provided for @provisionStepCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get provisionStepCompany;

  /// No description provided for @provisionStepDna.
  ///
  /// In es, this message translates to:
  /// **'ADN'**
  String get provisionStepDna;

  /// No description provided for @provisionStepInvite.
  ///
  /// In es, this message translates to:
  /// **'Invitación'**
  String get provisionStepInvite;

  /// No description provided for @pasteLogoUrl.
  ///
  /// In es, this message translates to:
  /// **'Pegar URL del logo'**
  String get pasteLogoUrl;

  /// No description provided for @selectLogoFile.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar archivo'**
  String get selectLogoFile;

  /// No description provided for @logoPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa del logo'**
  String get logoPreview;

  /// No description provided for @sectorFinance.
  ///
  /// In es, this message translates to:
  /// **'Financiero'**
  String get sectorFinance;

  /// No description provided for @sectorHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get sectorHealth;

  /// No description provided for @sectorEducation.
  ///
  /// In es, this message translates to:
  /// **'Educación'**
  String get sectorEducation;

  /// No description provided for @sectorManufacturing.
  ///
  /// In es, this message translates to:
  /// **'Manufactura'**
  String get sectorManufacturing;

  /// No description provided for @sectorRetail.
  ///
  /// In es, this message translates to:
  /// **'Comercio'**
  String get sectorRetail;

  /// No description provided for @sectorServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get sectorServices;

  /// No description provided for @sectorConstruction.
  ///
  /// In es, this message translates to:
  /// **'Construcción'**
  String get sectorConstruction;

  /// No description provided for @sectorEnergy.
  ///
  /// In es, this message translates to:
  /// **'Energía'**
  String get sectorEnergy;

  /// No description provided for @sectorAgribusiness.
  ///
  /// In es, this message translates to:
  /// **'Agroindustria'**
  String get sectorAgribusiness;

  /// No description provided for @sectorGovernment.
  ///
  /// In es, this message translates to:
  /// **'Gobierno'**
  String get sectorGovernment;

  /// No description provided for @sectorOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get sectorOther;

  /// No description provided for @size1to10.
  ///
  /// In es, this message translates to:
  /// **'1–10 empleados'**
  String get size1to10;

  /// No description provided for @size11to50.
  ///
  /// In es, this message translates to:
  /// **'11–50 empleados'**
  String get size11to50;

  /// No description provided for @size201to500.
  ///
  /// In es, this message translates to:
  /// **'201–500 empleados'**
  String get size201to500;

  /// No description provided for @size500plus.
  ///
  /// In es, this message translates to:
  /// **'Más de 500 empleados'**
  String get size500plus;

  /// No description provided for @emailSent.
  ///
  /// In es, this message translates to:
  /// **'El correo de invitación se envió correctamente.'**
  String get emailSent;

  /// No description provided for @errorEmailNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'La empresa se creó, pero falta configurar SMTP para enviar correos. El PIN quedó en pantalla.'**
  String get errorEmailNotConfigured;

  /// No description provided for @errorEmailSendFailed.
  ///
  /// In es, this message translates to:
  /// **'La empresa se creó, pero el correo no se pudo enviar. Revisa spam o la configuración SMTP. El PIN quedó en pantalla.'**
  String get errorEmailSendFailed;

  /// No description provided for @completeCompanyDnaTitle.
  ///
  /// In es, this message translates to:
  /// **'Completa el ADN de la empresa'**
  String get completeCompanyDnaTitle;

  /// No description provided for @completeCompanyDnaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Antes de entrar al espacio, registra los valores, la cultura y lo que destaca del personal.'**
  String get completeCompanyDnaSubtitle;

  /// No description provided for @reviewCompanyDnaTitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica el ADN de la empresa'**
  String get reviewCompanyDnaTitle;

  /// No description provided for @reviewCompanyDnaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa que estos datos describan bien a la organización. Si algo no cuadra, corrígelo antes de continuar.'**
  String get reviewCompanyDnaSubtitle;

  /// No description provided for @confirmCompanyDna.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y continuar'**
  String get confirmCompanyDna;

  /// No description provided for @dnaRequired.
  ///
  /// In es, this message translates to:
  /// **'Completa valores, cultura y lo que destaca del personal.'**
  String get dnaRequired;

  /// No description provided for @soughtCharacteristics.
  ///
  /// In es, this message translates to:
  /// **'Características buscadas'**
  String get soughtCharacteristics;

  /// No description provided for @firstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get lastName;

  /// No description provided for @activateAccount.
  ///
  /// In es, this message translates to:
  /// **'Activar cuenta'**
  String get activateAccount;

  /// No description provided for @activateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa el correo invitado y el PIN de 6 dígitos que llegó a esa bandeja. El PIN caduca a los 15 minutos.'**
  String get activateSubtitle;

  /// No description provided for @activatePinHint.
  ///
  /// In es, this message translates to:
  /// **'6 dígitos · válido 15 minutos. Usa el PIN del correo más reciente, no uno de una prueba anterior.'**
  String get activatePinHint;

  /// No description provided for @mustChangePasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu contraseña'**
  String get mustChangePasswordTitle;

  /// No description provided for @mustChangePasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Esta contraseña es la que usarás de ahora en adelante para entrar a TaleX.'**
  String get mustChangePasswordSubtitle;

  /// No description provided for @createPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get createPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get passwordsDoNotMatch;

  /// No description provided for @documentNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get documentNumber;

  /// No description provided for @activeVacancies.
  ///
  /// In es, this message translates to:
  /// **'Vacantes activas'**
  String get activeVacancies;

  /// No description provided for @closedVacancies.
  ///
  /// In es, this message translates to:
  /// **'Vacantes cerradas'**
  String get closedVacancies;

  /// No description provided for @pendingAssessments.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones pendientes'**
  String get pendingAssessments;

  /// No description provided for @completedAssessments.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones completadas'**
  String get completedAssessments;

  /// No description provided for @noVacancies.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes vacantes creadas.'**
  String get noVacancies;

  /// No description provided for @noCandidates.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay encuestados en este proceso.'**
  String get noCandidates;

  /// No description provided for @noTeamMembers.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay personas en el equipo.'**
  String get noTeamMembers;

  /// No description provided for @affinityWithCompany.
  ///
  /// In es, this message translates to:
  /// **'Afinidad con la empresa'**
  String get affinityWithCompany;

  /// No description provided for @affinityWithVacancy.
  ///
  /// In es, this message translates to:
  /// **'Afinidad con la vacante'**
  String get affinityWithVacancy;

  /// No description provided for @likertStronglyDisagree.
  ///
  /// In es, this message translates to:
  /// **'Muy en desacuerdo'**
  String get likertStronglyDisagree;

  /// No description provided for @likertDisagree.
  ///
  /// In es, this message translates to:
  /// **'En desacuerdo'**
  String get likertDisagree;

  /// No description provided for @likertNeutral.
  ///
  /// In es, this message translates to:
  /// **'Ni de acuerdo ni en desacuerdo'**
  String get likertNeutral;

  /// No description provided for @likertAgree.
  ///
  /// In es, this message translates to:
  /// **'De acuerdo'**
  String get likertAgree;

  /// No description provided for @likertStronglyAgree.
  ///
  /// In es, this message translates to:
  /// **'Muy de acuerdo'**
  String get likertStronglyAgree;

  /// No description provided for @questionProgress.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {current} de {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @goBack.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get goBack;

  /// No description provided for @finish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finish;

  /// No description provided for @basicResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado básico'**
  String get basicResult;

  /// No description provided for @fullResultLocked.
  ///
  /// In es, this message translates to:
  /// **'El resultado completo estará disponible cuando se habilite el acceso.'**
  String get fullResultLocked;

  /// No description provided for @compare.
  ///
  /// In es, this message translates to:
  /// **'Comparar'**
  String get compare;

  /// No description provided for @characteristic.
  ///
  /// In es, this message translates to:
  /// **'Característica'**
  String get characteristic;

  /// No description provided for @team.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get team;

  /// No description provided for @inviteRecruiter.
  ///
  /// In es, this message translates to:
  /// **'Invitar al equipo'**
  String get inviteRecruiter;

  /// No description provided for @inviteTeamSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La persona recibirá un PIN de 6 dígitos al correo. Caduca a los 15 minutos.'**
  String get inviteTeamSubtitle;

  /// No description provided for @teamRole.
  ///
  /// In es, this message translates to:
  /// **'Rol en la empresa'**
  String get teamRole;

  /// No description provided for @teamRoleCompanyAdmin.
  ///
  /// In es, this message translates to:
  /// **'CEO'**
  String get teamRoleCompanyAdmin;

  /// No description provided for @teamRoleCompanyLead.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get teamRoleCompanyLead;

  /// No description provided for @teamRolePeopleOps.
  ///
  /// In es, this message translates to:
  /// **'Recursos humanos'**
  String get teamRolePeopleOps;

  /// No description provided for @teamRoleRecruiter.
  ///
  /// In es, this message translates to:
  /// **'Reclutamiento'**
  String get teamRoleRecruiter;

  /// No description provided for @teamRoleHiringManager.
  ///
  /// In es, this message translates to:
  /// **'Líder técnico'**
  String get teamRoleHiringManager;

  /// No description provided for @teamRoleHint.
  ///
  /// In es, this message translates to:
  /// **'CEO y administrador pueden invitar al resto del equipo. Recursos humanos, reclutamiento y líder técnico trabajan vacantes y candidatos.'**
  String get teamRoleHint;

  /// No description provided for @vacanciesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea y da contexto a las vacantes de tu proceso. La ubicación de la vacante no cambia el perfil de la empresa.'**
  String get vacanciesSubtitle;

  /// No description provided for @teamSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Personas con acceso a TaleX en tu empresa.'**
  String get teamSubtitle;

  /// No description provided for @workModeOnsite.
  ///
  /// In es, this message translates to:
  /// **'Presencial'**
  String get workModeOnsite;

  /// No description provided for @workModeRemote.
  ///
  /// In es, this message translates to:
  /// **'Virtual'**
  String get workModeRemote;

  /// No description provided for @workModeHybrid.
  ///
  /// In es, this message translates to:
  /// **'Híbrida'**
  String get workModeHybrid;

  /// No description provided for @workModeHint.
  ///
  /// In es, this message translates to:
  /// **'Si es virtual, la ciudad es opcional. Si es presencial o híbrida, usa la ubicación de la empresa y ajústala solo para esta vacante.'**
  String get workModeHint;

  /// No description provided for @vacancyCityOptional.
  ///
  /// In es, this message translates to:
  /// **'Ciudad de referencia (opcional)'**
  String get vacancyCityOptional;

  /// No description provided for @seniorityHint.
  ///
  /// In es, this message translates to:
  /// **'Indica la experiencia esperada para el rol. No entra en el cálculo de afinidad.'**
  String get seniorityHint;

  /// No description provided for @seniorityJunior.
  ///
  /// In es, this message translates to:
  /// **'Inicial'**
  String get seniorityJunior;

  /// No description provided for @seniorityMid.
  ///
  /// In es, this message translates to:
  /// **'Intermedio'**
  String get seniorityMid;

  /// No description provided for @senioritySenior.
  ///
  /// In es, this message translates to:
  /// **'Con experiencia'**
  String get senioritySenior;

  /// No description provided for @seniorityLead.
  ///
  /// In es, this message translates to:
  /// **'Liderazgo'**
  String get seniorityLead;

  /// No description provided for @contractIndefinite.
  ///
  /// In es, this message translates to:
  /// **'Indefinido'**
  String get contractIndefinite;

  /// No description provided for @contractFixed.
  ///
  /// In es, this message translates to:
  /// **'Término fijo'**
  String get contractFixed;

  /// No description provided for @contractServices.
  ///
  /// In es, this message translates to:
  /// **'Prestación de servicios'**
  String get contractServices;

  /// No description provided for @contractInternship.
  ///
  /// In es, this message translates to:
  /// **'Práctica o pasantía'**
  String get contractInternship;

  /// No description provided for @contractTemporary.
  ///
  /// In es, this message translates to:
  /// **'Temporal'**
  String get contractTemporary;

  /// No description provided for @areaPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas y cultura'**
  String get areaPeople;

  /// No description provided for @areaFinanceOps.
  ///
  /// In es, this message translates to:
  /// **'Finanzas'**
  String get areaFinanceOps;

  /// No description provided for @areaOperations.
  ///
  /// In es, this message translates to:
  /// **'Operaciones'**
  String get areaOperations;

  /// No description provided for @areaCommercial.
  ///
  /// In es, this message translates to:
  /// **'Comercial'**
  String get areaCommercial;

  /// No description provided for @areaCustomer.
  ///
  /// In es, this message translates to:
  /// **'Atención a clientes'**
  String get areaCustomer;

  /// No description provided for @areaAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get areaAdmin;

  /// No description provided for @areaEngineering.
  ///
  /// In es, this message translates to:
  /// **'Ingeniería y desarrollo'**
  String get areaEngineering;

  /// No description provided for @areaProduct.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get areaProduct;

  /// No description provided for @areaData.
  ///
  /// In es, this message translates to:
  /// **'Datos y analítica'**
  String get areaData;

  /// No description provided for @areaSupport.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get areaSupport;

  /// No description provided for @areaRisk.
  ///
  /// In es, this message translates to:
  /// **'Riesgo y cumplimiento'**
  String get areaRisk;

  /// No description provided for @areaAccounting.
  ///
  /// In es, this message translates to:
  /// **'Contabilidad'**
  String get areaAccounting;

  /// No description provided for @areaClinical.
  ///
  /// In es, this message translates to:
  /// **'Clínica'**
  String get areaClinical;

  /// No description provided for @areaCare.
  ///
  /// In es, this message translates to:
  /// **'Cuidado y atención'**
  String get areaCare;

  /// No description provided for @areaAcademic.
  ///
  /// In es, this message translates to:
  /// **'Académica'**
  String get areaAcademic;

  /// No description provided for @areaTraining.
  ///
  /// In es, this message translates to:
  /// **'Formación'**
  String get areaTraining;

  /// No description provided for @areaProduction.
  ///
  /// In es, this message translates to:
  /// **'Producción'**
  String get areaProduction;

  /// No description provided for @areaQuality.
  ///
  /// In es, this message translates to:
  /// **'Calidad'**
  String get areaQuality;

  /// No description provided for @areaMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get areaMaintenance;

  /// No description provided for @areaStore.
  ///
  /// In es, this message translates to:
  /// **'Punto de venta'**
  String get areaStore;

  /// No description provided for @areaLogistics.
  ///
  /// In es, this message translates to:
  /// **'Logística'**
  String get areaLogistics;

  /// No description provided for @areaProjects.
  ///
  /// In es, this message translates to:
  /// **'Proyectos'**
  String get areaProjects;

  /// No description provided for @areaField.
  ///
  /// In es, this message translates to:
  /// **'Campo u obra'**
  String get areaField;

  /// No description provided for @areaPublicService.
  ///
  /// In es, this message translates to:
  /// **'Servicio público'**
  String get areaPublicService;

  /// No description provided for @vacancyAreaHint.
  ///
  /// In es, this message translates to:
  /// **'Las áreas cambian según el sector de la empresa. Elige la más cercana al rol.'**
  String get vacancyAreaHint;

  /// No description provided for @invitationUsed.
  ///
  /// In es, this message translates to:
  /// **'Activada'**
  String get invitationUsed;

  /// No description provided for @invitationPending.
  ///
  /// In es, this message translates to:
  /// **'Invitación pendiente'**
  String get invitationPending;

  /// No description provided for @statusInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get statusInReview;

  /// No description provided for @statusShortlisted.
  ///
  /// In es, this message translates to:
  /// **'Preseleccionado'**
  String get statusShortlisted;

  /// No description provided for @statusInterview.
  ///
  /// In es, this message translates to:
  /// **'Entrevista'**
  String get statusInterview;

  /// No description provided for @statusFinalist.
  ///
  /// In es, this message translates to:
  /// **'Finalista'**
  String get statusFinalist;

  /// No description provided for @statusHired.
  ///
  /// In es, this message translates to:
  /// **'Contratado'**
  String get statusHired;

  /// No description provided for @statusRejected.
  ///
  /// In es, this message translates to:
  /// **'No seleccionado'**
  String get statusRejected;

  /// No description provided for @vacancyName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la vacante'**
  String get vacancyName;

  /// No description provided for @vacancyArea.
  ///
  /// In es, this message translates to:
  /// **'Área'**
  String get vacancyArea;

  /// No description provided for @workMode.
  ///
  /// In es, this message translates to:
  /// **'Modalidad'**
  String get workMode;

  /// No description provided for @contractType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de contrato'**
  String get contractType;

  /// No description provided for @seniority.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get seniority;

  /// No description provided for @roleProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil buscado'**
  String get roleProfile;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @companyProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de empresa'**
  String get companyProfile;

  /// No description provided for @vacancyInsights.
  ///
  /// In es, this message translates to:
  /// **'Lectura de la vacante'**
  String get vacancyInsights;

  /// No description provided for @vacancyInsightsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay suficiente información para mostrar una lectura de esta vacante.'**
  String get vacancyInsightsEmpty;

  /// No description provided for @vacancyInsightsCounts.
  ///
  /// In es, this message translates to:
  /// **'{invited} invitados · {started} en curso · {completed} completaron la evaluación.'**
  String vacancyInsightsCounts(int invited, int started, int completed);

  /// No description provided for @dnaSelectSeveral.
  ///
  /// In es, this message translates to:
  /// **'Puedes elegir varias opciones. Si agregas una que no estaba en la lista, también puedes quitarla.'**
  String get dnaSelectSeveral;

  /// No description provided for @removeCustomOption.
  ///
  /// In es, this message translates to:
  /// **'Eliminar esta opción'**
  String get removeCustomOption;

  /// No description provided for @results.
  ///
  /// In es, this message translates to:
  /// **'Resultados'**
  String get results;

  /// No description provided for @resultsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lectura de afinidad de las personas que ya se presentaron. Aquí verás el detalle cuando la metodología complete la ficha.'**
  String get resultsSubtitle;

  /// No description provided for @compareHint.
  ///
  /// In es, this message translates to:
  /// **'El recuadro a la izquierda sirve para elegir dos o más personas y usar Comparar. No cambia el estado del proceso.'**
  String get compareHint;

  /// No description provided for @affinityCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get affinityCompany;

  /// No description provided for @affinityVacancy.
  ///
  /// In es, this message translates to:
  /// **'Vacante'**
  String get affinityVacancy;

  /// No description provided for @affinityUnknownHint.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay evaluación completa, por eso la afinidad no está clasificada.'**
  String get affinityUnknownHint;

  /// No description provided for @affinityMockNote.
  ///
  /// In es, this message translates to:
  /// **'Análisis generado con IA a partir de la encuesta, que es la misma para todas las empresas. Es información de apoyo: TaleX no toma decisiones de contratación ni descarta personas. La decisión final corresponde a tu equipo.'**
  String get affinityMockNote;

  /// No description provided for @affinityAnalysisNone.
  ///
  /// In es, this message translates to:
  /// **'Esta evaluación todavía no tiene análisis de afinidad.'**
  String get affinityAnalysisNone;

  /// No description provided for @affinityAnalysisPending.
  ///
  /// In es, this message translates to:
  /// **'Estamos analizando las respuestas de la encuesta. Puede tardar unos segundos.'**
  String get affinityAnalysisPending;

  /// No description provided for @affinityAnalysisFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar el análisis de afinidad en este momento. Puedes intentarlo de nuevo.'**
  String get affinityAnalysisFailed;

  /// No description provided for @affinityAnalysisMissingDna.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay información suficiente de la encuesta para completar el análisis.'**
  String get affinityAnalysisMissingDna;

  /// No description provided for @affinityAnalysisIncompleteAnswers.
  ///
  /// In es, this message translates to:
  /// **'La evaluación no tiene suficientes respuestas para analizar la afinidad.'**
  String get affinityAnalysisIncompleteAnswers;

  /// No description provided for @affinityAnalyzeAction.
  ///
  /// In es, this message translates to:
  /// **'Analizar afinidad'**
  String get affinityAnalyzeAction;

  /// No description provided for @affinityReanalyzeAction.
  ///
  /// In es, this message translates to:
  /// **'Volver a analizar'**
  String get affinityReanalyzeAction;

  /// No description provided for @affinityAlignmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Dónde hay afinidad'**
  String get affinityAlignmentsTitle;

  /// No description provided for @affinityDifferencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Aspectos que podrían generar dificultades'**
  String get affinityDifferencesTitle;

  /// No description provided for @affinityTopicsTitle.
  ///
  /// In es, this message translates to:
  /// **'Temas para conversar en la entrevista'**
  String get affinityTopicsTitle;

  /// No description provided for @affinityGuidanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Orientación para Recursos Humanos'**
  String get affinityGuidanceTitle;

  /// No description provided for @affinityDataGapsTitle.
  ///
  /// In es, this message translates to:
  /// **'Información que faltó'**
  String get affinityDataGapsTitle;

  /// No description provided for @affinityScoreValue.
  ///
  /// In es, this message translates to:
  /// **'Puntaje {score}/100'**
  String affinityScoreValue(int score);

  /// No description provided for @continueAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @respondentWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Quiero conocerte bien'**
  String get respondentWelcomeTitle;

  /// No description provided for @respondentWelcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Hola. Soy TaleXito. Esta encuesta es la misma para todas las empresas. Yo recibo tus respuestas para conocer mejor cómo te gusta trabajar. El resultado no lo determino yo: una persona especializada te lo contará más adelante.'**
  String get respondentWelcomeBody;

  /// No description provided for @respondentWelcomeAction.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get respondentWelcomeAction;

  /// No description provided for @respondentHello.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String respondentHello(String name);

  /// No description provided for @respondentHomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu evaluación de afinidad'**
  String get respondentHomeTitle;

  /// No description provided for @respondentHomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'TaleX no decide si te contratan. Mide qué tan cerca estás del perfil que la empresa describió para esta vacante.'**
  String get respondentHomeSubtitle;

  /// No description provided for @respondentDuration.
  ///
  /// In es, this message translates to:
  /// **'Reserva unos 40 minutos en un lugar tranquilo. Puedes avanzar con calma.'**
  String get respondentDuration;

  /// No description provided for @respondentLikertHint.
  ///
  /// In es, this message translates to:
  /// **'En la mayoría de preguntas verás dos frases, una a cada lado. Elige el recuadro que quede más cerca de la que mejor te describe. No hay respuestas correctas o incorrectas.'**
  String get respondentLikertHint;

  /// No description provided for @startAssessment.
  ///
  /// In es, this message translates to:
  /// **'Iniciar evaluación'**
  String get startAssessment;

  /// No description provided for @assignedVacancy.
  ///
  /// In es, this message translates to:
  /// **'Vacante asignada'**
  String get assignedVacancy;

  /// No description provided for @viewFullSummary.
  ///
  /// In es, this message translates to:
  /// **'Ver resumen orientativo'**
  String get viewFullSummary;

  /// No description provided for @hideFullSummary.
  ///
  /// In es, this message translates to:
  /// **'Ocultar resumen'**
  String get hideFullSummary;

  /// No description provided for @fullSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen orientativo'**
  String get fullSummaryTitle;

  /// No description provided for @fullSummaryIntro.
  ///
  /// In es, this message translates to:
  /// **'Esta vista es una maqueta de cómo se verá la lectura. Las dimensiones de abajo son de ejemplo hasta que TaleX entregue el detalle real.'**
  String get fullSummaryIntro;

  /// No description provided for @dimensionCommunication.
  ///
  /// In es, this message translates to:
  /// **'Comunicación'**
  String get dimensionCommunication;

  /// No description provided for @dimensionAdaptability.
  ///
  /// In es, this message translates to:
  /// **'Adaptabilidad'**
  String get dimensionAdaptability;

  /// No description provided for @dimensionCollaboration.
  ///
  /// In es, this message translates to:
  /// **'Colaboración'**
  String get dimensionCollaboration;

  /// No description provided for @dimensionInitiative.
  ///
  /// In es, this message translates to:
  /// **'Iniciativa'**
  String get dimensionInitiative;

  /// No description provided for @veryHigh.
  ///
  /// In es, this message translates to:
  /// **'Muy alta'**
  String get veryHigh;

  /// No description provided for @resultThanks.
  ///
  /// In es, this message translates to:
  /// **'Gracias por completar la evaluación. La empresa podrá ver tu afinidad con su cultura y con esta vacante.'**
  String get resultThanks;

  /// No description provided for @newAssessment.
  ///
  /// In es, this message translates to:
  /// **'Nueva evaluación'**
  String get newAssessment;

  /// No description provided for @pendingAssessmentNotification.
  ///
  /// In es, this message translates to:
  /// **'Tienes una evaluación pendiente.'**
  String get pendingAssessmentNotification;

  /// No description provided for @assessmentCompletedNotification.
  ///
  /// In es, this message translates to:
  /// **'La evaluación fue completada.'**
  String get assessmentCompletedNotification;

  /// No description provided for @newVacancyNotification.
  ///
  /// In es, this message translates to:
  /// **'Se creó una nueva vacante.'**
  String get newVacancyNotification;

  /// No description provided for @newActivityNotification.
  ///
  /// In es, this message translates to:
  /// **'Hay nueva actividad en TaleX.'**
  String get newActivityNotification;

  /// No description provided for @errorNeedSignIn.
  ///
  /// In es, this message translates to:
  /// **'Necesitas iniciar sesión.'**
  String get errorNeedSignIn;

  /// No description provided for @errorNeedAuthEmail.
  ///
  /// In es, this message translates to:
  /// **'Necesitas un correo autenticado.'**
  String get errorNeedAuthEmail;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para esta operación.'**
  String get errorPermissionDenied;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo nuevamente.'**
  String get errorUnexpected;

  /// No description provided for @errorApiUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con TaleX. No puedes entrar hasta que la API responda.'**
  String get errorApiUnavailable;

  /// No description provided for @errorCompanyNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la empresa.'**
  String get errorCompanyNotFound;

  /// No description provided for @errorRespondentExists.
  ///
  /// In es, this message translates to:
  /// **'Ya existe un encuestado con este correo en la vacante.'**
  String get errorRespondentExists;

  /// No description provided for @errorInviteMissing.
  ///
  /// In es, this message translates to:
  /// **'No hay una invitación para este correo.'**
  String get errorInviteMissing;

  /// No description provided for @errorInviteUsed.
  ///
  /// In es, this message translates to:
  /// **'Esta invitación ya fue utilizada.'**
  String get errorInviteUsed;

  /// No description provided for @errorInviteInvalid.
  ///
  /// In es, this message translates to:
  /// **'El enlace de invitación no es válido.'**
  String get errorInviteInvalid;

  /// No description provided for @errorInviteExpired.
  ///
  /// In es, this message translates to:
  /// **'El enlace caducó. Pide una invitación nueva.'**
  String get errorInviteExpired;

  /// No description provided for @errorInvalidPin.
  ///
  /// In es, this message translates to:
  /// **'El PIN no es válido.'**
  String get errorInvalidPin;

  /// No description provided for @errorPinExpired.
  ///
  /// In es, this message translates to:
  /// **'El PIN caducó. Pide una invitación nueva; dura 15 minutos.'**
  String get errorPinExpired;

  /// No description provided for @errorDocumentMismatch.
  ///
  /// In es, this message translates to:
  /// **'El documento no coincide con la invitación.'**
  String get errorDocumentMismatch;

  /// No description provided for @errorAssessmentMissing.
  ///
  /// In es, this message translates to:
  /// **'No hay una evaluación asignada.'**
  String get errorAssessmentMissing;

  /// No description provided for @errorDocumentPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'El número de documento debe tener al menos 6 caracteres para usarse como contraseña.'**
  String get errorDocumentPasswordTooShort;

  /// No description provided for @registerPinHint.
  ///
  /// In es, this message translates to:
  /// **'PIN de 6 dígitos que llegó al correo'**
  String get registerPinHint;

  /// No description provided for @googlePinTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el PIN del correo'**
  String get googlePinTitle;

  /// No description provided for @googlePinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta de Google ya está lista. Confirma el PIN de 6 dígitos para vincular la invitación.'**
  String get googlePinSubtitle;

  /// No description provided for @addCustomOption.
  ///
  /// In es, this message translates to:
  /// **'Agregar \"{value}\"'**
  String addCustomOption(String value);

  /// No description provided for @searchOrAdd.
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar o agregar...'**
  String get searchOrAdd;

  /// No description provided for @customAreaLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del área'**
  String get customAreaLabel;

  /// No description provided for @areaOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get areaOther;

  /// No description provided for @dnaValueIntegrity.
  ///
  /// In es, this message translates to:
  /// **'Integridad'**
  String get dnaValueIntegrity;

  /// No description provided for @dnaValueRespect.
  ///
  /// In es, this message translates to:
  /// **'Respeto'**
  String get dnaValueRespect;

  /// No description provided for @dnaValueCollaboration.
  ///
  /// In es, this message translates to:
  /// **'Colaboración'**
  String get dnaValueCollaboration;

  /// No description provided for @dnaValueInnovation.
  ///
  /// In es, this message translates to:
  /// **'Innovación'**
  String get dnaValueInnovation;

  /// No description provided for @dnaValueExcellence.
  ///
  /// In es, this message translates to:
  /// **'Excelencia'**
  String get dnaValueExcellence;

  /// No description provided for @dnaValueEmpathy.
  ///
  /// In es, this message translates to:
  /// **'Empatía'**
  String get dnaValueEmpathy;

  /// No description provided for @dnaCultureClose.
  ///
  /// In es, this message translates to:
  /// **'Cercana y humana'**
  String get dnaCultureClose;

  /// No description provided for @dnaCultureFormal.
  ///
  /// In es, this message translates to:
  /// **'Formal y estructurada'**
  String get dnaCultureFormal;

  /// No description provided for @dnaCultureLearning.
  ///
  /// In es, this message translates to:
  /// **'Aprendizaje continuo'**
  String get dnaCultureLearning;

  /// No description provided for @dnaCultureAgile.
  ///
  /// In es, this message translates to:
  /// **'Ágil'**
  String get dnaCultureAgile;

  /// No description provided for @dnaCultureAutonomous.
  ///
  /// In es, this message translates to:
  /// **'Autónoma'**
  String get dnaCultureAutonomous;

  /// No description provided for @dnaStandoutOwnership.
  ///
  /// In es, this message translates to:
  /// **'Sentido de dueño'**
  String get dnaStandoutOwnership;

  /// No description provided for @dnaStandoutCommunication.
  ///
  /// In es, this message translates to:
  /// **'Comunicación clara'**
  String get dnaStandoutCommunication;

  /// No description provided for @dnaStandoutAdaptability.
  ///
  /// In es, this message translates to:
  /// **'Adaptabilidad'**
  String get dnaStandoutAdaptability;

  /// No description provided for @dnaStandoutInitiative.
  ///
  /// In es, this message translates to:
  /// **'Iniciativa'**
  String get dnaStandoutInitiative;

  /// No description provided for @dnaStandoutTeamwork.
  ///
  /// In es, this message translates to:
  /// **'Trabajo en equipo'**
  String get dnaStandoutTeamwork;

  /// No description provided for @assessmentKindLabel.
  ///
  /// In es, this message translates to:
  /// **'Esta es tu evaluación'**
  String get assessmentKindLabel;

  /// No description provided for @assessmentKindAffinity.
  ///
  /// In es, this message translates to:
  /// **'Afinidad'**
  String get assessmentKindAffinity;

  /// No description provided for @assessmentKindFit.
  ///
  /// In es, this message translates to:
  /// **'Fit'**
  String get assessmentKindFit;

  /// No description provided for @sentByCompany.
  ///
  /// In es, this message translates to:
  /// **'Te la envió'**
  String get sentByCompany;

  /// No description provided for @respondentQuestionCount.
  ///
  /// In es, this message translates to:
  /// **'En total son {count} preguntas.'**
  String respondentQuestionCount(int count);

  /// No description provided for @assessmentFinishedTitle.
  ///
  /// In es, this message translates to:
  /// **'TaleXito ya recibió tus respuestas'**
  String get assessmentFinishedTitle;

  /// No description provided for @assessmentFinishedBody.
  ///
  /// In es, this message translates to:
  /// **'TaleXito se encarga de recibir la información. No determina el resultado. Una persona especializada te lo dirá más adelante.'**
  String get assessmentFinishedBody;

  /// No description provided for @surveyResultRequest.
  ///
  /// In es, this message translates to:
  /// **'Quiero conocer mis resultados'**
  String get surveyResultRequest;

  /// No description provided for @surveyResultRequested.
  ///
  /// In es, this message translates to:
  /// **'Gracias por hacernos saber eso. El resultado se demora un poco. Una persona especializada se encarga de eso.'**
  String get surveyResultRequested;

  /// No description provided for @companyProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Datos generales de la empresa.'**
  String get companyProfileSubtitle;

  /// No description provided for @downloadPdf.
  ///
  /// In es, this message translates to:
  /// **'Descargar informe PDF'**
  String get downloadPdf;

  /// No description provided for @candidateResultTitle.
  ///
  /// In es, this message translates to:
  /// **'Informe de resultados'**
  String get candidateResultTitle;

  /// No description provided for @editCandidate.
  ///
  /// In es, this message translates to:
  /// **'Editar candidato'**
  String get editCandidate;

  /// No description provided for @deleteCandidate.
  ///
  /// In es, this message translates to:
  /// **'Eliminar candidato'**
  String get deleteCandidate;

  /// No description provided for @deleteCandidateConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {name}? Se borrarán sus respuestas y su enlace de invitación dejará de funcionar. Esta acción no se puede deshacer.'**
  String deleteCandidateConfirm(String name);

  /// No description provided for @deleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteAction;

  /// No description provided for @candidateUpdated.
  ///
  /// In es, this message translates to:
  /// **'Candidato actualizado.'**
  String get candidateUpdated;

  /// No description provided for @candidateDeleted.
  ///
  /// In es, this message translates to:
  /// **'Candidato eliminado.'**
  String get candidateDeleted;

  /// No description provided for @backToResults.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get backToResults;

  /// No description provided for @candidatesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Personas invitadas a evaluar afinidad con tus vacantes.'**
  String get candidatesSubtitle;

  /// No description provided for @candidateProcessStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del proceso'**
  String get candidateProcessStatus;

  /// No description provided for @respondentInviteHint.
  ///
  /// In es, this message translates to:
  /// **'La persona recibirá un correo con un enlace para presentar la prueba de inmediato. Cuando la complete, verás el estado y el resultado aquí.'**
  String get respondentInviteHint;

  /// No description provided for @firstAccessCompany.
  ///
  /// In es, this message translates to:
  /// **'Primer acceso'**
  String get firstAccessCompany;

  /// No description provided for @assessmentSignInHint.
  ///
  /// In es, this message translates to:
  /// **'Si te invitaron a una evaluación, usa el enlace del correo para comenzar la prueba. No necesitas registrarte con un PIN.'**
  String get assessmentSignInHint;

  /// No description provided for @respondentInviteSent.
  ///
  /// In es, this message translates to:
  /// **'Invitación lista. El candidato recibe un enlace por correo para presentar la prueba.'**
  String get respondentInviteSent;

  /// No description provided for @recoverPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar acceso'**
  String get recoverPasswordTitle;

  /// No description provided for @recoverPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el correo de tu cuenta TaleX. Te enviaremos un PIN de 6 dígitos para continuar.'**
  String get recoverPasswordSubtitle;

  /// No description provided for @recoverContinue.
  ///
  /// In es, this message translates to:
  /// **'Enviar PIN'**
  String get recoverContinue;

  /// No description provided for @recoverPinTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get recoverPinTitle;

  /// No description provided for @recoverPinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un PIN. Ingrésalo para actualizar tu contraseña.'**
  String get recoverPinSubtitle;

  /// No description provided for @recoverPinHint.
  ///
  /// In es, this message translates to:
  /// **'6 dígitos · válido 15 minutos. Revisa también spam. Si no pediste este cambio, ignora el mensaje.'**
  String get recoverPinHint;

  /// No description provided for @recoverPinSent.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un PIN a tu correo.'**
  String get recoverPinSent;

  /// No description provided for @recoverVerifyPin.
  ///
  /// In es, this message translates to:
  /// **'Verificar PIN'**
  String get recoverVerifyPin;

  /// No description provided for @recoverResendPin.
  ///
  /// In es, this message translates to:
  /// **'Reenviar PIN'**
  String get recoverResendPin;

  /// No description provided for @recoverUpdatePassword.
  ///
  /// In es, this message translates to:
  /// **'Actualizar contraseña'**
  String get recoverUpdatePassword;

  /// No description provided for @recoverSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get recoverSuccessTitle;

  /// No description provided for @recoverSuccessBody.
  ///
  /// In es, this message translates to:
  /// **'Ya puedes iniciar sesión en TaleX con tu nueva contraseña.'**
  String get recoverSuccessBody;

  /// No description provided for @errorResetCooldown.
  ///
  /// In es, this message translates to:
  /// **'Espera un minuto antes de pedir otro PIN.'**
  String get errorResetCooldown;

  /// No description provided for @errorResetTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera un momento e inténtalo de nuevo.'**
  String get errorResetTooManyAttempts;

  /// No description provided for @dashboardReadyToReview.
  ///
  /// In es, this message translates to:
  /// **'{count} evaluaciones listas para revisar'**
  String dashboardReadyToReview(int count);

  /// No description provided for @dashboardPendingToStart.
  ///
  /// In es, this message translates to:
  /// **'{count} personas aún no inician la evaluación'**
  String dashboardPendingToStart(int count);

  /// No description provided for @dashboardStalledAssessments.
  ///
  /// In es, this message translates to:
  /// **'{count} evaluaciones detenidas más de 24 h'**
  String dashboardStalledAssessments(int count);

  /// No description provided for @dashboardRecentEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay actividad de encuestados en este espacio.'**
  String get dashboardRecentEmpty;

  /// No description provided for @dashboardAlertsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay alertas pendientes en este momento.'**
  String get dashboardAlertsEmpty;

  /// No description provided for @errorAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hay una cuenta TaleX con este correo. Si te invitaron, entra por Primer acceso con el PIN.'**
  String get errorAccountNotFound;

  /// No description provided for @adminQuestions.
  ///
  /// In es, this message translates to:
  /// **'Encuesta de afinidad'**
  String get adminQuestions;

  /// No description provided for @adminQuestionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas que responde el candidato. Puedes verlas, editarlas y actualizarlas.'**
  String get adminQuestionsSubtitle;

  /// No description provided for @adminCultureSurvey.
  ///
  /// In es, this message translates to:
  /// **'Encuesta de cultura'**
  String get adminCultureSurvey;

  /// No description provided for @adminCultureSurveySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Formulario de valores y cultura de la empresa. Sube el archivo una vez; después solo se edita.'**
  String get adminCultureSurveySubtitle;

  /// No description provided for @adminCultureSurveyEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay preguntas de cultura. Sube un archivo CSV o JSON para cargarlas.'**
  String get adminCultureSurveyEmpty;

  /// No description provided for @adminSurveys.
  ///
  /// In es, this message translates to:
  /// **'Encuestas'**
  String get adminSurveys;

  /// No description provided for @adminSurveysCultureVs.
  ///
  /// In es, this message translates to:
  /// **'Cultura candidato vs empresa'**
  String get adminSurveysCultureVs;

  /// No description provided for @adminSurveysMyCulture.
  ///
  /// In es, this message translates to:
  /// **'Mi cultura'**
  String get adminSurveysMyCulture;

  /// No description provided for @adminMyCultureSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empresas que llegaron por la landing /micultura, con lo que respondieron sobre su cultura.'**
  String get adminMyCultureSubtitle;

  /// No description provided for @adminMyCultureRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get adminMyCultureRefresh;

  /// No description provided for @adminMyCultureError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los datos de Mi cultura.'**
  String get adminMyCultureError;

  /// No description provided for @adminMyCultureEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay respuestas de Mi cultura.'**
  String get adminMyCultureEmpty;

  /// No description provided for @adminMyCultureNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ninguna empresa coincide con la búsqueda.'**
  String get adminMyCultureNoResults;

  /// No description provided for @adminMyCultureSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar por empresa, contacto o correo...'**
  String get adminMyCultureSearch;

  /// No description provided for @adminMyCultureOrganizations.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get adminMyCultureOrganizations;

  /// No description provided for @adminMyCultureLeads.
  ///
  /// In es, this message translates to:
  /// **'Leads'**
  String get adminMyCultureLeads;

  /// No description provided for @adminMyCultureResponded.
  ///
  /// In es, this message translates to:
  /// **'Respondieron'**
  String get adminMyCultureResponded;

  /// No description provided for @adminMyCultureUnassigned.
  ///
  /// In es, this message translates to:
  /// **'Sin empresa asignada'**
  String get adminMyCultureUnassigned;

  /// No description provided for @adminMyCultureLastLead.
  ///
  /// In es, this message translates to:
  /// **'Último lead'**
  String get adminMyCultureLastLead;

  /// No description provided for @adminMyCultureComments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get adminMyCultureComments;

  /// No description provided for @adminMyCultureRespondedBadge.
  ///
  /// In es, this message translates to:
  /// **'Respondió'**
  String get adminMyCultureRespondedBadge;

  /// No description provided for @adminMyCulturePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get adminMyCulturePending;

  /// No description provided for @adminMyCultureEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Correo enviado'**
  String get adminMyCultureEmailSent;

  /// No description provided for @adminMyCultureEmailSkipped.
  ///
  /// In es, this message translates to:
  /// **'Correo omitido'**
  String get adminMyCultureEmailSkipped;

  /// No description provided for @adminMyCultureEmailFailed.
  ///
  /// In es, this message translates to:
  /// **'Correo fallido'**
  String get adminMyCultureEmailFailed;

  /// No description provided for @adminMyCultureLeadCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 lead} other{{count} leads}}'**
  String adminMyCultureLeadCount(int count);

  /// No description provided for @adminMyCultureRespondedCount.
  ///
  /// In es, this message translates to:
  /// **'{responded} de {total} respondieron'**
  String adminMyCultureRespondedCount(int responded, int total);

  /// No description provided for @cultureQuestionsOpen.
  ///
  /// In es, this message translates to:
  /// **'Preguntas'**
  String get cultureQuestionsOpen;

  /// No description provided for @cultureSurveyPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa de la encuesta'**
  String get cultureSurveyPreview;

  /// No description provided for @cultureSurveyDemo.
  ///
  /// In es, this message translates to:
  /// **'Ver demo de la encuesta'**
  String get cultureSurveyDemo;

  /// No description provided for @cultureSurveyDemoCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace demo'**
  String get cultureSurveyDemoCopy;

  /// No description provided for @cultureSurveyDemoCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace demo copiado. Al abrirlo no se envían respuestas.'**
  String get cultureSurveyDemoCopied;

  /// No description provided for @cultureQuestionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas de Mi cultura'**
  String get cultureQuestionsTitle;

  /// No description provided for @cultureQuestionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Banco de preguntas de la encuesta que responden los colaboradores de cada empresa.'**
  String get cultureQuestionsSubtitle;

  /// No description provided for @cultureQuestionsBack.
  ///
  /// In es, this message translates to:
  /// **'Volver a Mi cultura'**
  String get cultureQuestionsBack;

  /// No description provided for @cultureQuestionsNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva pregunta'**
  String get cultureQuestionsNew;

  /// No description provided for @cultureQuestionsEditSurvey.
  ///
  /// In es, this message translates to:
  /// **'Título e intro'**
  String get cultureQuestionsEditSurvey;

  /// No description provided for @cultureQuestionsShowInactive.
  ///
  /// In es, this message translates to:
  /// **'Mostrar desactivadas'**
  String get cultureQuestionsShowInactive;

  /// No description provided for @cultureQuestionsSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar por código, nombre, enunciado o sección...'**
  String get cultureQuestionsSearch;

  /// No description provided for @cultureQuestionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay preguntas de cultura.'**
  String get cultureQuestionsEmpty;

  /// No description provided for @cultureQuestionsNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ninguna pregunta coincide con la búsqueda.'**
  String get cultureQuestionsNoResults;

  /// No description provided for @cultureQuestionsInactive.
  ///
  /// In es, this message translates to:
  /// **'Desactivada'**
  String get cultureQuestionsInactive;

  /// No description provided for @cultureQuestionsRequiredBadge.
  ///
  /// In es, this message translates to:
  /// **'Obligatoria'**
  String get cultureQuestionsRequiredBadge;

  /// No description provided for @cultureQuestionsSurveyTitle.
  ///
  /// In es, this message translates to:
  /// **'Título de la encuesta'**
  String get cultureQuestionsSurveyTitle;

  /// No description provided for @cultureQuestionsSurveyIntro.
  ///
  /// In es, this message translates to:
  /// **'Introducción'**
  String get cultureQuestionsSurveyIntro;

  /// No description provided for @cultureQuestionsSurveyNoTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin título configurado'**
  String get cultureQuestionsSurveyNoTitle;

  /// No description provided for @cultureQuestionsCode.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get cultureQuestionsCode;

  /// No description provided for @cultureQuestionsName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get cultureQuestionsName;

  /// No description provided for @cultureQuestionsStatement.
  ///
  /// In es, this message translates to:
  /// **'Enunciado'**
  String get cultureQuestionsStatement;

  /// No description provided for @cultureQuestionsInstruction.
  ///
  /// In es, this message translates to:
  /// **'Instrucción'**
  String get cultureQuestionsInstruction;

  /// No description provided for @cultureQuestionsFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get cultureQuestionsFormat;

  /// No description provided for @cultureQuestionsOptionsSource.
  ///
  /// In es, this message translates to:
  /// **'Origen de opciones'**
  String get cultureQuestionsOptionsSource;

  /// No description provided for @cultureQuestionsSection.
  ///
  /// In es, this message translates to:
  /// **'Sección (clave)'**
  String get cultureQuestionsSection;

  /// No description provided for @cultureQuestionsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Título de la sección'**
  String get cultureQuestionsSectionTitle;

  /// No description provided for @cultureQuestionsTechnique.
  ///
  /// In es, this message translates to:
  /// **'Técnica'**
  String get cultureQuestionsTechnique;

  /// No description provided for @cultureQuestionsRequiredField.
  ///
  /// In es, this message translates to:
  /// **'Obligatoria'**
  String get cultureQuestionsRequiredField;

  /// No description provided for @cultureQuestionsActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get cultureQuestionsActive;

  /// No description provided for @cultureQuestionsOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get cultureQuestionsOptions;

  /// No description provided for @cultureQuestionsOptionId.
  ///
  /// In es, this message translates to:
  /// **'ID'**
  String get cultureQuestionsOptionId;

  /// No description provided for @cultureQuestionsOptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get cultureQuestionsOptionLabel;

  /// No description provided for @cultureQuestionsOptionDimension.
  ///
  /// In es, this message translates to:
  /// **'Dimensión'**
  String get cultureQuestionsOptionDimension;

  /// No description provided for @cultureQuestionsAddOption.
  ///
  /// In es, this message translates to:
  /// **'Agregar opción'**
  String get cultureQuestionsAddOption;

  /// No description provided for @cultureQuestionsRemoveOption.
  ///
  /// In es, this message translates to:
  /// **'Quitar opción'**
  String get cultureQuestionsRemoveOption;

  /// No description provided for @cultureQuestionsOptionIdTaken.
  ///
  /// In es, this message translates to:
  /// **'ID repetido'**
  String get cultureQuestionsOptionIdTaken;

  /// No description provided for @cultureQuestionsUsed.
  ///
  /// In es, this message translates to:
  /// **'Usados en el banco:'**
  String get cultureQuestionsUsed;

  /// No description provided for @cultureQuestionsDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la pregunta {code}? Si solo quieres ocultarla, desactívala.'**
  String cultureQuestionsDeleteBody(String code);

  /// No description provided for @cultureQuestionsErrorLoad.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las preguntas de cultura.'**
  String get cultureQuestionsErrorLoad;

  /// No description provided for @cultureQuestionsErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el cambio.'**
  String get cultureQuestionsErrorGeneric;

  /// No description provided for @cultureQuestionsErrorSignIn.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión venció. Vuelve a iniciar sesión.'**
  String get cultureQuestionsErrorSignIn;

  /// No description provided for @cultureQuestionsErrorPermission.
  ///
  /// In es, this message translates to:
  /// **'Solo el superadmin puede cambiar las preguntas.'**
  String get cultureQuestionsErrorPermission;

  /// No description provided for @cultureQuestionsErrorNotFound.
  ///
  /// In es, this message translates to:
  /// **'Esa pregunta ya no existe. Recarga la lista.'**
  String get cultureQuestionsErrorNotFound;

  /// No description provided for @cultureQuestionsErrorDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una pregunta con ese código.'**
  String get cultureQuestionsErrorDuplicate;

  /// No description provided for @cultureQuestionsErrorInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisa la pregunta: {detail}'**
  String cultureQuestionsErrorInvalid(String detail);

  /// No description provided for @cultureQuestionsErrorInvalidGeneric.
  ///
  /// In es, this message translates to:
  /// **'Falta un dato o hay uno inválido en la pregunta.'**
  String get cultureQuestionsErrorInvalidGeneric;

  /// No description provided for @cultureQuestionsErrorCodesMismatch.
  ///
  /// In es, this message translates to:
  /// **'El banco cambió mientras reordenabas. Recarga la lista e inténtalo de nuevo.'**
  String get cultureQuestionsErrorCodesMismatch;

  /// No description provided for @cultureQuestionsErrorNotDeployed.
  ///
  /// In es, this message translates to:
  /// **'El servidor todavía no tiene las preguntas de cultura publicadas. Cuando el backend las suba, aparecerán aquí.'**
  String get cultureQuestionsErrorNotDeployed;

  /// No description provided for @adminQuestionsUploadFile.
  ///
  /// In es, this message translates to:
  /// **'Subir archivo'**
  String get adminQuestionsUploadFile;

  /// No description provided for @adminQuestionsFrontCultura.
  ///
  /// In es, this message translates to:
  /// **'Cultura vivida'**
  String get adminQuestionsFrontCultura;

  /// No description provided for @adminQuestionsFrontLiderazgo.
  ///
  /// In es, this message translates to:
  /// **'Liderazgo'**
  String get adminQuestionsFrontLiderazgo;

  /// No description provided for @adminQuestionsFrontTrabajo.
  ///
  /// In es, this message translates to:
  /// **'Forma de trabajar'**
  String get adminQuestionsFrontTrabajo;

  /// No description provided for @adminQuestionsFrontPersonas.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get adminQuestionsFrontPersonas;

  /// No description provided for @adminQuestionsFrontApertura.
  ///
  /// In es, this message translates to:
  /// **'Comentarios abiertos'**
  String get adminQuestionsFrontApertura;

  /// No description provided for @adminQuestionsFormatScale.
  ///
  /// In es, this message translates to:
  /// **'Escala'**
  String get adminQuestionsFormatScale;

  /// No description provided for @adminQuestionsFormatText.
  ///
  /// In es, this message translates to:
  /// **'Texto abierto'**
  String get adminQuestionsFormatText;

  /// No description provided for @adminQuestionsFormatSingle.
  ///
  /// In es, this message translates to:
  /// **'Opción única'**
  String get adminQuestionsFormatSingle;

  /// No description provided for @adminQuestionsFormatMulti.
  ///
  /// In es, this message translates to:
  /// **'Opción múltiple'**
  String get adminQuestionsFormatMulti;

  /// No description provided for @adminQuestionsNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva pregunta'**
  String get adminQuestionsNew;

  /// No description provided for @adminQuestionsEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar pregunta'**
  String get adminQuestionsEdit;

  /// No description provided for @adminQuestionsPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get adminQuestionsPreview;

  /// No description provided for @affinityDemoCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa de ejemplo'**
  String get affinityDemoCompany;

  /// No description provided for @affinityDemoCompanyDescription.
  ///
  /// In es, this message translates to:
  /// **'Así se ve la descripción de la empresa que envía la evaluación.'**
  String get affinityDemoCompanyDescription;

  /// No description provided for @affinityDemoVacancy.
  ///
  /// In es, this message translates to:
  /// **'Vacante de ejemplo'**
  String get affinityDemoVacancy;

  /// No description provided for @affinityDemoCandidate.
  ///
  /// In es, this message translates to:
  /// **'Ana Demo'**
  String get affinityDemoCandidate;

  /// No description provided for @adminQuestionsDemo.
  ///
  /// In es, this message translates to:
  /// **'Ver demo'**
  String get adminQuestionsDemo;

  /// No description provided for @adminQuestionsPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista previa de la encuesta'**
  String get adminQuestionsPreviewTitle;

  /// No description provided for @adminQuestionsPreviewNote.
  ///
  /// In es, this message translates to:
  /// **'Simulación: las respuestas no se guardan.'**
  String get adminQuestionsPreviewNote;

  /// No description provided for @adminQuestionsPreviewEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay preguntas activas para mostrar.'**
  String get adminQuestionsPreviewEmpty;

  /// No description provided for @adminQuestionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay preguntas en Firebase.'**
  String get adminQuestionsEmpty;

  /// No description provided for @adminQuestionsSeed.
  ///
  /// In es, this message translates to:
  /// **'Cargar las {count} preguntas base'**
  String adminQuestionsSeed(int count);

  /// No description provided for @adminQuestionsNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ninguna pregunta coincide con el filtro.'**
  String get adminQuestionsNoResults;

  /// No description provided for @adminQuestionsSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar por código, dimensión o enunciado...'**
  String get adminQuestionsSearch;

  /// No description provided for @adminQuestionsAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get adminQuestionsAll;

  /// No description provided for @adminQuestionsSummary.
  ///
  /// In es, this message translates to:
  /// **'{active} activas de {total}'**
  String adminQuestionsSummary(int active, int total);

  /// No description provided for @adminQuestionsFrontValues.
  ///
  /// In es, this message translates to:
  /// **'1 · Valores'**
  String get adminQuestionsFrontValues;

  /// No description provided for @adminQuestionsFrontNeeds.
  ///
  /// In es, this message translates to:
  /// **'2 · Necesidades'**
  String get adminQuestionsFrontNeeds;

  /// No description provided for @adminQuestionsFrontCapabilities.
  ///
  /// In es, this message translates to:
  /// **'3 · Capacidades'**
  String get adminQuestionsFrontCapabilities;

  /// No description provided for @adminQuestionsFormatPair.
  ///
  /// In es, this message translates to:
  /// **'Par de enunciados'**
  String get adminQuestionsFormatPair;

  /// No description provided for @adminQuestionsFormatExperience.
  ///
  /// In es, this message translates to:
  /// **'Enunciado de experiencia'**
  String get adminQuestionsFormatExperience;

  /// No description provided for @adminQuestionsCode.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get adminQuestionsCode;

  /// No description provided for @adminQuestionsFront.
  ///
  /// In es, this message translates to:
  /// **'Frente'**
  String get adminQuestionsFront;

  /// No description provided for @adminQuestionsFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get adminQuestionsFormat;

  /// No description provided for @adminQuestionsDimension.
  ///
  /// In es, this message translates to:
  /// **'Dimensión'**
  String get adminQuestionsDimension;

  /// No description provided for @adminQuestionsDimensionA.
  ///
  /// In es, this message translates to:
  /// **'Dimensión A'**
  String get adminQuestionsDimensionA;

  /// No description provided for @adminQuestionsDimensionB.
  ///
  /// In es, this message translates to:
  /// **'Dimensión B'**
  String get adminQuestionsDimensionB;

  /// No description provided for @adminQuestionsInstruction.
  ///
  /// In es, this message translates to:
  /// **'Instrucción'**
  String get adminQuestionsInstruction;

  /// No description provided for @adminQuestionsStatement.
  ///
  /// In es, this message translates to:
  /// **'Enunciado'**
  String get adminQuestionsStatement;

  /// No description provided for @adminQuestionsStatementA.
  ///
  /// In es, this message translates to:
  /// **'Enunciado A'**
  String get adminQuestionsStatementA;

  /// No description provided for @adminQuestionsStatementB.
  ///
  /// In es, this message translates to:
  /// **'Enunciado B'**
  String get adminQuestionsStatementB;

  /// No description provided for @adminQuestionsOption.
  ///
  /// In es, this message translates to:
  /// **'Opción {number}'**
  String adminQuestionsOption(int number);

  /// No description provided for @adminQuestionsTimeLimit.
  ///
  /// In es, this message translates to:
  /// **'Tiempo límite (segundos)'**
  String get adminQuestionsTimeLimit;

  /// No description provided for @adminQuestionsTimeLimitHint.
  ///
  /// In es, this message translates to:
  /// **'Vacío = sin límite'**
  String get adminQuestionsTimeLimitHint;

  /// No description provided for @adminQuestionsNoLimit.
  ///
  /// In es, this message translates to:
  /// **'Sin límite'**
  String get adminQuestionsNoLimit;

  /// No description provided for @adminQuestionsSeconds.
  ///
  /// In es, this message translates to:
  /// **'{seconds} s'**
  String adminQuestionsSeconds(int seconds);

  /// No description provided for @adminQuestionsActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get adminQuestionsActive;

  /// No description provided for @adminQuestionsInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactiva'**
  String get adminQuestionsInactive;

  /// No description provided for @adminQuestionsRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get adminQuestionsRequired;

  /// No description provided for @adminQuestionsCodeTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una pregunta con este código.'**
  String get adminQuestionsCodeTaken;

  /// No description provided for @adminQuestionsInvalidTime.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número entero mayor que cero.'**
  String get adminQuestionsInvalidTime;

  /// No description provided for @adminQuestionsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar pregunta'**
  String get adminQuestionsDeleteTitle;

  /// No description provided for @adminQuestionsDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará {code} de Firebase. Esta acción no se puede deshacer.'**
  String adminQuestionsDeleteBody(String code);

  /// No description provided for @adminQuestionsDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get adminQuestionsDelete;

  /// No description provided for @adminQuestionsMoveUp.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get adminQuestionsMoveUp;

  /// No description provided for @adminQuestionsMoveDown.
  ///
  /// In es, this message translates to:
  /// **'Bajar'**
  String get adminQuestionsMoveDown;

  /// No description provided for @adminQuestionsError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación en Firebase.'**
  String get adminQuestionsError;

  /// No description provided for @adminQuestionsRestart.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get adminQuestionsRestart;

  /// No description provided for @adminQuestionsDeviceMobile.
  ///
  /// In es, this message translates to:
  /// **'Móvil'**
  String get adminQuestionsDeviceMobile;

  /// No description provided for @adminQuestionsDeviceDesktop.
  ///
  /// In es, this message translates to:
  /// **'Escritorio'**
  String get adminQuestionsDeviceDesktop;

  /// No description provided for @adminQuestionsTimeUp.
  ///
  /// In es, this message translates to:
  /// **'Tiempo agotado'**
  String get adminQuestionsTimeUp;

  /// No description provided for @assessmentPairInstruction.
  ///
  /// In es, this message translates to:
  /// **'¿Cuál de las dos frases lo describe mejor a usted?'**
  String get assessmentPairInstruction;

  /// No description provided for @assessmentNeedInstruction.
  ///
  /// In es, this message translates to:
  /// **'Si tuviera que elegir, ¿cuál de las dos es más importante para usted en un empleo?'**
  String get assessmentNeedInstruction;

  /// No description provided for @assessmentExperienceInstruction.
  ///
  /// In es, this message translates to:
  /// **'Pensando en sus trabajos o proyectos de los últimos tres años, ¿con qué frecuencia le ha ocurrido lo siguiente?'**
  String get assessmentExperienceInstruction;

  /// No description provided for @assessmentPairScaleHint.
  ///
  /// In es, this message translates to:
  /// **'Toque la frase con la que más se identifica, o elija un punto de la escala.'**
  String get assessmentPairScaleHint;

  /// No description provided for @assessmentStatementA.
  ///
  /// In es, this message translates to:
  /// **'Frase A'**
  String get assessmentStatementA;

  /// No description provided for @assessmentStatementB.
  ///
  /// In es, this message translates to:
  /// **'Frase B'**
  String get assessmentStatementB;

  /// No description provided for @pairScale1.
  ///
  /// In es, this message translates to:
  /// **'Claramente la A'**
  String get pairScale1;

  /// No description provided for @pairScale2.
  ///
  /// In es, this message translates to:
  /// **'Más la A que la B'**
  String get pairScale2;

  /// No description provided for @pairScale3.
  ///
  /// In es, this message translates to:
  /// **'Ambas por igual'**
  String get pairScale3;

  /// No description provided for @pairScale4.
  ///
  /// In es, this message translates to:
  /// **'Más la B que la A'**
  String get pairScale4;

  /// No description provided for @pairScale5.
  ///
  /// In es, this message translates to:
  /// **'Claramente la B'**
  String get pairScale5;

  /// No description provided for @frequencyScale1.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get frequencyScale1;

  /// No description provided for @frequencyScale2.
  ///
  /// In es, this message translates to:
  /// **'Rara vez'**
  String get frequencyScale2;

  /// No description provided for @frequencyScale3.
  ///
  /// In es, this message translates to:
  /// **'Algunas veces'**
  String get frequencyScale3;

  /// No description provided for @frequencyScale4.
  ///
  /// In es, this message translates to:
  /// **'Con frecuencia'**
  String get frequencyScale4;

  /// No description provided for @frequencyScale5.
  ///
  /// In es, this message translates to:
  /// **'Siempre'**
  String get frequencyScale5;

  /// No description provided for @adminRoleSuperadmin.
  ///
  /// In es, this message translates to:
  /// **'Superadmin'**
  String get adminRoleSuperadmin;

  /// No description provided for @adminRoleSuperadminHelp.
  ///
  /// In es, this message translates to:
  /// **'Acceso total al panel de TaleX.'**
  String get adminRoleSuperadminHelp;

  /// No description provided for @adminRoleUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get adminRoleUser;

  /// No description provided for @adminRoleUserHelp.
  ///
  /// In es, this message translates to:
  /// **'Acceso estándar, sin panel de administración.'**
  String get adminRoleUserHelp;

  /// No description provided for @adminRoleChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol'**
  String get adminRoleChange;

  /// No description provided for @adminQuestionsImport.
  ///
  /// In es, this message translates to:
  /// **'Importar CSV'**
  String get adminQuestionsImport;

  /// No description provided for @adminQuestionsImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar preguntas'**
  String get adminQuestionsImportTitle;

  /// No description provided for @adminQuestionsImportBody.
  ///
  /// In es, this message translates to:
  /// **'El archivo trae {total} preguntas: {created} nuevas y {replaced} que reemplazan a las que ya existen con el mismo código.'**
  String adminQuestionsImportBody(int total, int created, int replaced);

  /// No description provided for @adminQuestionsImportAction.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get adminQuestionsImportAction;

  /// No description provided for @adminQuestionsCsvUnreadable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el archivo. Debe ser un CSV.'**
  String get adminQuestionsCsvUnreadable;

  /// No description provided for @adminQuestionsCsvEmpty.
  ///
  /// In es, this message translates to:
  /// **'El archivo no tiene preguntas.'**
  String get adminQuestionsCsvEmpty;

  /// No description provided for @adminQuestionsCsvMissingColumns.
  ///
  /// In es, this message translates to:
  /// **'Faltan columnas obligatorias en el CSV: {columns}.'**
  String adminQuestionsCsvMissingColumns(String columns);

  /// No description provided for @adminQuestionsCsvInvalidRow.
  ///
  /// In es, this message translates to:
  /// **'Fila {row}: falta el código o el enunciado A.'**
  String adminQuestionsCsvInvalidRow(int row);

  /// No description provided for @adminQuestionsCsvDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Fila {row}: el código {code} está repetido en el archivo.'**
  String adminQuestionsCsvDuplicate(int row, String code);

  /// No description provided for @adminQuestionsDeleteAll.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get adminQuestionsDeleteAll;

  /// No description provided for @adminQuestionsDeleteAllTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas las preguntas'**
  String get adminQuestionsDeleteAllTitle;

  /// No description provided for @adminQuestionsDeleteAllBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán las {count} preguntas de Firebase. Esta acción no se puede deshacer.'**
  String adminQuestionsDeleteAllBody(int count);

  /// No description provided for @adminQuestionsUploading.
  ///
  /// In es, this message translates to:
  /// **'Cargando preguntas…'**
  String get adminQuestionsUploading;

  /// No description provided for @adminQuestionsDeleting.
  ///
  /// In es, this message translates to:
  /// **'Eliminando preguntas…'**
  String get adminQuestionsDeleting;

  /// No description provided for @adminQuestionsUploaded.
  ///
  /// In es, this message translates to:
  /// **'{count} preguntas cargadas en TaleX.'**
  String adminQuestionsUploaded(int count);

  /// No description provided for @adminQuestionsDeletedAll.
  ///
  /// In es, this message translates to:
  /// **'Se eliminaron todas las preguntas.'**
  String get adminQuestionsDeletedAll;

  /// No description provided for @authBrandEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Fit cultural'**
  String get authBrandEyebrow;

  /// No description provided for @authBrandTitleLead.
  ///
  /// In es, this message translates to:
  /// **'Contrata personas que'**
  String get authBrandTitleLead;

  /// No description provided for @authBrandTitleAccent.
  ///
  /// In es, this message translates to:
  /// **'encajan.'**
  String get authBrandTitleAccent;

  /// No description provided for @authBrandBody.
  ///
  /// In es, this message translates to:
  /// **'Medimos el fit cultural entre cada candidato y tu empresa, antes de contratar. El fit informa; la persona decide.'**
  String get authBrandBody;

  /// No description provided for @authBrandExample.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo'**
  String get authBrandExample;

  /// No description provided for @authBrandCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get authBrandCompany;

  /// No description provided for @authBrandCandidate.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get authBrandCandidate;

  /// No description provided for @authBrandDimCollaboration.
  ///
  /// In es, this message translates to:
  /// **'Colaboración'**
  String get authBrandDimCollaboration;

  /// No description provided for @authBrandDimAutonomy.
  ///
  /// In es, this message translates to:
  /// **'Autonomía'**
  String get authBrandDimAutonomy;

  /// No description provided for @authBrandDimStructure.
  ///
  /// In es, this message translates to:
  /// **'Estructura'**
  String get authBrandDimStructure;

  /// No description provided for @authBrandDimInnovation.
  ///
  /// In es, this message translates to:
  /// **'Innovación'**
  String get authBrandDimInnovation;

  /// No description provided for @authBrandAligned.
  ///
  /// In es, this message translates to:
  /// **'Alineado'**
  String get authBrandAligned;

  /// No description provided for @authBrandFriction.
  ///
  /// In es, this message translates to:
  /// **'Fricción'**
  String get authBrandFriction;

  /// No description provided for @authSignInEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Plataforma TaleX'**
  String get authSignInEyebrow;

  /// No description provided for @adminEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Administración TaleX'**
  String get adminEyebrow;

  /// No description provided for @companyEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Espacio de empresa'**
  String get companyEyebrow;

  /// No description provided for @themeSwitchToLight.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a tema claro'**
  String get themeSwitchToLight;

  /// No description provided for @themeSwitchToDark.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a tema oscuro'**
  String get themeSwitchToDark;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @appearanceDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo se ve TaleX en este dispositivo.'**
  String get appearanceDescription;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @cultureResponsesBack.
  ///
  /// In es, this message translates to:
  /// **'Volver a Mi cultura'**
  String get cultureResponsesBack;

  /// No description provided for @cultureResponsesAnonymous.
  ///
  /// In es, this message translates to:
  /// **'Respuestas anónimas: no se guarda quién respondió y el orden es aleatorio.'**
  String get cultureResponsesAnonymous;

  /// No description provided for @cultureResponsesSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get cultureResponsesSummary;

  /// No description provided for @cultureResponsesIndividual.
  ///
  /// In es, this message translates to:
  /// **'Por persona'**
  String get cultureResponsesIndividual;

  /// No description provided for @cultureResponsesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún nadie del equipo ha respondido la encuesta de esta empresa.'**
  String get cultureResponsesEmpty;

  /// No description provided for @cultureResponsesError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las respuestas.'**
  String get cultureResponsesError;

  /// No description provided for @cultureResponsesMost.
  ///
  /// In es, this message translates to:
  /// **'Más probable'**
  String get cultureResponsesMost;

  /// No description provided for @cultureResponsesLeast.
  ///
  /// In es, this message translates to:
  /// **'Menos probable'**
  String get cultureResponsesLeast;

  /// No description provided for @cultureResponsesYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get cultureResponsesYes;

  /// No description provided for @cultureResponsesNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get cultureResponsesNo;

  /// No description provided for @cultureResponsesNoAnswers.
  ///
  /// In es, this message translates to:
  /// **'Nadie respondió esta pregunta.'**
  String get cultureResponsesNoAnswers;

  /// No description provided for @cultureResponsesLead.
  ///
  /// In es, this message translates to:
  /// **'Lead de la landing'**
  String get cultureResponsesLead;

  /// No description provided for @cultureResponsesRespondents.
  ///
  /// In es, this message translates to:
  /// **'Respuestas'**
  String get cultureResponsesRespondents;

  /// No description provided for @cultureResponsesQuestions.
  ///
  /// In es, this message translates to:
  /// **'Preguntas'**
  String get cultureResponsesQuestions;

  /// No description provided for @cultureResponsesSurveyLink.
  ///
  /// In es, this message translates to:
  /// **'Abrir encuesta de la empresa'**
  String get cultureResponsesSurveyLink;

  /// No description provided for @cultureResponsesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 respuesta anónima} other{{count} respuestas anónimas}}'**
  String cultureResponsesCount(int count);

  /// No description provided for @cultureResponsesPerson.
  ///
  /// In es, this message translates to:
  /// **'Respuesta {index}'**
  String cultureResponsesPerson(int index);

  /// No description provided for @cultureResponsesAnswered.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} respondieron'**
  String cultureResponsesAnswered(int count, int total);

  /// No description provided for @cultureResponsesForecast.
  ///
  /// In es, this message translates to:
  /// **'Pronóstico promedio: {value}%'**
  String cultureResponsesForecast(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
