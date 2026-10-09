import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_cubit.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: const LoginView(),
    );
  }
}

/// The login screen, given a [LoginCubit] and an [AuthBloc] above it.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        switch (state) {
          case LoginState(status: LoginStatus.success, :final user?):
            context.read<AuthBloc>().add(AuthLoggedIn(user));
          case LoginState(status: LoginStatus.failure, :final errorMessage?):
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(errorMessage)));
          case LoginState():
            break;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const LoginForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
