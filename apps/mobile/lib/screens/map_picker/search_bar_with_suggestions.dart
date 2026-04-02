import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';
import 'package:whileyoureout/services/places_autocomplete_service.dart';

/// Search bar with an inline autocomplete suggestions dropdown.
///
/// Displays a Material search [TextField] with:
/// - A loading spinner in the prefix when
///   [MapPickerViewModel.isLoadingAutocomplete] is `true`, and a search icon
///   otherwise.
/// - A clear (×) button in the suffix when the field contains text.
/// - A [Card] dropdown listing [MapPickerViewModel.autocompleteSuggestions]
///   below the field whenever the list is non-empty.
///
/// Reads [placesAutocompleteServiceProvider] from the nearest [ProviderScope]
/// to perform prediction selection and to forward queries from `onChanged`.
class SearchBarWithSuggestions extends ConsumerStatefulWidget {
  /// Creates a [SearchBarWithSuggestions].
  const SearchBarWithSuggestions({
    required this.viewModel,
    required this.locationBias,
    required this.onMoveCamera,
    super.key,
  });

  /// The view-model that holds autocomplete state and exposes search
  /// callbacks ([MapPickerViewModel.updateSearchQuery],
  /// [MapPickerViewModel.selectPrediction],
  /// [MapPickerViewModel.clearAutocompleteSuggestions]).
  final MapPickerViewModel viewModel;

  /// Current map center used to bias autocomplete results geographically.
  final LatLng locationBias;

  /// Called with the place's [LatLng] after the user selects a suggestion so
  /// the map camera can be animated to the new location.
  final void Function(LatLng) onMoveCamera;

  @override
  ConsumerState<SearchBarWithSuggestions> createState() =>
      _SearchBarWithSuggestionsState();
}

class _SearchBarWithSuggestionsState
    extends ConsumerState<SearchBarWithSuggestions> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.viewModel.clearAutocompleteSuggestions();
    }
    setState(() {}); // repaint to show/hide clear button
  }

  Future<void> _onSuggestionTap(AutocompletePrediction prediction) async {
    _focusNode.unfocus();
    _controller.text = prediction.mainText;
    setState(() {}); // update clear button visibility

    final latLng = await widget.viewModel.selectPrediction(
      prediction,
      service: ref.read(placesAutocompleteServiceProvider),
    );

    if (latLng != null) {
      widget.onMoveCamera(latLng);
    }
  }

  void _onClear() {
    _controller.clear();
    _focusNode.unfocus();
    widget.viewModel.clearAutocompleteSuggestions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final suggestions = widget.viewModel.autocompleteSuggestions;
    final isLoading = widget.viewModel.isLoadingAutocomplete;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ------------------------------------------------------------------
        // Search text field
        // ------------------------------------------------------------------
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(24),
          color: colorScheme.surface,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Search for a place\u2026',
              prefixIcon: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: _onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (query) {
              setState(() {}); // repaint clear button
              widget.viewModel.updateSearchQuery(
                query,
                service: ref.read(placesAutocompleteServiceProvider),
                lat: widget.locationBias.latitude,
                lng: widget.locationBias.longitude,
              );
            },
          ),
        ),

        // ------------------------------------------------------------------
        // Suggestions dropdown
        // ------------------------------------------------------------------
        if (suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < suggestions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outlineVariant,
                    ),
                  InkWell(
                    borderRadius: BorderRadius.vertical(
                      top: i == 0
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottom: i == suggestions.length - 1
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    onTap: () => _onSuggestionTap(suggestions[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  suggestions[i].mainText,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (suggestions[i].description !=
                                    suggestions[i].mainText)
                                  Text(
                                    suggestions[i].description,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
