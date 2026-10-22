import 'package:flutter/material.dart';

/// Component materials only. Layout, user colours and traversal are independent.
enum InterfaceStyle { standard, glass, soft, outline }

InterfaceStyle interfaceStyleFrom(String? value) => InterfaceStyle.values
    .firstWhere((s) => s.name == value, orElse: () => InterfaceStyle.standard);

@immutable
class InterfaceSkin extends ThemeExtension<InterfaceSkin> {
  final InterfaceStyle style;
  const InterfaceSkin([this.style = InterfaceStyle.standard]);
  static InterfaceSkin of(BuildContext context) =>
      Theme.of(context).extension<InterfaceSkin>() ?? const InterfaceSkin();
  bool get standard => style == InterfaceStyle.standard;
  double get radius => switch (style) {
    InterfaceStyle.standard => 14,
    InterfaceStyle.glass => 22,
    InterfaceStyle.soft => 18,
    InterfaceStyle.outline => 6,
  };

  BoxDecoration surface(
    Color base,
    Color foreground, {
    bool focused = false,
    Color? accent,
    double? cornerRadius,
    double borderWidth = 1.5,
  }) {
    final focus = accent ?? foreground;
    final fill = focused
        ? Color.alphaBlend(focus.withValues(alpha: .18), base)
        : base;
    return BoxDecoration(
      color: style == InterfaceStyle.glass ? null : fill,
      gradient: style == InterfaceStyle.glass
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  foreground.withValues(alpha: focused ? .20 : .08),
                  fill,
                ).withValues(alpha: fill.a),
                fill,
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(cornerRadius ?? radius),
      border: Border.all(
        color: focused
            ? focus
            : foreground.withValues(
                alpha: style == InterfaceStyle.outline
                    ? .30
                    : style == InterfaceStyle.glass
                    ? .16
                    : 0,
              ),
        width: borderWidth,
      ),
      boxShadow: switch (style) {
        InterfaceStyle.glass => [
          BoxShadow(
            color: Colors.black.withValues(alpha: focused ? .32 : .18),
            blurRadius: focused ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
        InterfaceStyle.soft when focused => [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        _ => null,
      },
    );
  }

  ThemeData apply(ThemeData theme) {
    if (standard) return theme;
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    ButtonStyle button(ButtonStyle? base) =>
        (base ?? const ButtonStyle()).copyWith(
          shape: WidgetStatePropertyAll(shape),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => colors.onSurface.withValues(
              alpha: states.contains(WidgetState.focused) ? .18 : .055,
            ),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? colors.primary
                  : colors.onSurface.withValues(
                      alpha: style == InterfaceStyle.outline ? .35 : .10,
                    ),
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
          elevation: WidgetStatePropertyAll(
            style == InterfaceStyle.glass ? 3 : 0,
          ),
          shadowColor: const WidgetStatePropertyAll(Colors.black38),
        );
    return theme.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: button(theme.textButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: button(theme.elevatedButtonTheme.style),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: button(theme.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button(theme.outlinedButtonTheme.style),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: button(theme.iconButtonTheme.style),
      ),
      sliderTheme: theme.sliderTheme.copyWith(
        trackHeight: style == InterfaceStyle.soft
            ? 9
            : style == InterfaceStyle.outline
            ? 3
            : 6,
        thumbShape: SkinSliderThumb(style),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: theme.switchTheme.copyWith(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => style == InterfaceStyle.outline
              ? colors.onSurface.withValues(alpha: .55)
              : Colors.transparent,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
        thumbIcon: style == InterfaceStyle.outline
            ? WidgetStateProperty.resolveWith(
                (states) => Icon(
                  states.contains(WidgetState.selected)
                      ? Icons.check
                      : Icons.remove,
                  color: colors.onPrimary,
                  size: 14,
                ),
              )
            : null,
        padding: EdgeInsets.zero,
      ),
      dialogTheme: theme.dialogTheme.copyWith(
        shape: shape,
        elevation: style == InterfaceStyle.outline ? 0 : 16,
      ),
      popupMenuTheme: theme.popupMenuTheme.copyWith(shape: shape),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colors.onSurface.withValues(alpha: .05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }

  @override
  InterfaceSkin copyWith({InterfaceStyle? style}) =>
      InterfaceSkin(style ?? this.style);
  @override
  InterfaceSkin lerp(covariant InterfaceSkin? other, double t) =>
      t < .5 ? this : other ?? this;
}

class SkinSliderThumb extends SliderComponentShape {
  final InterfaceStyle style;
  const SkinSliderThumb(this.style);
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final color =
        Color.lerp(
          sliderTheme.disabledThumbColor,
          sliderTheme.thumbColor,
          enableAnimation.value,
        ) ??
        Colors.white;
    if (style == InterfaceStyle.outline) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 10, height: 22),
          const Radius.circular(3),
        ),
        Paint()..color = color,
      );
    } else {
      final path = Path()..addOval(Rect.fromCircle(center: center, radius: 12));
      if (style == InterfaceStyle.glass) {
        canvas.drawShadow(path, Colors.black54, 3, true);
      }
      canvas.drawCircle(center, 12, Paint()..color = color);
      if (style == InterfaceStyle.glass) {
        canvas.drawCircle(
          center.translate(0, -2),
          9,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: .6), Colors.transparent],
            ).createShader(Rect.fromCircle(center: center, radius: 12)),
        );
      } else {
        canvas.drawCircle(
          center,
          5,
          Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey,
        );
      }
    }
  }
}

/// Decorative switch; its enclosing settings row owns activation and semantics.
class SkinSwitch extends StatelessWidget {
  final bool value, enabled;
  const SkinSwitch({super.key, required this.value, this.enabled = true});
  @override
  Widget build(BuildContext context) {
    final skin = InterfaceSkin.of(context);
    final colors = Theme.of(context).colorScheme;
    final outline = skin.style == InterfaceStyle.outline;
    final glass = skin.style == InterfaceStyle.glass;
    final radius = outline
        ? 5.0
        : glass
        ? 20.0
        : 9.0;
    final fill = value
        ? colors.primary
        : colors.onSurface.withValues(alpha: .2);
    final knob = value ? colors.onPrimary : colors.onSurface;
    return Opacity(
      opacity: enabled ? 1 : .38,
      child: Container(
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: outline
              ? Border.all(color: colors.onSurface.withValues(alpha: .5))
              : null,
          gradient: glass
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.alphaBlend(Colors.white24, fill), fill],
                )
              : null,
        ),
        child: AnimatedAlign(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: outline ? 15 : 20,
            height: 20,
            decoration: BoxDecoration(
              color: knob,
              borderRadius: BorderRadius.circular(
                outline
                    ? 2
                    : glass
                    ? 20
                    : 6,
              ),
              boxShadow: glass
                  ? const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
