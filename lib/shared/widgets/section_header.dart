import 'package:flutter/material.dart';

/// A reusable section header with a title and optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (actionLabel != null || actionIcon != null)
          TextButton.icon(
            onPressed: onAction,
            icon: actionIcon != null
                ? Icon(actionIcon, size: 18)
                : const SizedBox.shrink(),
            label: Text(actionLabel ?? ''),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
