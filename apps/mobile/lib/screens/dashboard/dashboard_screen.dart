import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/router/app_router.dart';
import 'package:whileyoureout/screens/dashboard/create_list_bottom_sheet.dart';
import 'package:whileyoureout/screens/dashboard/dashboard_view_model.dart';

/// The home screen — displays all todo lists and allows creating new ones.
class DashboardScreen extends ConsumerWidget {
  /// Creates a [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardViewModelProvider);
    final viewModel = ref.read(dashboardViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "While You're Out",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'settings') {
                context.push(AppRoutes.notificationSettings);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Notification settings'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('dashboard_fab'),
        onPressed: () => CreateListBottomSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
      body: _DashboardBody(
        state: dashState,
        onDelete: (id) => _confirmDelete(context, ref, viewModel, id),
        onTap: (id) => context.push(AppRoutes.listDetailPath(id)),
        onReorder: (oldIndex, newIndex) {
          // ReorderableListView calls onReorder with newIndex already adjusted
          // for the removal; we just need to build the ordered ID list.
          final lists = List<TodoList>.from(dashState.lists);
          final item = lists.removeAt(oldIndex);
          lists.insert(newIndex, item);
          viewModel.reorderLists(lists.map((l) => l.id).toList());
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DashboardViewModel viewModel,
    String listId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete list?'),
        content: const Text(
          'This will permanently delete the list and all its items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await viewModel.deleteList(listId);
    }
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.state,
    required this.onDelete,
    required this.onTap,
    required this.onReorder,
  });

  final DashboardState state;
  final void Function(String id) onDelete;
  final void Function(String id) onTap;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.lists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.lists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong: ${state.errorMessage}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.lists.isEmpty) {
      return const AppEmptyState(
        icon: Icons.checklist,
        headline: 'No lists yet',
        body: 'Tap + to create one.',
      );
    }

    return ReorderableListView.builder(
      itemCount: state.lists.length,
      onReorder: onReorder,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemBuilder: (context, index) {
        final list = state.lists[index];
        return _ListTileWithBadge(
          key: ValueKey(list.id),
          list: list,
          index: index,
          onTap: () => onTap(list.id),
          onLongPress: () => onDelete(list.id),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// List tile with async badge
// ---------------------------------------------------------------------------

class _ListTileWithBadge extends ConsumerWidget {
  const _ListTileWithBadge({
    required this.list,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final TodoList list;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(incompleteCountProvider(list.id));
    final incompleteCount = countAsync.valueOrNull ?? 0;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppListTile(
        key: ValueKey(list.id),
        title: list.title,
        color: list.color,
        incompleteCount: incompleteCount,
        hasGeofence: list.geofenceId != null,
        onTap: onTap,
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}
