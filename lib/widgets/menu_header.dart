import 'package:flutter/material.dart';

/// Shared widget-menu header. Only control hints need an extra line.
class MenuHeader extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;
  final Widget? hint;

  const MenuHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.titleLarge,
            child: title,
          ),
        ),
        ...actions,
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconButtonTheme(
          data: IconButtonThemeData(
            style: (IconButtonTheme.of(context).style ?? const ButtonStyle())
                .copyWith(
                  minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
                  padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                ),
          ),
          child: row,
        ),
        if (hint != null) ...[const SizedBox(height: 4), hint!],
      ],
    );
  }
}
