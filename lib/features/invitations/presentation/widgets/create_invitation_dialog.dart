import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:talex_platform/l10n/l10n.dart';

class CreateInvitationDialog extends StatefulWidget {
  const CreateInvitationDialog({super.key});
  @override
  State<CreateInvitationDialog> createState() => _CreateInvitationDialogState();
}

class _CreateInvitationDialogState extends State<CreateInvitationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  int _days = 7;
  int _assessmentIndex = 0;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final assessments = _assessments(context);
    context.read<InvitationBloc>().add(
      InvitationCreated(
        personName: _name.text.trim(),
        email: _email.text.trim(),
        assessmentName: assessments[_assessmentIndex],
        expiresAt: DateTime.now().add(Duration(days: _days)),
        message: _message.text.trim().isEmpty ? null : _message.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  List<String> _assessments(BuildContext context) => [
    context.l10n.logicalReasoningAssessment,
    context.l10n.decisionMakingAssessment,
    context.l10n.problemSolvingAssessment,
  ];

  @override
  Widget build(BuildContext context) {
    final assessments = _assessments(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: AppRadii.shape,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.enablePerson,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.enablePersonSubtitle,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _label(context.l10n.personName),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: context.l10n.personNameHint,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 18),
                _label(context.l10n.emailAddress),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: context.l10n.emailAddressHint,
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? context.l10n.validEmailAddressError
                      : null,
                ),
                const SizedBox(height: 18),
                _label(context.l10n.selectAssessment),
                DropdownButtonFormField<int>(
                  initialValue: _assessmentIndex,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: assessments.indexed
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.$1,
                          child: Text(entry.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _assessmentIndex = value ?? 0),
                ),
                const SizedBox(height: 18),
                _label(context.l10n.invitationExpiry),
                DropdownButtonFormField<int>(
                  initialValue: _days,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [3, 7, 14]
                      .map(
                        (days) => DropdownMenuItem(
                          value: days,
                          child: Text(context.l10n.daysValue(days)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _days = value ?? 7),
                ),
                const SizedBox(height: 18),
                _label(context.l10n.optionalMessage),
                TextField(
                  controller: _message,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: context.l10n.optionalMessageHint,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(context.l10n.sendInvitation),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
    ),
  );
}
