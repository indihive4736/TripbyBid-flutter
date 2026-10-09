import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/chat/domain/entities/chat.dart';
import 'package:tripbybid/features/chat/domain/usecases/chat_usecases.dart';
import 'package:tripbybid/features/chat/presentation/bloc/chat_cubit.dart';
import 'package:tripbybid/features/chat/presentation/pages/chat_page.dart';
import 'package:tripbybid/features/chat/presentation/widgets/chat_widgets.dart';

import '../../chat_fakes.dart';

void main() {
  late FakeChatRepository repository;

  setUp(() {
    repository = FakeChatRepository()
      ..conversationsResult = Ok([ChatFixtures.conversation()]);
  });

  Future<ChatCubit> pump(WidgetTester tester) async {
    final cubit = ChatCubit(
      getConversations: GetConversationsUseCase(repository),
      getMessages: GetMessagesUseCase(repository),
      sendMessage: SendMessageUseCase(repository),
      markRead: MarkConversationReadUseCase(repository),
      timerFactory: ManualTimer.factory,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const ChatView()),
      ),
    );
    await cubit.open(
      bookingId: ChatFixtures.bookingId,
      currentUserId: ChatFixtures.me,
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  MessageBubble bubble(WidgetTester tester, String text) =>
      tester.widget<MessageBubble>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(MessageBubble),
        ),
      );

  testWidgets('shows the agent, the trip and mine/theirs bubbles', (
    tester,
  ) async {
    final now = DateTime.now();
    repository.messagesResult = Ok([
      ChatFixtures.message(
        id: 'm1',
        content: 'Hello from AirTrek',
        createdAt: now,
      ),
      ChatFixtures.message(
        id: 'm2',
        senderId: ChatFixtures.me,
        content: 'Hi there',
        createdAt: now,
      ),
      ChatFixtures.message(
        id: 'm3',
        senderId: '',
        content: 'Booking confirmed',
        createdAt: now,
        isSystem: true,
      ),
    ]);
    await pump(tester);

    expect(find.text('AirTrek India'), findsOneWidget);
    expect(find.text('Mumbai → Dubai'), findsNWidgets(2)); // header + chip
    expect(find.text('· #9A21C0D3'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(bubble(tester, 'Hello from AirTrek').mine, isFalse);
    expect(bubble(tester, 'Hi there').mine, isTrue);
    expect(find.byType(SystemNote), findsOneWidget);
    expect(find.byType(QuickReplies), findsNothing);
  });

  testWidgets('offers quick replies on an empty thread', (tester) async {
    await pump(tester);

    expect(find.text('Start the conversation'), findsOneWidget);
    await tester.tap(find.text('Any better option?'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Any better option?',
    );
  });

  testWidgets('sends optimistically, then shows the confirmed message', (
    tester,
  ) async {
    repository.messagesResult = Ok([
      ChatFixtures.message(id: 'm1', content: 'Hello from AirTrek'),
    ]);
    final reply = Completer<Result<ChatMessage>>();
    repository.sendHandler = (_, _) => reply.future;
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Can you hold this fare?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.text('Can you hold this fare?'), findsOneWidget);
    expect(find.text('Sending…'), findsOneWidget);
    expect(bubble(tester, 'Can you hold this fare?').mine, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );

    reply.complete(
      Ok(
        ChatFixtures.message(
          id: 'm2',
          senderId: ChatFixtures.me,
          content: 'Can you hold this fare?',
          createdAt: DateTime(2026, 10, 10, 9, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sending…'), findsNothing);
    expect(find.text('Can you hold this fare?'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
  });

  testWidgets('a failed send can be retried by tapping it', (tester) async {
    repository.sendResult = const Err(NetworkFailure());
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Is cancellation free?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Not sent · Tap to retry'), findsOneWidget);

    repository.sendResult = Ok(
      ChatFixtures.message(
        id: 'm5',
        senderId: ChatFixtures.me,
        content: 'Is cancellation free?',
      ),
    );
    await tester.tap(find.text('Is cancellation free?'));
    await tester.pumpAndSettle();
    expect(find.text('Not sent · Tap to retry'), findsNothing);
    expect(repository.calls.where((c) => c.startsWith('send:')), hasLength(2));
  });
}
