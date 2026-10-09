import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';

/// Placeholder — replaced by the real screen.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('HomePage')));
}
