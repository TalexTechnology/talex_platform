import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 18,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.invitationsTitle,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: compact ? 34 : 42,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.invitationsSubtitle,
                                style: const TextStyle(
                                  color: AppColors.subtitle,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: onCreate,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryButton,
                            ),
                            icon: const Icon(Icons.person_add_alt_1),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.softBorder),
      borderRadius: AppRadii.border,
    ),
    child: Column(
      children: [
        const Icon(
          Icons.mark_email_unread_outlined,
          size: 48,
          color: AppColors.dashboardAccent,
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.noInvitations,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.noInvitationsDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.subtitle),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onCreate,
          child: Text(context.l10n.enablePerson),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D1D6)),
        borderRadius: AppRadii.border,
      ),
      child: Wrap(
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 52,
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF0EFFF),
              child: Text(
                invitation.personName.isEmpty
                    ? '?'
                    : invitation.personName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.dashboardAccent,
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
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invitation.email,
                  style: const TextStyle(color: AppColors.subtitle),
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
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.expiresOn(
                    DateFormat.yMMMd(locale).format(invitation.expiresAt),
                  ),
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: AppRadii.border,
            ),
            child: Text(
              _status(context),
              style: const TextStyle(
                color: AppColors.dashboardAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
              icon: const Icon(Icons.block_outlined, color: Colors.redAccent),
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
