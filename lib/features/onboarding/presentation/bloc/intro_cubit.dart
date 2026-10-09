import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/mark_intro_seen_usecase.dart';

final class IntroState extends Equatable {
  const IntroState({this.page = 0, this.finished = false});

  /// The visible slide, 0-based.
  final int page;

  /// The intro was finished or skipped and marked as seen.
  final bool finished;

  IntroState copyWith({int? page, bool? finished}) =>
      IntroState(page: page ?? this.page, finished: finished ?? this.finished);

  @override
  List<Object?> get props => [page, finished];
}

/// The intro slides: current page, and "seen" once finished or skipped.
class IntroCubit extends Cubit<IntroState> {
  IntroCubit({required MarkIntroSeenUseCase markIntroSeen})
    : _markIntroSeen = markIntroSeen,
      super(const IntroState());

  static const pageCount = 3;

  final MarkIntroSeenUseCase _markIntroSeen;

  bool get isLastPage => state.page == pageCount - 1;

  void pageChanged(int page) {
    if (state.finished) return;
    emit(state.copyWith(page: page.clamp(0, pageCount - 1)));
  }

  /// Marks the intro as seen. A storage failure only means the intro shows
  /// again next launch, so it never blocks the traveler.
  Future<void> finish() async {
    if (state.finished) return;
    await _markIntroSeen(const NoParams());
    emit(state.copyWith(finished: true));
  }
}
