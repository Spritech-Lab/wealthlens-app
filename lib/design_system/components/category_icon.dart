/// A category glyph on a semantic tinted background (Material Symbols only).
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';

/// A single-color Material Symbol on a soft tinted square.
///
/// Emoji and imported images are forbidden as category icons;
/// callers pass a Material Symbol and a semantic [color].
class CategoryIcon extends StatelessWidget {
  /// Creates a [CategoryIcon].
  const CategoryIcon({
    required this.icon,
    required this.color,
    this.size = 40,
    super.key,
  });

  /// The Material Symbol to render.
  final IconData icon;

  /// The semantic / category color (also tints the background).
  final Color color;

  /// Square side length.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
