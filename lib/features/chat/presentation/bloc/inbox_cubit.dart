import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/chat_usecases.dart';

sealed class InboxState extends Equatable {
  const InboxState();

  @override
  List<Object?> get props => [];
}

final class InboxLoading extends InboxState {
  const InboxLoading();
}

final class InboxLoaded extends InboxState {
  const InboxLoaded(this.conversations);

  /// Most recent first.
  final List<Conversation> conversations;

  @override
  List<Object?> get props => [conversations];
}

final class InboxError extends InboxState {
  const InboxError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The traveler's chat threads (one per booking).
class InboxCubit extends Cubit<InboxState> {
  InboxCubit({required GetConversationsUseCase getConversations})
    : _getConversations = getConversations,
      super(const InboxLoading());

  final GetConversationsUseCase _getConversations;

  Future<void> load() async {
    emit(const InboxLoading());
    await refresh();
  }

  /// Reloads in place: a failed refresh keeps the list already shown.
  Future<void> refresh() async {
    final result = await _getConversations(const NoParams());
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(InboxLoaded(value));
      case Err(:final failure):
        if (state is! InboxLoaded) emit(InboxError(failure.message));
    }
  }
}
