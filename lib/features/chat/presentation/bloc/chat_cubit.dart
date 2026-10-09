import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_state.dart';

/// Creates the polling timer; tests pass one they can fire by hand.
typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) onTick);

/// One booking's chat with its agent.
///
/// The backend publishes new messages over Ably, but the app has no Ably
/// client yet, so the thread is polled every [pollInterval] while the screen
/// is visible ([pausePolling] / [resumePolling] follow the app lifecycle).
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required GetConversationsUseCase getConversations,
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
    required MarkConversationReadUseCase markRead,
    this.pollInterval = const Duration(seconds: 5),
    PeriodicTimerFactory? timerFactory,
  }) : _getConversations = getConversations,
       _getMessages = getMessages,
       _sendMessage = sendMessage,
       _markRead = markRead,
       _timerFactory = timerFactory ?? Timer.periodic,
       super(const ChatState());

  final GetConversationsUseCase _getConversations;
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final MarkConversationReadUseCase _markRead;
  final PeriodicTimerFactory _timerFactory;
  final Duration pollInterval;

  String _bookingId = '';
  Timer? _timer;
  bool _polling = false;
  bool _paused = false;
  int _localSeq = 0;

  /// Incoming messages already reported as read.
  final _markedRead = <String>{};

  /// Loads the thread and starts polling.
  Future<void> open({
    required String bookingId,
    required String currentUserId,
  }) async {
    _bookingId = bookingId;
    emit(ChatState(currentUserId: currentUserId));
    await _loadAll();
  }

  /// Retries after a failed first load.
  Future<void> retry() async {
    emit(state.copyWith(status: ChatStatus.loading));
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final conversations = _getConversations(const NoParams());
    final messages = await _getMessages(_bookingId);
    final conversation = switch (await conversations) {
      Ok(:final value) =>
        value.where((c) => c.bookingId == _bookingId).firstOrNull,
      Err() => null,
    };
    if (isClosed) return;
    switch (messages) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: ChatStatus.ready,
            conversation: conversation,
            messages: _merge(const [], value),
          ),
        );
        _markIncomingRead();
        _startTimer();
      case Err(:final failure):
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            conversation: conversation,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Fetches new messages once (also what the timer runs).
  Future<void> poll() async {
    if (_polling || isClosed || state.status != ChatStatus.ready) return;
    _polling = true;
    try {
      final result = await _getMessages(_bookingId);
      if (isClosed) return;
      if (result case Ok(:final value)) {
        final merged = _merge(state.messages, value);
        if (merged.length != state.messages.length ||
            !_sameMessages(merged, state.messages)) {
          emit(state.copyWith(messages: merged));
        }
        _markIncomingRead();
      }
      // A failed poll is silent: the next tick tries again.
    } finally {
      _polling = false;
    }
  }

  void pausePolling() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void resumePolling() {
    if (!_paused) return;
    _paused = false;
    if (state.status != ChatStatus.ready) return;
    _startTimer();
    unawaited(poll());
  }

  void _startTimer() {
    if (_paused || isClosed) return;
    _timer?.cancel();
    _timer = _timerFactory(pollInterval, (_) => unawaited(poll()));
  }

  /// Sends [text] with an optimistic bubble.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.status != ChatStatus.ready) return;
    final pending = PendingMessage(
      localId: 'local-${_localSeq++}',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(pending: [...state.pending, pending]));
    await _deliver(pending);
  }

  /// Sends a failed message again.
  Future<void> resend(String localId) async {
    final pending = state.pending
        .where((p) => p.localId == localId && p.failed)
        .firstOrNull;
    if (pending == null) return;
    _replacePending(localId, pending.copyWith(failed: false));
    await _deliver(pending);
  }

  /// Drops a failed message without sending it.
  void discard(String localId) {
    emit(
      state.copyWith(
        pending: [
          for (final p in state.pending)
            if (p.localId != localId) p,
        ],
      ),
    );
  }

  Future<void> _deliver(PendingMessage pending) async {
    final result = await _sendMessage(
      SendMessageParams(_bookingId, pending.text),
    );
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            messages: _merge(state.messages, [value]),
            pending: [
              for (final p in state.pending)
                if (p.localId != pending.localId) p,
            ],
          ),
        );
      case Err():
        _replacePending(pending.localId, pending.copyWith(failed: true));
    }
  }

  void _replacePending(String localId, PendingMessage replacement) {
    emit(
      state.copyWith(
        pending: [
          for (final p in state.pending) p.localId == localId ? replacement : p,
        ],
      ),
    );
  }

  void _markIncomingRead() {
    final unread = state.messages
        .where(
          (m) =>
              !m.isRead &&
              !state.isMine(m) &&
              !m.isSystem &&
              !_markedRead.contains(m.id),
        )
        .map((m) => m.id)
        .toList();
    if (unread.isEmpty) return;
    _markedRead.addAll(unread);
    unawaited(_markRead(_bookingId));
  }

  /// Union by id (fresh copies win), oldest first.
  static List<ChatMessage> _merge(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final byId = <String, ChatMessage>{
      for (final m in current) m.id: m,
      for (final m in incoming) m.id: m,
    };
    return byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static bool _sameMessages(List<ChatMessage> a, List<ChatMessage> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
