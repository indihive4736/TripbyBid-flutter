import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_cubit.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final submitting = context.select(
      (LoginCubit cubit) => cubit.state.status == LoginStatus.submitting,
    );

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TripByBid', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Sign in to continue', style: textTheme.bodyLarge),
          const SizedBox(height: 32),
          TextField(
            key: const Key('login_email'),
            controller: _email,
            enabled: !submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('login_password'),
            controller: _password,
            enabled: !submitting,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login_submit'),
            onPressed: submitting ? null : _submit,
            child: submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
