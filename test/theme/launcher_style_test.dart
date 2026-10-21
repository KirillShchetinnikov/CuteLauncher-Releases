import 'package:flauncher/theme/launcher_style.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit zero wins over theme and custom base geometry', () {
    final style = const LauncherStyle().copyWith(tileRadius: 25);
    expect(style.tileCorners('modern').topLeft.x, 25);
    expect(style.tileCorners('classic'), BorderRadius.zero);
    for (final theme in ['classic', 'modern', 'premium', 'capsule']) {
      expect(style.tileCorners(theme, radius: 0), BorderRadius.zero);
      expect(style.tileInnerCorners(theme, radius: 0), BorderRadius.zero);
      expect(style.tileCorners(theme, radius: 30).topLeft.x, 30);
      expect(style.tileInnerCorners(theme, radius: 30).topLeft.x, 28);
    }
  });

  test(
    'theme interpolation preserves endpoints and blends motion and geometry',
    () {
      const first = LauncherStyle();
      final second = first.copyWith(
        rowRadius: 0,
        rowFocusColor: Colors.black,
        rowDuration: Duration.zero,
        rowPadding: EdgeInsets.zero,
      );
      expect(first.lerp(second, 0).rowRadius, first.rowRadius);
      expect(first.lerp(second, 1).rowRadius, 0);
      expect(first.lerp(second, .5).rowDuration.inMilliseconds, 80);
      expect(first.lerp(second, .5).rowPadding.horizontal, 12);
      expect(
        first.lerp(second, .5).rowFocusColor,
        Color.lerp(first.rowFocusColor, Colors.black, .5),
      );
      expect(first.lerp(null, .5), same(first));
    },
  );

  test('explicit focus growth is the same for every tile theme', () {
    const style = LauncherStyle();
    const appearance = TileAppearance({
      'focusEffect': 'scale',
      'focusStrength': .35,
      'horizontalGap': 16,
      'verticalGap': 16,
    });
    for (final theme in ['classic', 'modern', 'premium', 'capsule']) {
      expect(
        style.tileFocusScale(theme, appearance, width: 200, focused: true),
        1.35,
      );
      expect(
        style.tileFocusScale(theme, appearance, width: 200, focused: false),
        1,
      );
    }
    expect(
      style.tileFocusScale(
        'classic',
        const TileAppearance(),
        width: 200,
        focused: true,
      ),
      1.1,
    );
    expect(
      style.tileFocusScale(
        'premium',
        const TileAppearance(),
        width: 200,
        focused: true,
      ),
      closeTo(1.1, .000001),
    );
  });

  testWidgets(
    'ordinary ThemeData has safe fallback and extension overrides it',
    (tester) async {
      late LauncherStyle style;
      Future<void> pump(ThemeData theme) => tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              style = LauncherStyle.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await pump(ThemeData());
      expect(style.tileCorners('modern').topLeft.x, 14);
      await pump(ThemeData(extensions: const [LauncherStyle(tileRadius: 0)]));
      await tester.pumpAndSettle();
      expect(style.tileCorners('modern'), BorderRadius.zero);
    },
  );
}
