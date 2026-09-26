import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/models/layer_feature.dart';
import '../map_layer_renderer.dart';
import 'feature_popup.dart';

class FeaturePopupLayer extends StatefulWidget {
  const FeaturePopupLayer({
    super.key,
    required this.renderer,
    required this.feature,
    required this.onClose,
  });

  final MapLayerRenderer renderer;
  final LayerFeature feature;
  final VoidCallback onClose;

  @override
  State<FeaturePopupLayer> createState() => _FeaturePopupLayerState();
}

class _FeaturePopupLayerState extends State<FeaturePopupLayer> {
  static const _pointClearance = 14.0;
  static const _screenMargin = 12.0;
  static const _maxResizeFrames = 30;

  final _popupKey = GlobalKey();
  late double _mapPixelRatio;
  Size? _layoutSize;
  Offset? _anchor;
  bool _revealPending = true;
  bool _updateRunning = false;
  bool _updatePending = false;

  @override
  void initState() {
    super.initState();
    widget.renderer.addCameraListener(_updateAnchor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mapPixelRatio = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1;
  }

  @override
  void didUpdateWidget(FeaturePopupLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feature != widget.feature) {
      _anchor = null;
      _revealPending = true;
      _updateAnchor();
    }
  }

  @override
  void dispose() {
    widget.renderer.removeCameraListener(_updateAnchor);
    super.dispose();
  }

  Future<void> _updateAnchor() async {
    if (_updateRunning) {
      _updatePending = true;
      return;
    }
    _updateRunning = true;
    do {
      _updatePending = false;
      await _projectFeature();
    } while (_updatePending && mounted);
    _updateRunning = false;
  }

  Future<void> _projectFeature() async {
    final feature = widget.feature;
    final anchor = await widget.renderer.screenPositionOf(
      feature,
      pixelRatio: _mapPixelRatio,
    );
    if (!mounted || widget.feature != feature) return;
    setState(() => _anchor = anchor);

    if (_revealPending) {
      _revealPending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealPopup());
    }
  }

  void _revealPopup() {
    final popupBox = _popupKey.currentContext?.findRenderObject() as RenderBox?;
    final layerBox = context.findRenderObject() as RenderBox?;
    if (!mounted || popupBox == null || layerBox == null) return;

    final popupRect =
        popupBox.localToGlobal(Offset.zero, ancestor: layerBox) & popupBox.size;
    final overflow = _overflowOf(popupRect, layerBox.size);
    if (overflow == Offset.zero) return;

    widget.renderer.panBy(
      overflow,
      mapSize: layerBox.size,
      pixelRatio: _mapPixelRatio,
    );
  }

  static Offset _overflowOf(Rect rect, Size area) {
    final dx = rect.left < _screenMargin
        ? rect.left - _screenMargin
        : rect.right > area.width - _screenMargin
        ? rect.right - (area.width - _screenMargin)
        : 0.0;
    final dy = rect.top < _screenMargin ? rect.top - _screenMargin : 0.0;
    return Offset(dx, dy);
  }

  void _onLayoutChanged(Size size) {
    if (size == _layoutSize) return;
    _layoutSize = size;
    _revealPending = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _anchorAfterResize(size),
    );
  }

  Future<void> _anchorAfterResize(Size size) async {
    for (var frame = 0; frame < _maxResizeFrames; frame++) {
      if (!mounted || size != _layoutSize) return;
      final resized = await widget.renderer.hasViewportSize(
        size,
        pixelRatio: _mapPixelRatio,
      );
      if (resized) break;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted && size == _layoutSize) await _updateAnchor();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _onLayoutChanged(constraints.biggest);
        final anchor = _anchor;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (anchor != null)
              Positioned(
                left: anchor.dx,
                top: anchor.dy - _pointClearance,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1),
                  child: FeaturePopup(
                    key: _popupKey,
                    feature: widget.feature,
                    onClose: widget.onClose,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
