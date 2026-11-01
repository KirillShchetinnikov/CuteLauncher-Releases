import 'package:flauncher/panel_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final combined in [false, true]) {
    test(
      'wallpaper slots survive moving visible objects: combined=$combined',
      () {
        final layout = PanelLayout(
          ['settings', 'time', 'network'],
          ['date', 'weather'],
        );
        const excluded = {'time', 'weather'};
        final (left, right) = layout.displayOrders(
          combined,
          excluded: excluded,
        );
        expect([...left, ...right], isNot(contains('time')));
        expect([...left, ...right], isNot(contains('weather')));
        left.remove('settings');
        right.add('settings');
        final (savedLeft, savedRight) = layout.expandOrders(
          left,
          right,
          excluded: excluded,
        );
        expect(savedLeft.indexOf('time'), layout.left.indexOf('time'));
        expect(savedRight.indexOf('weather'), layout.right.indexOf('weather'));
        expect(savedRight, contains('settings'));
        expect({...savedLeft, ...savedRight}, PanelLayout.ids.toSet());
        expect(savedLeft.length + savedRight.length, PanelLayout.ids.length);
      },
    );
  }

  test('new VPN slot inherits the former network position on either side', () {
    final left = PanelLayout(['settings', 'network', 'traffic'], ['date']);
    expect(left.left.take(4), ['settings', 'network', 'vpn', 'traffic']);
    final right = PanelLayout(['settings'], ['time', 'network', 'date']);
    expect(right.right, ['time', 'network', 'vpn', 'date', 'audio', 'weather']);
  });
  test('an explicitly positioned VPN is preserved', () {
    final layout = PanelLayout(['vpn', 'settings', 'network'], ['date']);
    expect(layout.left.take(3), ['vpn', 'settings', 'network']);
    expect({...layout.left, ...layout.right}.length, PanelLayout.ids.length);
  });
  test('audio is independently ordered and never swallowed by combined information', () {
    final layout = PanelLayout(
      ['settings', 'audio'],
      ['time', 'date', 'weather'],
    );
    final (left, right) = layout.displayOrders(true);
    expect(left, contains('audio'));
    expect(right, [PanelLayout.informationGroup]);
    final (expandedLeft, expandedRight) = layout.expandOrders(left, right);
    expect(expandedLeft, layout.left);
    expect(expandedRight, layout.right);
    expect(PanelLayout(null, null).right.first, 'audio');
  });
}
