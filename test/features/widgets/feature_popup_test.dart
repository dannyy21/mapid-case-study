import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapid_case_study/data/models/layer_feature.dart';
import 'package:mapid_case_study/features/map/widgets/feature_popup.dart';

void main() {
  Future<void> pumpPopup(
    WidgetTester tester,
    LayerFeature feature, {
    VoidCallback? onClose,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FeaturePopup(feature: feature, onClose: onClose ?? () {}),
          ),
        ),
      ),
    );
  }

  LayerFeature feature(Map<String, String> properties) => LayerFeature(
    id: 'f-1',
    latitude: -7.8,
    longitude: 110.37,
    properties: properties,
  );

  testWidgets('shows the feature attributes', (tester) async {
    await pumpPopup(
      tester,
      feature({
        'NAMA': 'TAMAN BUDAYA YOGYAKARTA',
        'ALAMAT': 'JL. SRIWEDANI NO.1',
        'KECAMATAN': 'GONDOMANAN',
        'KABKOT': 'KOTA YOGYAKARTA',
        'WAKTU': 'Q2 2024',
      }),
    );

    expect(find.text('TAMAN BUDAYA YOGYAKARTA'), findsOneWidget);
    expect(find.text('JL. SRIWEDANI NO.1'), findsOneWidget);
    expect(find.text('GONDOMANAN, KOTA YOGYAKARTA'), findsOneWidget);
    expect(find.text('Q2 2024'), findsOneWidget);
  });

  testWidgets('hides missing attributes and falls back for the name', (
    tester,
  ) async {
    await pumpPopup(tester, feature({'KABKOT': 'KOTA YOGYAKARTA'}));

    expect(find.text('Unnamed location'), findsOneWidget);
    expect(find.text('KOTA YOGYAKARTA'), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(find.byIcon(Icons.event_outlined), findsNothing);
  });

  testWidgets('calls onClose when the close button is tapped', (tester) async {
    var closed = false;
    await pumpPopup(
      tester,
      feature({'NAMA': 'TAMAN VREDEBURG'}),
      onClose: () => closed = true,
    );

    await tester.tap(find.byTooltip('Close'));

    expect(closed, isTrue);
  });
}
