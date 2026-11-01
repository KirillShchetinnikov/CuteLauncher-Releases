import 'package:flutter/widgets.dart';

final _targets = Expando<double>('home scroll target');

/// All home sections share the same motion on their enclosing viewport.
/// Repeated focus notifications must not restart an in-flight reveal.
void revealHomeOffset(
  BuildContext context,
  ScrollPosition position,
  double offset,
) {
  final target = offset.clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if (MediaQuery.disableAnimationsOf(context)) {
    _targets[position] = null;
    if (position.pixels != target || position.isScrollingNotifier.value) {
      position.jumpTo(target);
    }
    return;
  }
  final pending = _targets[position];
  if (position.isScrollingNotifier.value &&
      pending != null &&
      (pending - target).abs() <= .5) {
    return;
  }
  // A reversal may ask to stay at the current offset while the old animation
  // is still heading elsewhere. Cancel that motion instead of ignoring it.
  if ((target - position.pixels).abs() <= .5) {
    _targets[position] = null;
    if (position.isScrollingNotifier.value) position.jumpTo(target);
    return;
  }
  _targets[position] = target;
  position
      .animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      )
      .whenComplete(() {
        if (_targets[position] == target &&
            !position.isScrollingNotifier.value) {
          _targets[position] = null;
        }
      });
}
