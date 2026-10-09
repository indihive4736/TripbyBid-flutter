import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';

/// Placeholder landing screen after sign-in. Receives what it needs from the
/// router so it depends only on the auth feature's domain.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.onLogout});

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TripByBid'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome, ${user.name}', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(switch (user.role) {
              UserRole.traveler => 'Traveler account',
              UserRole.agent => 'Agent account',
              UserRole.admin => 'Admin account',
            }),
          ],
        ),
      ),
    );
  }
}
