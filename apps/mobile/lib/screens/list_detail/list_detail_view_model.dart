import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whileyoureout/providers/providers.dart';

/// State exposed by [ListDetailViewModel].
class ListDetailState {
  /// Creates a [ListDetailState].
  const ListDetailState({
    this.list,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// The [TodoList] being viewed, or `null` while loading.
  final TodoList? list;

  /// The items belonging to [list].
  final List<TodoItem> items;

  /// Whether a mutating operation is in progress.
  final bool isLoading;

  /// Non-null when a mutating operation has failed.
  final String? errorMessage;

  /// Returns a copy of this state with the given fields replaced.
  ListDetailState copyWith({
    Object? list = _sentinel,
    List<TodoItem>? items,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return ListDetailState(
      list: list == _sentinel ? this.list : list as TodoList?,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

/// ViewModel for the list detail screen, keyed by list ID.
///
/// Subscribes to the reactive [listByIdProvider] and [itemsStreamProvider]
/// streams and delegates mutations to the relevant use cases.
class ListDetailViewModel
    extends AutoDisposeFamilyNotifier<ListDetailState, String> {
  @override
  ListDetailState build(String arg) {
    final listId = arg;

    // Subscribe to the list stream.
    final asyncList = ref.watch(listByIdProvider(listId));
    // Subscribe to the items stream.
    final asyncItems = ref.watch(itemsStreamProvider(listId));

    final list = asyncList.valueOrNull;
    final items = asyncItems.valueOrNull ?? const <TodoItem>[];

    final loading = asyncList.isLoading || asyncItems.isLoading;

    final error = asyncList.hasError
        ? asyncList.error.toString()
        : asyncItems.hasError
            ? asyncItems.error.toString()
            : null;

    return ListDetailState(
      list: list,
      items: items,
      isLoading: loading,
      errorMessage: error,
    );
  }

  String get _listId => arg;

  /// Toggles the done state of the item identified by [itemId].
  Future<void> toggleItem(String itemId) async {
    try {
      await ref.read(toggleItemUseCaseProvider).call(itemId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Creates a new item with the given [title] in this list.
  Future<void> createItem({required String title}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    try {
      await ref.read(createItemUseCaseProvider).call(
            listId: _listId,
            title: trimmed,
          );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Permanently deletes the item identified by [itemId].
  Future<void> deleteItem(String itemId) async {
    try {
      await ref.read(deleteItemUseCaseProvider).call(itemId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

/// Riverpod provider for [ListDetailViewModel], keyed by list ID.
final listDetailViewModelProvider = NotifierProvider.autoDispose
    .family<ListDetailViewModel, ListDetailState, String>(
  ListDetailViewModel.new,
);
