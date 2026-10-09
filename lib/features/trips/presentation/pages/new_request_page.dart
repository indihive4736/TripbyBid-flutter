import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/trip_request.dart';
import '../new_request/new_request_cubit.dart';
import '../new_request/new_request_view.dart';
import '../new_request/place_search_cubit.dart';

/// Full-screen "new request" flow (design screen 04 plus a details step).
class NewRequestPage extends StatelessWidget {
  const NewRequestPage({super.key, this.initialType, required this.user});

  final TripType? initialType;
  final User user;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<NewRequestCubit>()
            ..start(type: initialType, email: user.email, phone: user.phone),
        ),
        BlocProvider(create: (_) => sl<PlaceSearchCubit>()),
      ],
      child: const NewRequestView(),
    );
  }
}
