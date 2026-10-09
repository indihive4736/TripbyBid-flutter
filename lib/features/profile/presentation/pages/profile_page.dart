import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';

/// Placeholder — replaced by the real screen.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.onLogout});

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('ProfilePage')));
}
