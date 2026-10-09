import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../detail/trip_detail_cubit.dart';
import '../detail/trip_detail_view.dart';

/// Booking detail of a request: bids, payment, ticket and rating.
class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, required this.requestId, this.initialTab});

  final String requestId;

  /// `overview`, `bids`, `timeline` or `docs`.
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<TripDetailCubit>()..load(requestId, initialTab: initialTab),
      child: const TripDetailView(),
    );
  }
}
