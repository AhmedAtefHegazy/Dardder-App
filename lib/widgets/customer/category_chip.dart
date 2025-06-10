import 'package:flutter/material.dart';
import '../../models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Function(bool) onSelected;

  const CategoryChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      onSelected: onSelected,
      label: Text(category.name),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      elevation: isSelected ? 4 : 0,
      pressElevation: 8,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }
}
