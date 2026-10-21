import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../category_appearance.dart';
import '../providers/appearance_service.dart';

class CategorySurface extends StatelessWidget {
  final int categoryId;
  final Widget child;
  const CategorySurface({
    super.key,
    required this.categoryId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        context.watch<AppearanceService?>()?.category(categoryId) ??
        const CategoryAppearance();
    return Container(
      color: style.background,
      padding: EdgeInsets.all(style.padding),
      child: child,
    );
  }
}
