import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/screens/list_detail/list_detail_view_model.dart';

/// The detail screen for a single [TodoList].
///
/// Displays the list's items as checkboxes, supports adding new items via an
/// inline text field, and allows swiping to delete individual items.
class ListDetailScreen extends ConsumerWidget {
  /// Creates a [ListDetailScreen] for the list identified by [listId].
  const ListDetailScreen({required this.listId, super.key});

  /// The ID of the [TodoList] to display.
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(listDetailViewModelProvider(listId));
    final viewModel = ref.read(listDetailViewModelProvider(listId).notifier);

    final list = detailState.list;

    return Scaffold(
      appBar: AppBar(
        title: list == null
            ? const Text('List')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(list.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      list.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
      body: _ListDetailBody(
        listId: listId,
        state: detailState,
        viewModel: viewModel,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _ListDetailBody extends ConsumerStatefulWidget {
  const _ListDetailBody({
    required this.listId,
    required this.state,
    required this.viewModel,
  });

  final String listId;
  final ListDetailState state;
  final ListDetailViewModel viewModel;

  @override
  ConsumerState<_ListDetailBody> createState() => _ListDetailBodyState();
}

class _ListDetailBodyState extends ConsumerState<_ListDetailBody> {
  final _addItemController = TextEditingController();
  final _addItemFocusNode = FocusNode();

  @override
  void dispose() {
    _addItemController.dispose();
    _addItemFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitItem() async {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;
    _addItemController.clear();
    await widget.viewModel.createItem(title: text);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoading && state.list == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.list == null) {
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

    final list = state.list;
    final items = state.items;

    return Column(
      children: [
        // Location chip (Phase 1: tapping shows coming-soon snackbar)
        if (list != null && list.geofenceId != null)
          _LocationChip(geofenceId: list.geofenceId!),

        // Item list or empty state
        Expanded(
          child: items.isEmpty
              ? const AppEmptyState(
                  icon: Icons.checklist,
                  headline: 'No items yet',
                  body: 'Add your first item below.',
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SwipeToDismissItem(
                      key: ValueKey(item.id),
                      item: item,
                      onToggle: () =>
                          widget.viewModel.toggleItem(item.id),
                      onDelete: () =>
                          widget.viewModel.deleteItem(item.id),
                    );
                  },
                ),
        ),

        // Inline add-item text field
        _AddItemTextField(
          controller: _addItemController,
          focusNode: _addItemFocusNode,
          onSubmit: _submitItem,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Location chip
// ---------------------------------------------------------------------------

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.geofenceId});

  final String geofenceId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.location_on, size: 16),
          label: Text(
            geofenceId,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location assignment coming soon'),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe-to-dismiss item row
// ---------------------------------------------------------------------------

class _SwipeToDismissItem extends StatelessWidget {
  const _SwipeToDismissItem({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AppCheckbox(
          label: item.title,
          value: item.isDone,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline add-item text field
// ---------------------------------------------------------------------------

class _AddItemTextField extends StatelessWidget {
  const _AddItemTextField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add an item…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add),
              tooltip: 'Add item',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
