import 'package:flutter/material.dart';

class MapActionButtons extends StatelessWidget {
  const MapActionButtons({
    super.key,
    required this.isLocating,
    required this.onLocate,
    this.onShowAll,
  });

  final bool isLocating;
  final VoidCallback onLocate;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (onShowAll != null) ...[
          FloatingActionButton.small(
            heroTag: 'show-all',
            tooltip: 'Show all places',
            onPressed: onShowAll,
            child: const Icon(Icons.zoom_out_map),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'my-location',
          tooltip: 'My location',
          onPressed: isLocating ? null : onLocate,
          child: isLocating
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
