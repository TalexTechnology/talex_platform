import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/app/app.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/locale/locale_cubit.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/talent/domain/services/assessment_invite_link.dart';
import 'package:talex_platform/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  final localeCubit = getIt<LocaleCubit>();
  await localeCubit.load();
  final inviteToken = AssessmentInviteLink.tokenFromUri(Uri.base);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: localeCubit),
        BlocProvider(
          create: (_) {
            final bloc = getIt<AuthBloc>();
            if (inviteToken != null) {
              bloc.add(AuthRespondentInviteRequested(inviteToken));
            } else {
              bloc.add(const AuthSessionRequested());
            }
            return bloc;
          },
        ),
      ],
      child: const TalexApp(),
    ),
  );
}
