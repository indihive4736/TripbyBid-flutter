import 'package:flutter/material.dart';

/// Placeholder — replaced by the real screen.
class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, required this.requestId, this.initialTab});

  final String requestId;
  final String? initialTab;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TripDetailPage')));
}
