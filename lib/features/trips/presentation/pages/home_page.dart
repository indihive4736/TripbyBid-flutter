import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../home/home_cubit.dart';
import '../home/home_view.dart';

/// 01 Home: featured trip, quick post, live bids and stats.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<HomeCubit>()..load(),
    child: HomeView(user: user),
  );
}
