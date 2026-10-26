import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
import 'package:talex_platform/features/invitations/domain/entities/invitation.dart';
import 'package:talex_platform/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:talex_platform/l10n/l10n.dart';

class InvitationsView extends StatelessWidget {
  const InvitationsView({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<InvitationBloc, InvitationState>(
        listenWhen: (previous, current) =>
            previous.operation != current.operation ||
            previous.failure != current.failure,
        listener: (context, state) {
          final message =
              state.failure?.message ??
              switch (state.operation) {
                InvitationOperation.created => context.l10n.invitationSent,
                InvitationOperation.resent => context.l10n.invitationResent,
                InvitationOperation.cancelled =>
                  context.l10n.invitationCancelled,
                null => null,
              };
          if (message != null) {
            final notifications = getIt<NotificationService>();
            state.failure == null
                ? notifications.success(message)
                : notifications.error(message);
          }
        },
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 18 : 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TalexPageHeader(
                        eyebrow: context.l10n.roles,
                        title: context.l10n.invitationsTitle,
                        subtitle: context.l10n.invitationsSubtitle,
                        actions: [
                          FilledButton.icon(
                            onPressed: onCreate,
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(context.l10n.enablePerson),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (state.status == InvitationViewStatus.loading)
                        const Skeleton(
                          child: SkeletonList(count: 4, separate: true),
                        )
                      else if (state.invitations.isEmpty)
                        _EmptyInvitations(onCreate: onCreate)
                      else
                        ...state.invitations.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _InvitationCard(invitation: item),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _EmptyInvitations extends StatelessWidget {
  const _EmptyInvitations({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => TalexPanel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
    child: Column(
      children: [
        const TalexIconBadge(Icons.mark_email_unread_outlined, size: 56),
        const SizedBox(height: 20),
        Text(
          context.l10n.noInvitations,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            context.l10n.noInvitationsDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.l10n.enablePerson),
        ),
      ],
    ),
  );
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation});
  final Invitation invitation;
  String _status(BuildContext context) => switch (invitation.status) {
    InvitationStatus.pending => context.l10n.statusPending,
    InvitationStatus.inProgress => context.l10n.statusInProgress,
    InvitationStatus.completed => context.l10n.statusCompleted,
    InvitationStatus.expired => context.l10n.statusExpired,
    InvitationStatus.cancelled => context.l10n.statusCancelled,
    InvitationStatus.interrupted => context.l10n.statusInterrupted,
  };
  @override
  Widget build(BuildContext context) {
    final disabled =
        invitation.status == InvitationStatus.cancelled ||
        invitation.status == InvitationStatus.completed;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tone = switch (invitation.status) {
      InvitationStatus.completed => TalexTone.green,
      InvitationStatus.inProgress => TalexTone.blue,
      InvitationStatus.pending => TalexTone.blue,
      InvitationStatus.interrupted => TalexTone.warning,
      InvitationStatus.expired => TalexTone.neutral,
      InvitationStatus.cancelled => TalexTone.danger,
    };
    return TalexPanel(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 52,
            child: CircleAvatar(
              backgroundColor: AppColors.greenDim,
              child: Text(
                invitation.personName.isEmpty
                    ? '?'
                    : invitation.personName[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.personName,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invitation.email,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.assessmentName,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.expiresOn(
                    DateFormat.yMMMd(locale).format(invitation.expiresAt),
                  ),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TalexPill(_status(context), tone: tone),
          const SizedBox(width: 12),
          if (!disabled) ...[
            TextButton.icon(
              onPressed: () => context.read<InvitationBloc>().add(
                InvitationResent(invitation.id),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.resend),
            ),
            IconButton(
              tooltip: context.l10n.cancelInvitation,
              onPressed: () => _confirmCancel(context),
              icon: Icon(Icons.block_outlined, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.cancelInvitation),
        content: Text(context.l10n.confirmCancellation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.keepInvitation),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.bg,
            ),
            child: Text(context.l10n.cancelInvitation),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<InvitationBloc>().add(InvitationCancelled(invitation.id));
    }
  }
}
