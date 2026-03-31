import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whileyoureout/providers/providers.dart';

/// State exposed by [DashboardViewModel].
class DashboardState {
  /// Creates a [DashboardState].
  const DashboardState({
    this.lists = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// The current list of all [TodoList]s.
  final List<TodoList> lists;

  /// Whether a mutating operation (delete, reorder) is in progress.
  final bool isLoading;

  /// Non-null when a mutating operation has failed.
  final String? errorMessage;

  /// Returns a copy of this state with the given fields replaced.
  DashboardState copyWith({
    List<TodoList>? lists,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return DashboardState(
      lists: lists ?? this.lists,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

/// ViewModel for the dashboard screen.
///
/// Manages the list of [TodoList]s by subscribing to the reactive
/// [allListsStreamProvider] and delegating mutations to the relevant use cases.
class DashboardViewModel extends AutoDisposeNotifier<DashboardState> {
  @override
  DashboardState build() {
    // Subscribe to the all-lists stream and keep state in sync.
    final asyncLists = ref.watch(allListsStreamProvider);
    return asyncLists.when(
      data: (lists) => DashboardState(lists: lists),
      loading: () => const DashboardState(isLoading: true),
      error: (e, _) => DashboardState(errorMessage: e.toString()),
    );
  }

  /// Deletes the list identified by [listId].
  Future<void> deleteList(String listId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(deleteListUseCaseProvider).call(listId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
    // On success the stream update will rebuild state automatically.
    state = state.copyWith(isLoading: false);
  }

  /// Reorders lists to match [orderedIds].
  Future<void> reorderLists(List<String> orderedIds) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(reorderListsUseCaseProvider).call(orderedIds);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
    state = state.copyWith(isLoading: false);
  }
}

/// Riverpod provider for [DashboardViewModel].
final dashboardViewModelProvider =
    NotifierProvider.autoDispose<DashboardViewModel, DashboardState>(
  DashboardViewModel.new,
);
