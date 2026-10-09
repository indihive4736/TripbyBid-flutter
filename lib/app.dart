import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class TripByBidApp extends StatefulWidget {
  const TripByBidApp({super.key});

  @override
  State<TripByBidApp> createState() => _TripByBidAppState();
}

class _TripByBidAppState extends State<TripByBidApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>()..add(const AuthStarted());
  late final GoRouter _router = createRouter(_authBloc, sl());

  @override
  void dispose() {
    _router.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'TripByBid',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
