import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/chat.dart';
import '../bloc/inbox_cubit.dart';
import '../widgets/chat_style.dart';

/// The Inbox tab: one thread per booked trip.
class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InboxCubit>()..load(),
      child: const InboxView(),
    );
  }
}

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InboxCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: BlocBuilder<InboxCubit, InboxState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text('Inbox', style: AppTypography.display(34)),
                      ),
                    ),
                  ),
                  ...switch (state) {
                    InboxLoading() => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: LoadingView(),
                      ),
                    ],
                    InboxError(:final message) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: StateMessage.error(
                            message: message,
                            onRetry: cubit.load,
                          ),
                        ),
                      ),
                    ],
                    InboxLoaded(:final conversations)
                        when conversations.isEmpty =>
                      [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: StateMessage(
                              icon: Symbols.forum_rounded,
                              title: 'No conversations yet',
                              message:
                                  'Chat opens with your agent once a trip is '
                                  'booked.',
                              actionLabel: 'Go to my trips',
                              onAction: () => context.go(AppRoutes.trips),
                            ),
                          ),
                        ),
                      ],
                    InboxLoaded(:final conversations) => [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.separated(
                          itemCount: conversations.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              ConversationTile(conversation: conversations[i]),
                        ),
                      ),
                    ],
                  },
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppBottomNav.reservedHeight + 20),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One thread in the inbox.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation});

  final Conversation conversation;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<InboxCubit>();
    await context.push(AppRoutes.chat(conversation.bookingId));
    // Unread counts and previews change while the chat is open.
    await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;
    final preview = switch (c.lastMessage) {
      null || '' => 'No messages yet — say hello',
      final text when c.lastMessageMine => 'You: $text',
      final text => text,
    };
    return Semantics(
      button: true,
      label:
          '${c.agentName}, ${c.title}'
          '${unread ? ', ${c.unreadCount} unread' : ''}',
      excludeSemantics: true,
      child: AppCard(
        radius: 26,
        shadow: true,
        onTap: () => _open(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: c.tripIcon, tint: c.tripTint, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.agentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            16,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Fmt.relative(c.updatedAt),
                        style: AppTypography.body(
                          12,
                          color: unread
                              ? AppColors.accentDeep
                              : AppColors.textTertiary,
                          weight: unread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            14,
                            color: unread
                                ? AppColors.ink
                                : AppColors.textSecondary,
                            weight: unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                            style: AppTypography.number(11, tracking: 0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
