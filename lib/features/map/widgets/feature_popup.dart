import 'package:flutter/material.dart';

import '../../../data/models/feature_attribute.dart';
import '../../../data/models/layer_feature.dart';

class FeaturePopup extends StatelessWidget {
  const FeaturePopup({super.key, required this.feature, required this.onClose});

  static const maxWidth = 300.0;
  static const _arrowSize = Size(20, 10);

  final LayerFeature feature;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final region = [
      feature[FeatureAttribute.district],
      feature[FeatureAttribute.city],
    ].nonNulls.join(', ');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: surface,
            elevation: 6,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feature[FeatureAttribute.name] ?? 'Unnamed location',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
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
          ),
          CustomPaint(
            size: _arrowSize,
            painter: _ArrowPainter(color: surface),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 6, right: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
