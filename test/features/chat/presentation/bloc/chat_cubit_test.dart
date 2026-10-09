import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/chat/domain/entities/chat.dart';
import 'package:tripbybid/features/chat/domain/usecases/chat_usecases.dart';
import 'package:tripbybid/features/chat/presentation/bloc/chat_cubit.dart';

import '../../chat_fakes.dart';

void main() {
  late FakeChatRepository repository;

  setUp(() {
    repository = FakeChatRepository();
    ManualTimer.created.clear();
  });

  ChatCubit build() => ChatCubit(
    getConversations: GetConversationsUseCase(repository),
    getMessages: GetMessagesUseCase(repository),
    sendMessage: SendMessageUseCase(repository),
    markRead: MarkConversationReadUseCase(repository),
    timerFactory: ManualTimer.factory,
  );

  Future<ChatCubit> opened() async {
    final cubit = build();
    await cubit.open(
      bookingId: ChatFixtures.bookingId,
      currentUserId: ChatFixtures.me,
    );
    return cubit;
  }

  final hello = ChatFixtures.message(id: 'm1', content: 'Hello');
  final mine = ChatFixtures.message(
    id: 'm2',
    senderId: ChatFixtures.me,
    content: 'Hi!',
    createdAt: DateTime(2026, 10, 10, 9, 5),
  );

  group('open', () {
    blocTest<ChatCubit, ChatState>(
      'loads the conversation and messages, then polls every 5 s',
      setUp: () {
        repository
          ..conversationsResult = Ok([
            ChatFixtures.conversation(bookingId: 'other'),
            ChatFixtures.conversation(),
          ])
          ..messagesResult = Ok([mine, hello]);
      },
      build: build,
      act: (cubit) => cubit.open(
        bookingId: ChatFixtures.bookingId,
        currentUserId: ChatFixtures.me,
      ),
      verify: (cubit) {
        final state = cubit.state;
        expect(state.status, ChatStatus.ready);
        expect(state.conversation?.bookingId, ChatFixtures.bookingId);
        expect(state.messages.map((m) => m.id), ['m1', 'm2']);
        expect(state.isMine(state.messages[1]), isTrue);
        expect(state.isMine(state.messages[0]), isFalse);
        expect(ManualTimer.created.single.interval, const Duration(seconds: 5));
      },
    );

    blocTest<ChatCubit, ChatState>(
      'emits failure when messages cannot load, and does not poll',
      setUp: () => repository.messagesResult = const Err(NetworkFailure()),
      build: build,
      act: (cubit) => cubit.open(
        bookingId: ChatFixtures.bookingId,
        currentUserId: ChatFixtures.me,
      ),
      verify: (cubit) {
        expect(cubit.state.status, ChatStatus.failure);
        expect(cubit.state.errorMessage, const NetworkFailure().message);
        expect(ManualTimer.created, isEmpty);
      },
    );

    test('marks the thread read when the agent has unread messages', () async {
      repository.messagesResult = Ok([
        ChatFixtures.message(id: 'm1', isRead: false),
      ]);
      final cubit = await opened();
      expect(repository.calls, contains('markRead:${ChatFixtures.bookingId}'));
      await cubit.close();
    });

    test('does not mark read when everything is read', () async {
      repository.messagesResult = Ok([hello, mine]);
      final cubit = await opened();
      expect(repository.calls.where((c) => c.startsWith('markRead')), isEmpty);
      await cubit.close();
    });
  });

  group('polling', () {
    test(
      'merges new messages without duplicates and marks them read',
      () async {
        repository.messagesResult = Ok([hello]);
        final cubit = await opened();

        final incoming = ChatFixtures.message(
          id: 'm3',
          content: 'Ticket uploaded',
          createdAt: DateTime(2026, 10, 10, 10),
          isRead: false,
        );
        repository.messagesResult = Ok([hello, incoming]);
        ManualTimer.created.single.fire();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.messages.map((m) => m.id), ['m1', 'm3']);
        expect(
          repository.calls.where((c) => c.startsWith('markRead')),
          hasLength(1),
        );

        // The same payload again changes nothing and is not re-marked.
        ManualTimer.created.single.fire();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.messages, hasLength(2));
        expect(
          repository.calls.where((c) => c.startsWith('markRead')),
          hasLength(1),
        );
        await cubit.close();
      },
    );

    test('a failed poll keeps the thread', () async {
      repository.messagesResult = Ok([hello]);
      final cubit = await opened();
      repository.messagesResult = const Err(NetworkFailure());
      await cubit.poll();
      expect(cubit.state.status, ChatStatus.ready);
      expect(cubit.state.messages, [hello]);
      await cubit.close();
    });

    test(
      'pause cancels the timer and resume restarts it with a poll',
      () async {
        final cubit = await opened();
        final first = ManualTimer.created.single;
        cubit.pausePolling();
        expect(first.isActive, isFalse);

        final calls = repository.calls.length;
        cubit.resumePolling();
        await Future<void>.delayed(Duration.zero);
        expect(ManualTimer.created, hasLength(2));
        expect(ManualTimer.created.last.isActive, isTrue);
        expect(repository.calls.length, greaterThan(calls));
        await cubit.close();
      },
    );

    test('close cancels the timer', () async {
      final cubit = await opened();
      await cubit.close();
      expect(ManualTimer.created.single.isActive, isFalse);
    });
  });

  group('send', () {
    test('shows a pending bubble, then the confirmed message', () async {
      final cubit = await opened();
      final reply = Completer<Result<ChatMessage>>();
      repository.sendHandler = (_, _) => reply.future;

      final sending = cubit.send('  Can you hold this fare?  ');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.pending.single.text, 'Can you hold this fare?');
      expect(cubit.state.pending.single.failed, isFalse);

      final saved = ChatFixtures.message(
        id: 'm9',
        senderId: ChatFixtures.me,
        content: 'Can you hold this fare?',
      );
      reply.complete(Ok(saved));
      await sending;

      expect(cubit.state.pending, isEmpty);
      expect(cubit.state.messages, [saved]);
      expect(
        repository.calls,
        contains('send:${ChatFixtures.bookingId}:Can you hold this fare?'),
      );
      await cubit.close();
    });

    test('marks a failed send and resends it on retry', () async {
      final cubit = await opened();
      repository.sendResult = const Err(NetworkFailure());
      await cubit.send('Any better option?');
      final failed = cubit.state.pending.single;
      expect(failed.failed, isTrue);

      final saved = ChatFixtures.message(
        id: 'm10',
        senderId: ChatFixtures.me,
        content: 'Any better option?',
      );
      repository.sendResult = Ok(saved);
      await cubit.resend(failed.localId);

      expect(cubit.state.pending, isEmpty);
      expect(cubit.state.messages, [saved]);
      await cubit.close();
    });

    test('discard drops a failed message', () async {
      final cubit = await opened();
      repository.sendResult = const Err(NetworkFailure());
      await cubit.send('Is cancellation free?');
      cubit.discard(cubit.state.pending.single.localId);
      expect(cubit.state.pending, isEmpty);
      await cubit.close();
    });

    test('ignores blank text', () async {
      final cubit = await opened();
      await cubit.send('   ');
      expect(cubit.state.pending, isEmpty);
      expect(repository.calls.where((c) => c.startsWith('send')), isEmpty);
      await cubit.close();
    });
  });
}
