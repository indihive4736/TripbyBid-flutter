import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/chat/domain/usecases/chat_usecases.dart';
import 'package:tripbybid/features/chat/presentation/bloc/inbox_cubit.dart';

import '../../chat_fakes.dart';

void main() {
  late FakeChatRepository repository;

  setUp(() => repository = FakeChatRepository());

  InboxCubit build() =>
      InboxCubit(getConversations: GetConversationsUseCase(repository));

  final conversation = ChatFixtures.conversation();

  blocTest<InboxCubit, InboxState>(
    'loads the conversations',
    setUp: () => repository.conversationsResult = Ok([conversation]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const InboxLoading(),
      InboxLoaded([conversation]),
    ],
  );

  blocTest<InboxCubit, InboxState>(
    'emits an error when loading fails',
    setUp: () => repository.conversationsResult = const Err(NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const InboxLoading(),
      InboxError(const NetworkFailure().message),
    ],
  );

  blocTest<InboxCubit, InboxState>(
    'a failed refresh keeps the list',
    setUp: () => repository.conversationsResult = const Err(NetworkFailure()),
    build: build,
    seed: () => InboxLoaded([conversation]),
    act: (cubit) => cubit.refresh(),
    expect: () => <InboxState>[],
  );
}
