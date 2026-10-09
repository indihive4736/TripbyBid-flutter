import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/chat/domain/usecases/chat_usecases.dart';
import 'package:tripbybid/features/chat/presentation/bloc/inbox_cubit.dart';
import 'package:tripbybid/features/chat/presentation/pages/inbox_page.dart';

import '../../chat_fakes.dart';

void main() {
  late FakeChatRepository repository;

  setUp(() => repository = FakeChatRepository());

  Future<void> pump(WidgetTester tester) async {
    final cubit = InboxCubit(
      getConversations: GetConversationsUseCase(repository),
    );
    addTearDown(cubit.close);
    unawaited(cubit.load());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const InboxView()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the empty state with a link to trips', (tester) async {
    await pump(tester);

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
    expect(
      find.text('Chat opens with your agent once a trip is booked.'),
      findsOneWidget,
    );
    expect(find.text('Go to my trips'), findsOneWidget);
  });

  testWidgets('lists threads with preview and unread count', (tester) async {
    repository.conversationsResult = Ok([
      ChatFixtures.conversation(unreadCount: 2),
      ChatFixtures.conversation(
        bookingId: 'b-2',
        agentName: 'Rail Mitra',
        tripType: 'train',
        lastMessage: 'Thanks!',
        lastMessageMine: true,
      ),
    ]);
    await pump(tester);

    expect(find.text('AirTrek India'), findsOneWidget);
    expect(find.text('Rail Mitra'), findsOneWidget);
    expect(find.text('Mumbai → Dubai'), findsNWidgets(2));
    expect(find.text('Your ticket is ready'), findsOneWidget);
    expect(find.text('You: Thanks!'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('5 min ago'), findsNWidgets(2));
  });
}
