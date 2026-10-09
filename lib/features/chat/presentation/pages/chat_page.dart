import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/chat_cubit.dart';
import '../widgets/chat_widgets.dart';

/// The chat with the agent of one booking.
class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.bookingId,
    required this.currentUserId,
  });

  final String bookingId;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ChatCubit>()
            ..open(bookingId: bookingId, currentUserId: currentUserId),
      child: const ChatView(),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  final _draft = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<ChatCubit>();
    if (state == AppLifecycleState.resumed) {
      cubit.resumePolling();
    } else {
      cubit.pausePolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draft.dispose();
    super.dispose();
  }

  void _send() {
    final text = _draft.text;
    if (text.trim().isEmpty) return;
    _draft.clear();
    context.read<ChatCubit>().send(text);
  }

  void _insertReply(String phrase) {
    final current = _draft.text.trimRight();
    final next = current.isEmpty ? phrase : '$current $phrase';
    _draft.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inbox);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final conversation = state.conversation;
        final agentName = conversation?.agentName ?? 'Your agent';
        return Scaffold(
          body: Column(
            children: [
              ChatHeader(
                agentName: agentName,
                subtitle: conversation?.title,
                onBack: _back,
              ),
              if (conversation != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TripContextChip(
                    conversation: conversation,
                    onTap: conversation.requestId.isEmpty
                        ? null
                        : () => context.push(
                            AppRoutes.trip(conversation.requestId),
                          ),
                  ),
                ),
              Expanded(
                child: switch (state.status) {
                  ChatStatus.loading => const LoadingView(),
                  ChatStatus.failure => Center(
                    child: SingleChildScrollView(
                      child: StateMessage.error(
                        message: state.errorMessage ?? 'Could not load chat.',
                        onRetry: context.read<ChatCubit>().retry,
                      ),
                    ),
                  ),
                  ChatStatus.ready when state.isEmpty => Center(
                    child: SingleChildScrollView(
                      child: StateMessage(
                        icon: Symbols.forum_rounded,
                        title: 'Start the conversation',
                        message: 'Ask $agentName anything about your booking.',
                      ),
                    ),
                  ),
                  ChatStatus.ready => MessageList(state: state),
                },
              ),
              if (state.status == ChatStatus.ready)
                ChatComposer(
                  controller: _draft,
                  hint: 'Message $agentName…',
                  onSend: _send,
                  top: state.isEmpty
                      ? QuickReplies(onPick: _insertReply)
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Messages with day separators, newest at the bottom. Follows new
/// messages only when the traveler is already near the bottom.
class MessageList extends StatefulWidget {
  const MessageList({super.key, required this.state});

  final ChatState state;

  @override
  State<MessageList> createState() => _MessageListState();
}

sealed class _Item {
  const _Item();
}

final class _Day extends _Item {
  const _Day(this.label);
  final String label;
}

final class _Sent extends _Item {
  const _Sent(this.message);
  final ChatMessageView message;
}

/// What a bubble needs, for confirmed and pending messages alike.
final class ChatMessageView {
  const ChatMessageView({
    required this.key,
    required this.text,
    required this.createdAt,
    required this.mine,
    this.system = false,
    this.delivery = BubbleDelivery.sent,
  });

  final String key;
  final String text;
  final DateTime createdAt;
  final bool mine;
  final bool system;
  final BubbleDelivery delivery;
}

class _MessageListState extends State<MessageList> {
  final _scroll = ScrollController();
  late List<_Item> _items = _build(widget.state);

  static const _nearBottom = 120.0;

  static List<_Item> _build(ChatState state) {
    final views = [
      for (final m in state.messages)
        ChatMessageView(
          key: m.id,
          text: m.content,
          createdAt: m.createdAt,
          mine: state.isMine(m),
          system: m.isSystem,
        ),
      for (final p in state.pending)
        ChatMessageView(
          key: p.localId,
          text: p.text,
          createdAt: p.createdAt,
          mine: true,
          delivery: p.failed ? BubbleDelivery.failed : BubbleDelivery.sending,
        ),
    ];
    final items = <_Item>[];
    DateTime? lastDay;
    for (final v in views) {
      final local = v.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day != lastDay) {
        items.add(_Day(Fmt.dayLabel(local)));
        lastDay = day;
      }
      items.add(_Sent(v));
    }
    return items;
  }

  String? _newestKey(List<_Item> items) => switch (items.lastOrNull) {
    _Sent(:final message) => message.key,
    _ => null,
  };

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = _newestKey(_items);
    _items = _build(widget.state);
    final after = _newestKey(_items);
    if (before == after || !_scroll.hasClients) return;

    final newest = (_items.last as _Sent).message;
    final position = _scroll.position;
    if (newest.mine || position.pixels <= _nearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      });
    } else {
      // The list is reversed: content added at the bottom would push what
      // the traveler is reading. Keep it in place.
      final oldMax = position.maxScrollExtent;
      final oldPixels = position.pixels;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final delta = _scroll.position.maxScrollExtent - oldMax;
        if (delta > 0) _scroll.jumpTo(oldPixels + delta);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final count = _items.length;
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: count,
      itemBuilder: (context, index) {
        final item = _items[count - 1 - index];
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: switch (item) {
            _Day(:final label) => DaySeparator(label: label),
            _Sent(:final message) when message.system => SystemNote(
              text: message.text,
            ),
            _Sent(:final message) => MessageBubble(
              key: ValueKey(message.key),
              text: message.text,
              mine: message.mine,
              timeLabel: Fmt.time(message.createdAt.toLocal()),
              delivery: message.delivery,
              onRetry: () => cubit.resend(message.key),
              onDiscard: () => cubit.discard(message.key),
            ),
          },
        );
      },
    );
  }
}
