import 'package:flutter/material.dart';

import '../../../data/models/feature_attribute.dart';
import '../../../data/models/layer_feature.dart';

class FeaturePopup extends StatelessWidget {
  const FeaturePopup({super.key, required this.feature, required this.onClose});

  final LayerFeature feature;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = [
      feature[FeatureAttribute.district],
      feature[FeatureAttribute.city],
    ].nonNulls.join(', ');

    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feature[FeatureAttribute.name] ?? 'Unnamed location',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            _AttributeRow(
              icon: Icons.place_outlined,
              value: feature[FeatureAttribute.address],
            ),
            _AttributeRow(
              icon: Icons.map_outlined,
              value: region.isEmpty ? null : region,
            ),
            _AttributeRow(
              icon: Icons.event_outlined,
              value: feature[FeatureAttribute.period],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.icon, required this.value});

  final IconData icon;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
