import 'package:flutter/material.dart';

import '../../domain/entities/trip_request.dart';
import '../../../auth/domain/entities/user.dart';

/// Placeholder — replaced by the real screen.
class NewRequestPage extends StatelessWidget {
  const NewRequestPage({super.key, this.initialType, required this.user});

  final TripType? initialType;
  final User user;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('NewRequestPage')));
}
