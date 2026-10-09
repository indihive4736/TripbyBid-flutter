import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../bloc/notifications_cubit.dart';
import '../widgets/notifications_view.dart';

/// Notifications: bids, messages, payments, tickets and updates.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<NotificationsCubit>()..load(),
    child: const NotificationsView(),
  );
}
