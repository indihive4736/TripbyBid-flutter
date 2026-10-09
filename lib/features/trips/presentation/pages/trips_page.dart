import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../list/trips_list_cubit.dart';
import '../list/trips_view.dart';

/// 02 My trips: every request and its status.
class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<TripsListCubit>()..load(),
    child: const TripsView(),
  );
}
