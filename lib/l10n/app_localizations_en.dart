// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TaleX';

  @override
  String get secureSignIn => 'Secure Sign In';

  @override
  String get workEmail => 'Email address';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressHint => 'candidate@email.com';

  @override
  String get validEmailAddressError => 'Enter a valid email address';

  @override
  String get emailHint => 'email@example.com';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get continueWith => 'Or continue with';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signUpGoogle => 'Sign up with Google';

  @override
  String get googleSignInError =>
      'Unable to sign in with Google. Please try again.';

  @override
  String get newToTalex => 'New to TaleX?';

  @override
  String get createAccountLink => 'Create account';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get validEmailError => 'Enter a valid email address';

  @override
  String get passwordLengthError => 'Password must have at least 6 characters';

  @override
  String get resetEmailSent => 'Check your email to reset your password.';

  @override
  String get createAccount => 'Create your account';

  @override
  String get registerSubtitle =>
      'Create your account to get started with TaleX.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Jane Doe';

  @override
  String get companyName => 'Company Name';

  @override
  String get companyHint => 'Acme Corp';

  @override
  String get signUp => 'Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get logIn => 'Log in';

  @override
  String get requiredField => 'This field is required';

  @override
  String get testimonial =>
      '“TaleX transformed our selection process and helped our team make better decisions.”';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get roles => 'Invitations';

  @override
  String get candidates => 'Enabled people';

  @override
  String get assessments => 'Assessments';

  @override
  String get managers => 'Team';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get support => 'Support';

  @override
  String get documentation => 'Documentation';

  @override
  String get searchHint => 'Search people, invitations, or assessments...';

  @override
  String get overview => 'Overview';

  @override
  String get overviewSubtitle =>
      'A general view of the assessments assigned by your team.';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get newRole => 'Enable person';

  @override
  String get activeRoles => 'Invitations sent';

  @override
  String get evaluatedCandidates => 'Not started';

  @override
  String get averageFitScore => 'Assessments in progress';

  @override
  String get hiringVelocity => 'Completed assessments';

  @override
  String get thisWeekChange => '+8 this week';

  @override
  String get thisMonthChange => '5 expire soon';

  @override
  String get stableTopRoles => 'Real-time activity';

  @override
  String get daysFromQuarter => '+42 this month';

  @override
  String get topMatches => 'Recent activity';

  @override
  String get viewAll => 'View All';

  @override
  String get candidate => 'Candidate';

  @override
  String get matchedRole => 'Assessment';

  @override
  String get affinity => 'Status';

  @override
  String get action => 'Action';

  @override
  String get pendingActions => 'Pending Actions';

  @override
  String get reviewRequirements => 'Results ready to review';

  @override
  String get finalApproval => 'Invitations expiring soon';

  @override
  String get scheduleInterview => 'Interrupted assessment';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusPending => 'Pending';

  @override
  String get logicalReasoningAssessment => 'Logical reasoning';

  @override
  String get decisionMakingAssessment => 'Decision making';

  @override
  String get problemSolvingAssessment => 'Problem solving';

  @override
  String get completedToday => 'Completed today';

  @override
  String get expiresTomorrow => '5 invitations expire tomorrow';

  @override
  String get connectionInterrupted => 'Recruiter follow-up required';

  @override
  String get invitationsTitle => 'Invitations';

  @override
  String get invitationsSubtitle =>
      'Enable people and track their assigned assessments.';

  @override
  String get enablePerson => 'Enable person';

  @override
  String get enablePersonSubtitle =>
      'Assign an assessment and send an access invitation.';

  @override
  String get personName => 'Person\'s name';

  @override
  String get personNameHint => 'First and last name';

  @override
  String get selectAssessment => 'Assigned assessment';

  @override
  String get invitationExpiry => 'Invitation validity';

  @override
  String daysValue(int count) {
    return '$count days';
  }

  @override
  String get optionalMessage => 'Optional message';

  @override
  String get optionalMessageHint => 'Add instructions for the person...';

  @override
  String get sendInvitation => 'Send invitation';

  @override
  String get invitationSent =>
      'The person was enabled and the invitation was created.';

  @override
  String get invitationResent =>
      'The invitation was resent and its validity was renewed.';

  @override
  String get invitationCancelled => 'The invitation was cancelled.';

  @override
  String get noInvitations => 'No people have been enabled yet';

  @override
  String get noInvitationsDescription =>
      'Enable the first person and assign an assessment.';

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get resend => 'Resend';

  @override
  String get cancelInvitation => 'Cancel invitation';

  @override
  String get confirmCancellation =>
      'Cancel this invitation? The person will lose access to the assessment.';

  @override
  String get keepInvitation => 'Keep invitation';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusInterrupted => 'Interrupted';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Manage your organization, hiring workflows, and security.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changesSaved => 'Your changes were saved successfully.';

  @override
  String get organizationProfile => 'Organization profile';

  @override
  String get organizationDescription =>
      'Information that identifies your company across TaleX.';

  @override
  String get organizationName => 'Organization name';

  @override
  String get industry => 'Industry';

  @override
  String get companySize => 'Company size';

  @override
  String get timezone => 'Time zone';

  @override
  String get timezoneBogota => 'Bogotá (UTC-5)';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsDescription =>
      'Choose which workflow updates you receive.';

  @override
  String get candidateUpdates => 'Assessment activity';

  @override
  String get candidateUpdatesDescription =>
      'Updates when an assessment starts, completes, or expires.';

  @override
  String get weeklyDigest => 'Weekly digest';

  @override
  String get weeklyDigestDescription =>
      'Pipeline metrics and activity every Monday.';

  @override
  String get securityTitle => 'Security and access';

  @override
  String get securityDescription =>
      'Protect your team\'s access to the platform.';

  @override
  String get twoFactorAuth => 'Two-factor authentication';

  @override
  String get twoFactorDescription =>
      'Require a second factor for administrator accounts.';

  @override
  String get sessionTimeout => 'Session timeout';

  @override
  String get manageMembers => 'Manage members';

  @override
  String get technologyIndustry => 'Technology';

  @override
  String get employeesRange => '51–200 employees';

  @override
  String get minutes30 => '30 minutes';

  @override
  String get adminCommandCenter => 'Command center';

  @override
  String get adminCommandSubtitle =>
      'An executive read of TaleX: operations, customers, and growth.';

  @override
  String get adminCompanies => 'Companies';

  @override
  String get adminProcesses => 'Processes';

  @override
  String get adminPeople => 'People';

  @override
  String get adminAffinity => 'Affinity';

  @override
  String get adminCommercial => 'Commercial';

  @override
  String get adminSales => 'Sales';

  @override
  String get adminCultureLeads => 'Culture leads';

  @override
  String get adminCultureLeadsSubtitle =>
      'Prospects from the /micultura landing diagnosis. No company or membership is created.';

  @override
  String get adminCultureLeadsEmpty => 'There are no culture leads yet.';

  @override
  String get cultureLeadEmployees => 'Employees';

  @override
  String get cultureLeadTraits => 'Cultural traits';

  @override
  String get cultureLeadComment => 'Comment';

  @override
  String get cultureLeadUtm => 'UTM';

  @override
  String get cultureLeadStatusNew => 'New';

  @override
  String get cultureLeadStatusContacted => 'Contacted';

  @override
  String get cultureLeadStatusQualified => 'Qualified';

  @override
  String get cultureLeadStatusDiscarded => 'Discarded';

  @override
  String get adminAnalytics => 'Analytics';

  @override
  String get adminAlerts => 'Alerts';

  @override
  String get adminXebec => 'Xebec';

  @override
  String get adminSettings => 'Settings';

  @override
  String get adminSearchHint => 'Search companies, processes, or people...';

  @override
  String get kpiTotalCompanies => 'Total companies';

  @override
  String get kpiActiveCompanies => 'Active companies';

  @override
  String get kpiEvaluatedPeople => 'People evaluated';

  @override
  String get kpiCompletedEvaluations => 'Completed assessments';

  @override
  String get kpiAffinities => 'Affinities detected';

  @override
  String get kpiPeriodSales => 'Period sales';

  @override
  String get kpiMrr => 'MRR';

  @override
  String get kpiAtRisk => 'Companies at risk';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get noActivity => 'No activity has been recorded yet.';

  @override
  String get talexFunnel => 'TaleX funnel';

  @override
  String get funnelCompanies => 'Companies';

  @override
  String get funnelProcesses => 'Processes';

  @override
  String get funnelInvited => 'People invited';

  @override
  String get funnelStarted => 'Assessments started';

  @override
  String get funnelCompleted => 'Assessments completed';

  @override
  String get funnelAffinities => 'Affinities detected';

  @override
  String get funnelDecisions => 'Results / decisions';

  @override
  String get noData => 'No data';

  @override
  String get noInformationYet => 'There is no information yet.';

  @override
  String get retry => 'Retry';

  @override
  String get newCompany => 'New company';

  @override
  String get newProcess => 'New process';

  @override
  String get newPerson => 'Register person';

  @override
  String get newDeal => 'New opportunity';

  @override
  String get newSale => 'Record sale';

  @override
  String get companyStatusActive => 'Active';

  @override
  String get companyStatusOnboarding => 'Onboarding';

  @override
  String get companyStatusInactive => 'Inactive';

  @override
  String get companyStatusAtRisk => 'At risk';

  @override
  String get companyStatusSuspended => 'Suspended';

  @override
  String get processStatusActive => 'Active';

  @override
  String get processStatusClosed => 'Closed';

  @override
  String get evaluationInvited => 'Invited';

  @override
  String get evaluationStarted => 'Started';

  @override
  String get evaluationInProgress => 'In progress';

  @override
  String get evaluationCompleted => 'Completed';

  @override
  String get evaluationAbandoned => 'Abandoned';

  @override
  String get affinityHigh => 'High affinity';

  @override
  String get affinityMedium => 'Medium affinity';

  @override
  String get affinityLow => 'Low affinity';

  @override
  String get affinityUnknown => 'Unclassified';

  @override
  String get dealProspect => 'Prospect';

  @override
  String get dealContacted => 'Contacted';

  @override
  String get dealMeeting => 'Meeting';

  @override
  String get dealProposal => 'Proposal';

  @override
  String get dealNegotiation => 'Negotiation';

  @override
  String get dealClient => 'Customer';

  @override
  String get filterAll => 'All';

  @override
  String get filterArchived => 'Archived';

  @override
  String get companyActions => 'Company actions';

  @override
  String get disableCompany => 'Disable';

  @override
  String get enableCompany => 'Re-enable';

  @override
  String get archiveCompany => 'Hide from list';

  @override
  String get restoreCompany => 'Restore to list';

  @override
  String get disableCompanyTitle => 'Disable company';

  @override
  String get disableCompanyBody =>
      'The company will stop operating in TaleX. Data is kept. Confirm?';

  @override
  String get enableCompanyTitle => 'Re-enable company';

  @override
  String get enableCompanyBody =>
      'The company will be active again and its team will be able to sign in. Confirm?';

  @override
  String get archiveCompanyTitle => 'Hide from list';

  @override
  String get archiveCompanyBody =>
      'Nothing is deleted. The company leaves the main list and moves to Archived. Confirm?';

  @override
  String get restoreCompanyTitle => 'Restore company';

  @override
  String get restoreCompanyBody =>
      'The company will show up in the main list again. Confirm?';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get noArchivedCompanies => 'There are no archived companies.';

  @override
  String get errorCompanyDisabled =>
      'This company is disabled. A SuperAdmin can re-enable it.';

  @override
  String get lastActivity => 'Last activity';

  @override
  String get joinedAt => 'Joined';

  @override
  String get openDetail => 'Open details';

  @override
  String get backToCompanies => 'Back to companies';

  @override
  String get backToPeople => 'Back to people';

  @override
  String get backToProcesses => 'Back to processes';

  @override
  String get presentedPeople => 'Already completed';

  @override
  String get pendingPeople => 'Pending';

  @override
  String get visitWebsite => 'Visit website';

  @override
  String get editCompany => 'Edit company';

  @override
  String get companyOverview => 'Overview';

  @override
  String get companyCommercial => 'Commercial';

  @override
  String get companyMetrics => 'Utilization';

  @override
  String get noCompanies => 'There are no companies in TaleX yet.';

  @override
  String get noProcesses => 'There are no processes to show.';

  @override
  String get noPeople =>
      'There are no evaluated people to show. Sensitive answers are not exposed.';

  @override
  String get noDeals => 'There are no opportunities in the pipeline.';

  @override
  String get noSales => 'There are no sales recorded in this period.';

  @override
  String get noAlerts => 'There are no alerts calculated from current data.';

  @override
  String get period7 => '7 days';

  @override
  String get period30 => '30 days';

  @override
  String get period90 => '90 days';

  @override
  String get period12m => '12 months';

  @override
  String get completionRate => 'Completion rate';

  @override
  String get suggestedAction => 'Suggested action';

  @override
  String get xebecSubtitle =>
      'Xebec answers with the real command-center context.';

  @override
  String get xebecPlaceholder => 'How is TaleX doing?';

  @override
  String get xebecEmpty =>
      'Ask about TaleX health, companies at risk, or opportunities. Xebec uses real metrics, not guesses.';

  @override
  String get askXebec => 'Ask';

  @override
  String get adminSettingsSubtitle =>
      'Users, roles, and real system parameters. Nothing fictional.';

  @override
  String get superAdminHelp =>
      'SuperAdmin is granted if the email is listed in config/superadmin.emails or the user document already has role=superadmin. Credentials live in Firebase Auth; change them with password reset or the console.';

  @override
  String get adminUsers => 'Users';

  @override
  String get roleLabel => 'Role';

  @override
  String get adminSaved => 'Changes were saved in TaleX.';

  @override
  String get amount => 'Amount';

  @override
  String get plan => 'Plan';

  @override
  String get owner => 'Owner';

  @override
  String get nextAction => 'Next action';

  @override
  String get product => 'Product or service';

  @override
  String get recurring => 'Recurring (MRR)';

  @override
  String get estimatedValue => 'Estimated value';

  @override
  String get affinityScore => 'Affinity score (0-100)';

  @override
  String get statusLabel => 'Status';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get alertRisk => 'Risk';

  @override
  String get alertOperational => 'Operational';

  @override
  String get alertCommercial => 'Commercial';

  @override
  String get alertProduct => 'Product';

  @override
  String get alertOpportunity => 'Opportunity';

  @override
  String get salesPeriod => 'Period sales';

  @override
  String get salesCumulative => 'Cumulative sales';

  @override
  String get newCustomers => 'Customers in period';

  @override
  String get averageTicket => 'Average ticket';

  @override
  String get growth => 'Growth vs previous period';

  @override
  String get activityByDay => 'Activity by day';

  @override
  String get language => 'Language';

  @override
  String get languageDescription =>
      'Choose the interface language. The change applies immediately.';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get vacancy => 'Vacancy';

  @override
  String get createVacancy => 'Create vacancy';

  @override
  String get createRespondent => 'Create respondent';

  @override
  String get activationPin => 'Activation PIN';

  @override
  String pinGenerated(String pin) {
    return 'Company created. First-access PIN: $pin.';
  }

  @override
  String invitePinReady(String pin) {
    return 'First-access PIN: $pin.';
  }

  @override
  String get nit => 'Tax ID';

  @override
  String get sector => 'Sector';

  @override
  String get city => 'City';

  @override
  String get website => 'Website';

  @override
  String get logoUrl => 'Logo URL';

  @override
  String get description => 'Description';

  @override
  String get companyDna => 'Company DNA';

  @override
  String get companyValues => 'Values';

  @override
  String get companyCulture => 'Culture';

  @override
  String get standoutPeople => 'What stands out about your people?';

  @override
  String get skipCompanyDna =>
      'Skip company DNA for now. The organization can complete it later.';

  @override
  String get country => 'Country';

  @override
  String get department => 'Department';

  @override
  String get divisionState => 'State';

  @override
  String get divisionCommunity => 'Autonomous community';

  @override
  String get divisionRegion => 'State / region';

  @override
  String get cityMunicipality => 'City / municipality';

  @override
  String get searchLocation => 'Type to search...';

  @override
  String get searchCountry => 'Search country...';

  @override
  String get searchDivision => 'Search division...';

  @override
  String get searchCity => 'Search city...';

  @override
  String get locationLoadError => 'We could not load locations. Try again.';

  @override
  String get locationNoResults => 'No results for that search.';

  @override
  String get locationSelectCountryFirst => 'Select a country first';

  @override
  String get provisionStepCompany => 'Company';

  @override
  String get provisionStepDna => 'DNA';

  @override
  String get provisionStepInvite => 'Invite';

  @override
  String get pasteLogoUrl => 'Paste logo URL';

  @override
  String get selectLogoFile => 'Select file';

  @override
  String get logoPreview => 'Logo preview';

  @override
  String get sectorFinance => 'Finance';

  @override
  String get sectorHealth => 'Healthcare';

  @override
  String get sectorEducation => 'Education';

  @override
  String get sectorManufacturing => 'Manufacturing';

  @override
  String get sectorRetail => 'Retail';

  @override
  String get sectorServices => 'Services';

  @override
  String get sectorConstruction => 'Construction';

  @override
  String get sectorEnergy => 'Energy';

  @override
  String get sectorAgribusiness => 'Agribusiness';

  @override
  String get sectorGovernment => 'Government';

  @override
  String get sectorOther => 'Other';

  @override
  String get size1to10 => '1–10 employees';

  @override
  String get size11to50 => '11–50 employees';

  @override
  String get size201to500 => '201–500 employees';

  @override
  String get size500plus => 'More than 500 employees';

  @override
  String get emailSent => 'The invitation email was sent.';

  @override
  String get errorEmailNotConfigured =>
      'The company was created, but SMTP is not configured yet. The PIN is shown on screen.';

  @override
  String get errorEmailSendFailed =>
      'The company was created, but the email could not be sent. Check spam or SMTP settings. The PIN is shown on screen.';

  @override
  String get completeCompanyDnaTitle => 'Complete the company DNA';

  @override
  String get completeCompanyDnaSubtitle =>
      'Before entering the workspace, record the values, culture, and what stands out about the people.';

  @override
  String get reviewCompanyDnaTitle => 'Verify the company DNA';

  @override
  String get reviewCompanyDnaSubtitle =>
      'Check that these details describe the organization well. If something is off, correct it before continuing.';

  @override
  String get confirmCompanyDna => 'Confirm and continue';

  @override
  String get dnaRequired =>
      'Fill in values, culture, and what stands out about the people.';

  @override
  String get soughtCharacteristics => 'Sought characteristics';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get activateAccount => 'Activate account';

  @override
  String get activateSubtitle =>
      'Use the invited email and the 6-digit PIN sent to that inbox. The PIN expires after 15 minutes.';

  @override
  String get activatePinHint =>
      '6 digits · valid for 15 minutes. Use the PIN from the latest email, not from an earlier test.';

  @override
  String get mustChangePasswordTitle => 'Create your password';

  @override
  String get mustChangePasswordSubtitle =>
      'This is the password you will use from now on to sign in to TaleX.';

  @override
  String get createPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'The passwords do not match.';

  @override
  String get documentNumber => 'Document number';

  @override
  String get activeVacancies => 'Active vacancies';

  @override
  String get closedVacancies => 'Closed vacancies';

  @override
  String get pendingAssessments => 'Pending assessments';

  @override
  String get completedAssessments => 'Completed assessments';

  @override
  String get noVacancies => 'You don\'t have any vacancies yet.';

  @override
  String get noCandidates => 'There are no respondents in this process yet.';

  @override
  String get noTeamMembers => 'There is no one on the team yet.';

  @override
  String get affinityWithCompany => 'Affinity with the company';

  @override
  String get affinityWithVacancy => 'Affinity with the vacancy';

  @override
  String get likertStronglyDisagree => 'Strongly disagree';

  @override
  String get likertDisagree => 'Disagree';

  @override
  String get likertNeutral => 'Neither agree nor disagree';

  @override
  String get likertAgree => 'Agree';

  @override
  String get likertStronglyAgree => 'Strongly agree';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get next => 'Next';

  @override
  String get goBack => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String get basicResult => 'Basic result';

  @override
  String get fullResultLocked =>
      'The full result will be available when access is enabled.';

  @override
  String get compare => 'Compare';

  @override
  String get characteristic => 'Characteristic';

  @override
  String get team => 'Team';

  @override
  String get inviteRecruiter => 'Invite to the team';

  @override
  String get inviteTeamSubtitle =>
      'The person will receive a 6-digit PIN by email. It expires after 15 minutes.';

  @override
  String get teamRole => 'Role in the company';

  @override
  String get teamRoleCompanyAdmin => 'CEO';

  @override
  String get teamRoleCompanyLead => 'Administrator';

  @override
  String get teamRolePeopleOps => 'Human resources';

  @override
  String get teamRoleRecruiter => 'Recruiting';

  @override
  String get teamRoleHiringManager => 'Technical lead';

  @override
  String get teamRoleHint =>
      'The CEO and the administrator can invite the rest of the team. Human resources, recruiting, and the technical lead work on vacancies and candidates.';

  @override
  String get vacanciesSubtitle =>
      'Create vacancies and add context for the process. Vacancy location does not change the company profile.';

  @override
  String get teamSubtitle => 'People with TaleX access in your company.';

  @override
  String get workModeOnsite => 'On-site';

  @override
  String get workModeRemote => 'Remote';

  @override
  String get workModeHybrid => 'Hybrid';

  @override
  String get workModeHint =>
      'If remote, city is optional. If on-site or hybrid, start from the company location and change it only for this vacancy.';

  @override
  String get vacancyCityOptional => 'Reference city (optional)';

  @override
  String get seniorityHint =>
      'Expected experience for the role. It is not used in affinity scoring.';

  @override
  String get seniorityJunior => 'Entry-level';

  @override
  String get seniorityMid => 'Intermediate';

  @override
  String get senioritySenior => 'Experienced';

  @override
  String get seniorityLead => 'Leadership';

  @override
  String get contractIndefinite => 'Open-ended';

  @override
  String get contractFixed => 'Fixed term';

  @override
  String get contractServices => 'Independent contractor';

  @override
  String get contractInternship => 'Internship';

  @override
  String get contractTemporary => 'Temporary';

  @override
  String get areaPeople => 'People and culture';

  @override
  String get areaFinanceOps => 'Finance';

  @override
  String get areaOperations => 'Operations';

  @override
  String get areaCommercial => 'Sales';

  @override
  String get areaCustomer => 'Customer care';

  @override
  String get areaAdmin => 'Administration';

  @override
  String get areaEngineering => 'Engineering';

  @override
  String get areaProduct => 'Product';

  @override
  String get areaData => 'Data and analytics';

  @override
  String get areaSupport => 'Support';

  @override
  String get areaRisk => 'Risk and compliance';

  @override
  String get areaAccounting => 'Accounting';

  @override
  String get areaClinical => 'Clinical';

  @override
  String get areaCare => 'Care';

  @override
  String get areaAcademic => 'Academic';

  @override
  String get areaTraining => 'Training';

  @override
  String get areaProduction => 'Production';

  @override
  String get areaQuality => 'Quality';

  @override
  String get areaMaintenance => 'Maintenance';

  @override
  String get areaStore => 'Store';

  @override
  String get areaLogistics => 'Logistics';

  @override
  String get areaProjects => 'Projects';

  @override
  String get areaField => 'Field';

  @override
  String get areaPublicService => 'Public service';

  @override
  String get vacancyAreaHint =>
      'Areas follow the company sector. Pick the closest match for the role.';

  @override
  String get invitationUsed => 'Activated';

  @override
  String get invitationPending => 'Invitation pending';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusShortlisted => 'Shortlisted';

  @override
  String get statusInterview => 'Interview';

  @override
  String get statusFinalist => 'Finalist';

  @override
  String get statusHired => 'Hired';

  @override
  String get statusRejected => 'Not selected';

  @override
  String get vacancyName => 'Vacancy name';

  @override
  String get vacancyArea => 'Area';

  @override
  String get workMode => 'Work mode';

  @override
  String get contractType => 'Contract type';

  @override
  String get seniority => 'Seniority';

  @override
  String get roleProfile => 'Role profile';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get companyProfile => 'Company profile';

  @override
  String get vacancyInsights => 'Vacancy reading';

  @override
  String get vacancyInsightsEmpty =>
      'There is not enough information yet to show a reading for this vacancy.';

  @override
  String vacancyInsightsCounts(int invited, int started, int completed) {
    return '$invited invited · $started in progress · $completed completed the assessment.';
  }

  @override
  String get dnaSelectSeveral =>
      'You can choose several options. If you add one that was not in the list, you can also remove it.';

  @override
  String get removeCustomOption => 'Remove this option';

  @override
  String get results => 'Results';

  @override
  String get resultsSubtitle =>
      'Affinity reading for people who already completed an assessment. Detail will appear here when the methodology fills the profile.';

  @override
  String get compareHint =>
      'The checkbox on the left lets you pick two or more people and use Compare. It does not change process status.';

  @override
  String get affinityCompany => 'Company';

  @override
  String get affinityVacancy => 'Vacancy';

  @override
  String get affinityUnknownHint =>
      'There is no complete assessment yet, so affinity is not classified.';

  @override
  String get affinityMockNote =>
      'AI-generated analysis based on the survey, which is the same for every company. It is supporting information: TaleX does not make hiring decisions or rule people out. The final decision belongs to your team.';

  @override
  String get affinityAnalysisNone =>
      'This assessment does not have an affinity analysis yet.';

  @override
  String get affinityAnalysisPending =>
      'We are analyzing the survey answers. This may take a few seconds.';

  @override
  String get affinityAnalysisFailed =>
      'We could not complete the affinity analysis right now. You can try again.';

  @override
  String get affinityAnalysisMissingDna =>
      'There is not enough survey information yet to complete the analysis.';

  @override
  String get affinityAnalysisIncompleteAnswers =>
      'The assessment does not have enough answers to analyze affinity.';

  @override
  String get affinityAnalyzeAction => 'Analyze affinity';

  @override
  String get affinityReanalyzeAction => 'Analyze again';

  @override
  String get affinityAlignmentsTitle => 'Where there is affinity';

  @override
  String get affinityDifferencesTitle =>
      'Aspects that could make adaptation harder';

  @override
  String get affinityTopicsTitle => 'Topics to discuss in the interview';

  @override
  String get affinityGuidanceTitle => 'Guidance for Human Resources';

  @override
  String get affinityDataGapsTitle => 'Missing information';

  @override
  String affinityScoreValue(int score) {
    return 'Score $score/100';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get respondentWelcomeTitle => 'I want to get to know you';

  @override
  String get respondentWelcomeBody =>
      'Hi. I am TaleXito. This survey is the same for every company. I receive your answers so we can understand how you like to work. I do not decide the result: a specialist will share it with you later.';

  @override
  String get respondentWelcomeAction => 'OK';

  @override
  String respondentHello(String name) {
    return 'Hi, $name';
  }

  @override
  String get respondentHomeTitle => 'Your affinity assessment';

  @override
  String get respondentHomeSubtitle =>
      'TaleX does not decide who gets hired. It measures how close you are to the profile the company described for this vacancy.';

  @override
  String get respondentDuration =>
      'Set aside about 40 minutes in a quiet place. You can go at your own pace.';

  @override
  String get respondentLikertHint =>
      'Most questions show two statements, one on each side. Pick the box closest to the one that describes you best. There are no right or wrong answers.';

  @override
  String get startAssessment => 'Start assessment';

  @override
  String get assignedVacancy => 'Assigned vacancy';

  @override
  String get viewFullSummary => 'View orientative summary';

  @override
  String get hideFullSummary => 'Hide summary';

  @override
  String get fullSummaryTitle => 'Orientative summary';

  @override
  String get fullSummaryIntro =>
      'This screen is a mock of the reading. The dimensions below are examples until TaleX delivers the real detail.';

  @override
  String get dimensionCommunication => 'Communication';

  @override
  String get dimensionAdaptability => 'Adaptability';

  @override
  String get dimensionCollaboration => 'Collaboration';

  @override
  String get dimensionInitiative => 'Initiative';

  @override
  String get veryHigh => 'Very high';

  @override
  String get resultThanks =>
      'Thank you for completing the assessment. The company will be able to see your affinity with its culture and with this vacancy.';

  @override
  String get newAssessment => 'New assessment';

  @override
  String get pendingAssessmentNotification => 'You have a pending assessment.';

  @override
  String get assessmentCompletedNotification => 'The assessment was completed.';

  @override
  String get newVacancyNotification => 'A new vacancy was created.';

  @override
  String get newActivityNotification => 'There is new activity in TaleX.';

  @override
  String get errorNeedSignIn => 'You need to sign in.';

  @override
  String get errorNeedAuthEmail => 'You need an authenticated email.';

  @override
  String get errorPermissionDenied =>
      'You don\'t have permission for this operation.';

  @override
  String get errorUnexpected =>
      'The operation could not be completed. Please try again.';

  @override
  String get errorApiUnavailable =>
      'TaleX is unavailable. You cannot sign in until the API responds.';

  @override
  String get errorCompanyNotFound => 'The company was not found.';

  @override
  String get errorRespondentExists =>
      'A respondent with this email already exists for this vacancy.';

  @override
  String get errorInviteMissing => 'There is no invitation for this email.';

  @override
  String get errorInviteUsed => 'This invitation has already been used.';

  @override
  String get errorInviteInvalid => 'This invitation link is not valid.';

  @override
  String get errorInviteExpired =>
      'This invitation link expired. Ask for a new invitation.';

  @override
  String get errorInvalidPin => 'The PIN is not valid.';

  @override
  String get errorPinExpired =>
      'The PIN expired. Ask for a new invitation; it lasts 15 minutes.';

  @override
  String get errorDocumentMismatch =>
      'The document does not match the invitation.';

  @override
  String get errorAssessmentMissing => 'There is no assessment assigned.';

  @override
  String get errorDocumentPasswordTooShort =>
      'The document number must have at least 6 characters to be used as the password.';

  @override
  String get registerPinHint => '6-digit PIN from the email';

  @override
  String get googlePinTitle => 'Enter the PIN from your email';

  @override
  String get googlePinSubtitle =>
      'Your Google account is ready. Confirm the 6-digit PIN to link the invitation.';

  @override
  String addCustomOption(String value) {
    return 'Add \"$value\"';
  }

  @override
  String get searchOrAdd => 'Type to search or add...';

  @override
  String get customAreaLabel => 'Area name';

  @override
  String get areaOther => 'Other';

  @override
  String get dnaValueIntegrity => 'Integrity';

  @override
  String get dnaValueRespect => 'Respect';

  @override
  String get dnaValueCollaboration => 'Collaboration';

  @override
  String get dnaValueInnovation => 'Innovation';

  @override
  String get dnaValueExcellence => 'Excellence';

  @override
  String get dnaValueEmpathy => 'Empathy';

  @override
  String get dnaCultureClose => 'Close and human';

  @override
  String get dnaCultureFormal => 'Formal and structured';

  @override
  String get dnaCultureLearning => 'Continuous learning';

  @override
  String get dnaCultureAgile => 'Agile';

  @override
  String get dnaCultureAutonomous => 'Autonomous';

  @override
  String get dnaStandoutOwnership => 'Ownership';

  @override
  String get dnaStandoutCommunication => 'Clear communication';

  @override
  String get dnaStandoutAdaptability => 'Adaptability';

  @override
  String get dnaStandoutInitiative => 'Initiative';

  @override
  String get dnaStandoutTeamwork => 'Teamwork';

  @override
  String get assessmentKindLabel => 'This is your assessment';

  @override
  String get assessmentKindAffinity => 'Affinity';

  @override
  String get assessmentKindFit => 'Fit';

  @override
  String get sentByCompany => 'Sent by';

  @override
  String respondentQuestionCount(int count) {
    return 'There are $count questions in total.';
  }

  @override
  String get assessmentFinishedTitle => 'TaleXito has your answers';

  @override
  String get assessmentFinishedBody =>
      'TaleXito receives the information. It does not decide the result. A specialist will tell you later.';

  @override
  String get surveyResultRequest => 'I want to know my results';

  @override
  String get surveyResultRequested =>
      'Thanks for letting us know. The result takes a little while. A specialist takes care of it.';

  @override
  String get companyProfileSubtitle => 'General company details.';

  @override
  String get downloadPdf => 'Download PDF report';

  @override
  String get candidateResultTitle => 'Results report';

  @override
  String get editCandidate => 'Edit candidate';

  @override
  String get deleteCandidate => 'Delete candidate';

  @override
  String deleteCandidateConfirm(String name) {
    return 'Delete $name? Their answers will be removed and their invitation link will stop working. This cannot be undone.';
  }

  @override
  String get deleteAction => 'Delete';

  @override
  String get candidateUpdated => 'Candidate updated.';

  @override
  String get candidateDeleted => 'Candidate deleted.';

  @override
  String get backToResults => 'Back';

  @override
  String get candidatesSubtitle =>
      'People invited to assess affinity with your vacancies.';

  @override
  String get candidateProcessStatus => 'Process status';

  @override
  String get respondentInviteHint =>
      'The person will receive an email with a link to take the assessment right away. When they finish, you will see the status and result here.';

  @override
  String get firstAccessCompany => 'First access';

  @override
  String get assessmentSignInHint =>
      'If you were invited to an assessment, use the link in the email to start. You do not need to register with a PIN.';

  @override
  String get respondentInviteSent =>
      'Invitation ready. The candidate receives an email link to take the assessment.';

  @override
  String get recoverPasswordTitle => 'Recover access';

  @override
  String get recoverPasswordSubtitle =>
      'Enter the email of your TaleX account. We will send a 6-digit PIN so you can continue.';

  @override
  String get recoverContinue => 'Send PIN';

  @override
  String get recoverPinTitle => 'Check your email';

  @override
  String get recoverPinSubtitle =>
      'We sent you a PIN. Enter it to update your password.';

  @override
  String get recoverPinHint =>
      '6 digits · valid for 15 minutes. Check spam too. If you did not request this, ignore the message.';

  @override
  String get recoverPinSent => 'We sent a PIN to your email.';

  @override
  String get recoverVerifyPin => 'Verify PIN';

  @override
  String get recoverResendPin => 'Resend PIN';

  @override
  String get recoverUpdatePassword => 'Update password';

  @override
  String get recoverSuccessTitle => 'Password updated';

  @override
  String get recoverSuccessBody =>
      'You can now sign in to TaleX with your new password.';

  @override
  String get errorResetCooldown =>
      'Wait a minute before requesting another PIN.';

  @override
  String get errorResetTooManyAttempts =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String dashboardReadyToReview(int count) {
    return '$count assessments ready to review';
  }

  @override
  String dashboardPendingToStart(int count) {
    return '$count people have not started the assessment yet';
  }

  @override
  String dashboardStalledAssessments(int count) {
    return '$count assessments stalled for more than 24 h';
  }

  @override
  String get dashboardRecentEmpty =>
      'There is no respondent activity in this workspace yet.';

  @override
  String get dashboardAlertsEmpty => 'There are no pending alerts right now.';

  @override
  String get errorAccountNotFound =>
      'There is no TaleX account with this email. If you were invited, use First access with the PIN.';

  @override
  String get adminQuestions => 'Affinity survey';

  @override
  String get adminQuestionsSubtitle =>
      'Questions the candidate answers. You can view, edit, and update them.';

  @override
  String get adminCultureSurvey => 'Culture survey';

  @override
  String get adminCultureSurveySubtitle =>
      'Company values and culture form. Upload the file once; after that you only edit.';

  @override
  String get adminCultureSurveyEmpty =>
      'There are no culture questions yet. Upload a CSV or JSON file to add them.';

  @override
  String get adminQuestionsUploadFile => 'Upload file';

  @override
  String get adminQuestionsFrontCultura => 'Lived culture';

  @override
  String get adminQuestionsFrontLiderazgo => 'Leadership';

  @override
  String get adminQuestionsFrontTrabajo => 'Way of working';

  @override
  String get adminQuestionsFrontPersonas => 'People';

  @override
  String get adminQuestionsFrontApertura => 'Open comments';

  @override
  String get adminQuestionsFormatScale => 'Scale';

  @override
  String get adminQuestionsFormatText => 'Open text';

  @override
  String get adminQuestionsFormatSingle => 'Single choice';

  @override
  String get adminQuestionsFormatMulti => 'Multiple choice';

  @override
  String get adminQuestionsNew => 'New question';

  @override
  String get adminQuestionsEdit => 'Edit question';

  @override
  String get adminQuestionsPreview => 'Preview';

  @override
  String get adminQuestionsPreviewTitle => 'Survey preview';

  @override
  String get adminQuestionsPreviewNote => 'Simulation: answers are not saved.';

  @override
  String get adminQuestionsPreviewEmpty =>
      'There are no active questions to show.';

  @override
  String get adminQuestionsEmpty => 'There are no questions in Firebase yet.';

  @override
  String adminQuestionsSeed(int count) {
    return 'Load the $count base questions';
  }

  @override
  String get adminQuestionsNoResults => 'No question matches the filter.';

  @override
  String get adminQuestionsSearch =>
      'Search by code, dimension or statement...';

  @override
  String get adminQuestionsAll => 'All';

  @override
  String adminQuestionsSummary(int active, int total) {
    return '$active active of $total';
  }

  @override
  String get adminQuestionsFrontValues => '1 · Values';

  @override
  String get adminQuestionsFrontNeeds => '2 · Needs';

  @override
  String get adminQuestionsFrontCapabilities => '3 · Capabilities';

  @override
  String get adminQuestionsFormatPair => 'Statement pair';

  @override
  String get adminQuestionsFormatExperience => 'Experience statement';

  @override
  String get adminQuestionsCode => 'Code';

  @override
  String get adminQuestionsFront => 'Front';

  @override
  String get adminQuestionsFormat => 'Format';

  @override
  String get adminQuestionsDimension => 'Dimension';

  @override
  String get adminQuestionsDimensionA => 'Dimension A';

  @override
  String get adminQuestionsDimensionB => 'Dimension B';

  @override
  String get adminQuestionsInstruction => 'Instruction';

  @override
  String get adminQuestionsStatement => 'Statement';

  @override
  String get adminQuestionsStatementA => 'Statement A';

  @override
  String get adminQuestionsStatementB => 'Statement B';

  @override
  String adminQuestionsOption(int number) {
    return 'Option $number';
  }

  @override
  String get adminQuestionsTimeLimit => 'Time limit (seconds)';

  @override
  String get adminQuestionsTimeLimitHint => 'Empty = no limit';

  @override
  String get adminQuestionsNoLimit => 'No limit';

  @override
  String adminQuestionsSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminQuestionsActive => 'Active';

  @override
  String get adminQuestionsInactive => 'Inactive';

  @override
  String get adminQuestionsRequired => 'This field is required.';

  @override
  String get adminQuestionsCodeTaken =>
      'A question with this code already exists.';

  @override
  String get adminQuestionsInvalidTime =>
      'Enter a whole number greater than zero.';

  @override
  String get adminQuestionsDeleteTitle => 'Delete question';

  @override
  String adminQuestionsDeleteBody(String code) {
    return '$code will be deleted from Firebase. This action cannot be undone.';
  }

  @override
  String get adminQuestionsDelete => 'Delete';

  @override
  String get adminQuestionsMoveUp => 'Move up';

  @override
  String get adminQuestionsMoveDown => 'Move down';

  @override
  String get adminQuestionsError =>
      'The operation could not be completed in Firebase.';

  @override
  String get adminQuestionsRestart => 'Restart';

  @override
  String get adminQuestionsDeviceMobile => 'Mobile';

  @override
  String get adminQuestionsDeviceDesktop => 'Desktop';

  @override
  String get adminQuestionsTimeUp => 'Time is up';

  @override
  String get assessmentPairInstruction =>
      'Which of the two statements describes you better?';

  @override
  String get assessmentNeedInstruction =>
      'If you had to choose, which of the two matters more to you in a job?';

  @override
  String get assessmentExperienceInstruction =>
      'Thinking about your jobs or projects over the last three years, how often has the following happened to you?';

  @override
  String get assessmentPairScaleHint =>
      'Tap the box closest to the statement you identify with.';

  @override
  String get assessmentStatementA => 'Statement A';

  @override
  String get assessmentStatementB => 'Statement B';

  @override
  String get pairScale1 => 'Clearly A';

  @override
  String get pairScale2 => 'More A than B';

  @override
  String get pairScale3 => 'Both equally';

  @override
  String get pairScale4 => 'More B than A';

  @override
  String get pairScale5 => 'Clearly B';

  @override
  String get frequencyScale1 => 'Never';

  @override
  String get frequencyScale2 => 'Rarely';

  @override
  String get frequencyScale3 => 'Sometimes';

  @override
  String get frequencyScale4 => 'Often';

  @override
  String get frequencyScale5 => 'Always';

  @override
  String get adminRoleSuperadmin => 'Superadmin';

  @override
  String get adminRoleSuperadminHelp => 'Full access to the TaleX admin panel.';

  @override
  String get adminRoleUser => 'User';

  @override
  String get adminRoleUserHelp => 'Standard access, without the admin panel.';

  @override
  String get adminRoleChange => 'Change role';

  @override
  String get adminQuestionsImport => 'Import CSV';

  @override
  String get adminQuestionsImportTitle => 'Import questions';

  @override
  String adminQuestionsImportBody(int total, int created, int replaced) {
    return 'The file has $total questions: $created new and $replaced replacing existing ones with the same code.';
  }

  @override
  String get adminQuestionsImportAction => 'Import';

  @override
  String get adminQuestionsCsvUnreadable =>
      'The file could not be read. It must be a CSV.';

  @override
  String get adminQuestionsCsvEmpty => 'The file has no questions.';

  @override
  String adminQuestionsCsvMissingColumns(String columns) {
    return 'The CSV is missing required columns: $columns.';
  }

  @override
  String adminQuestionsCsvInvalidRow(int row) {
    return 'Row $row: the code or statement A is missing.';
  }

  @override
  String adminQuestionsCsvDuplicate(int row, String code) {
    return 'Row $row: code $code is repeated in the file.';
  }

  @override
  String get adminQuestionsDeleteAll => 'Delete all';

  @override
  String get adminQuestionsDeleteAllTitle => 'Delete all questions';

  @override
  String adminQuestionsDeleteAllBody(int count) {
    return 'All $count questions will be deleted from Firebase. This action cannot be undone.';
  }

  @override
  String get adminQuestionsUploading => 'Loading questions…';

  @override
  String get adminQuestionsDeleting => 'Deleting questions…';

  @override
  String adminQuestionsUploaded(int count) {
    return '$count questions loaded into TaleX.';
  }

  @override
  String get adminQuestionsDeletedAll => 'All questions were deleted.';
}
