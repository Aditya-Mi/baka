import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final Color color;
  final Color textColor;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.tag,
    required this.color,
    required this.textColor,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final removable = onRemove != null;
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: removable ? 4 : 10,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          if (removable) ...[
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 14, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
