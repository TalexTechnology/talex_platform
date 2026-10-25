import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

String talentErrorMessage(AppLocalizations l10n, String code) => switch (code) {
  TalentErrorCodes.needSignIn => l10n.errorNeedSignIn,
  TalentErrorCodes.apiUnavailable => l10n.errorApiUnavailable,
  TalentErrorCodes.needAuthEmail => l10n.errorNeedAuthEmail,
  TalentErrorCodes.permissionDenied => l10n.errorPermissionDenied,
  TalentErrorCodes.companyNotFound => l10n.errorCompanyNotFound,
  TalentErrorCodes.respondentExists => l10n.errorRespondentExists,
  TalentErrorCodes.inviteMissing => l10n.errorInviteMissing,
  TalentErrorCodes.inviteUsed => l10n.errorInviteUsed,
  TalentErrorCodes.inviteInvalid => l10n.errorInviteInvalid,
  TalentErrorCodes.inviteExpired => l10n.errorInviteExpired,
  TalentErrorCodes.invalidPin => l10n.errorInvalidPin,
  TalentErrorCodes.pinExpired => l10n.errorPinExpired,
  TalentErrorCodes.documentMismatch => l10n.errorDocumentMismatch,
  TalentErrorCodes.assessmentMissing => l10n.errorAssessmentMissing,
  TalentErrorCodes.documentPasswordTooShort => l10n.errorDocumentPasswordTooShort,
  TalentErrorCodes.emailNotConfigured => l10n.errorEmailNotConfigured,
  TalentErrorCodes.emailSendFailed => l10n.errorEmailSendFailed,
  TalentErrorCodes.companyDisabled => l10n.errorCompanyDisabled,
  TalentErrorCodes.resetCooldown => l10n.errorResetCooldown,
  TalentErrorCodes.resetTooManyAttempts => l10n.errorResetTooManyAttempts,
  TalentErrorCodes.passwordTooShort => l10n.passwordLengthError,
  TalentErrorCodes.accountNotFound => l10n.errorAccountNotFound,
  _ => l10n.errorUnexpected,
};
