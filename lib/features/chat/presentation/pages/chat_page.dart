import 'package:flutter/material.dart';

/// Placeholder — replaced by the real screen.
class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.bookingId,
    required this.currentUserId,
  });

  final String bookingId;
  final String currentUserId;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('ChatPage')));
}
