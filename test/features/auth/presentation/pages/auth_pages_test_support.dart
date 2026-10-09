import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/logout_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/watch_session_ended_usecase.dart';
import 'package:tripbybid/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../helpers/fakes.dart';

/// A real [AuthBloc] over [repository], closed after the test.
AuthBloc authBlocFor(FakeAuthRepository repository) {
  final bloc = AuthBloc(
    getCurrentUser: GetCurrentUserUseCase(repository),
    logout: LogoutUseCase(repository),
    watchSessionEnded: WatchSessionEndedUseCase(repository),
  );
  addTearDown(bloc.close);
  return bloc;
}

/// Provides [authBloc] and [cubit] above the app.
Widget Function(Widget) provide<C extends StateStreamableSource<Object?>>(
  AuthBloc authBloc,
  C cubit,
) =>
    (child) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider<C>.value(value: cubit),
      ],
      child: child,
    );
