import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('AppCheckbox', () {
    testWidgets('renders label and unchecked state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCheckbox(
              label: 'Buy milk',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Buy milk'), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('tap toggles from unchecked to checked', (tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AppCheckbox(
                  label: 'Buy milk',
                  value: currentValue,
                  onChanged: (v) => setState(() => currentValue = v ?? false),
                ),
              ),
            );
          },
        ),
      );

      expect(currentValue, isFalse);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(currentValue, isTrue);
    });

    testWidgets('tap toggles from checked to unchecked', (tester) async {
      bool currentValue = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AppCheckbox(
                  label: 'Buy milk',
                  value: currentValue,
                  onChanged: (v) => setState(() => currentValue = v ?? true),
                ),
              ),
            );
          },
        ),
      );

      expect(currentValue, isTrue);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(currentValue, isFalse);
    });

    testWidgets('tapping InkWell also toggles checkbox', (tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AppCheckbox(
                  label: 'Buy milk',
                  value: currentValue,
                  onChanged: (v) => setState(() => currentValue = v ?? false),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(currentValue, isTrue);
    });
  });

  group('ColorPickerRow', () {
    testWidgets('renders all 8 color circles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPickerRow(
              selectedColor: AppColors.listColors[0],
              onColorChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNWidgets(AppColors.listColors.length));
    });

    testWidgets('fires onColorChanged callback when a circle is tapped',
        (tester) async {
      int? tappedColor;
      const targetIndex = 3;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ColorPickerRow(
                selectedColor: AppColors.listColors[0],
                onColorChanged: (c) => tappedColor = c,
              ),
            ),
          ),
        ),
      );

      final circles = tester.widgetList<GestureDetector>(find.byType(GestureDetector)).toList();
      await tester.tap(find.byWidget(circles[targetIndex]));
      await tester.pump();

      expect(tappedColor, equals(AppColors.listColors[targetIndex]));
    });

    testWidgets('selected circle shows a check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPickerRow(
              selectedColor: AppColors.listColors[2],
              onColorChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('fires callback with correct color value', (tester) async {
      final receivedColors = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ColorPickerRow(
                selectedColor: AppColors.listColors[0],
                onColorChanged: receivedColors.add,
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < AppColors.listColors.length; i++) {
        final circles = tester.widgetList<GestureDetector>(find.byType(GestureDetector)).toList();
        await tester.tap(find.byWidget(circles[i]));
        await tester.pump();
      }

      expect(receivedColors, equals(AppColors.listColors));
    });
  });

  group('RadiusSlider', () {
    testWidgets('renders with initial value in range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSlider(
              radiusMeters: 500,
              onRadiusChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(500));
      expect(slider.min, equals(RadiusSlider.minRadius));
      expect(slider.max, equals(RadiusSlider.maxRadius));
    });

    testWidgets('emits value within allowed range when dragged', (tester) async {
      double emittedValue = 500;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: RadiusSlider(
                  radiusMeters: emittedValue,
                  onRadiusChanged: (v) => setState(() => emittedValue = v),
                ),
              ),
            );
          },
        ),
      );

      // Drag the slider to the right to increase value.
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(emittedValue, greaterThanOrEqualTo(RadiusSlider.minRadius));
      expect(emittedValue, lessThanOrEqualTo(RadiusSlider.maxRadius));
    });

    testWidgets('displays formatted label for metres', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSlider(
              radiusMeters: 250,
              onRadiusChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('250 m'), findsWidgets);
    });

    testWidgets('displays formatted label for kilometres', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSlider(
              radiusMeters: 1200,
              onRadiusChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('1.2 km'), findsWidgets);
    });

    test('formatRadius returns metres for values below 1000', () {
      expect(RadiusSlider.formatRadius(100), '100 m');
      expect(RadiusSlider.formatRadius(500), '500 m');
      expect(RadiusSlider.formatRadius(999), '999 m');
    });

    test('formatRadius returns kilometres for values >= 1000', () {
      expect(RadiusSlider.formatRadius(1000), '1 km');
      expect(RadiusSlider.formatRadius(1500), '1.5 km');
      expect(RadiusSlider.formatRadius(2000), '2 km');
      expect(RadiusSlider.formatRadius(5000), '5 km');
    });
  });

  group('AppListTile', () {
    testWidgets('badge is hidden when incompleteCount is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppListTile(
              title: 'Groceries',
              color: AppColors.listColors[0],
              incompleteCount: 0,
            ),
          ),
        ),
      );

      // No badge container should appear when count is 0.
      expect(find.text('0'), findsNothing);
    });

    testWidgets('badge is shown when incompleteCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppListTile(
              title: 'Groceries',
              color: AppColors.listColors[0],
              incompleteCount: 5,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('location pin icon is visible when hasGeofence is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppListTile(
              title: 'Groceries',
              color: AppColors.listColors[0],
              hasGeofence: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('location pin icon is absent when hasGeofence is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppListTile(
              title: 'Groceries',
              color: AppColors.listColors[0],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('onTap callback is fired when tile is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppListTile(
              title: 'Groceries',
              color: AppColors.listColors[0],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppListTile(
              title: 'Work Tasks',
              color: AppColors.listColors[1],
            ),
          ),
        ),
      );

      expect(find.text('Work Tasks'), findsOneWidget);
    });
  });
}
