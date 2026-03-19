import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class TabButton extends StatelessWidget {
  const TabButton({super.key, 
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.chipText.copyWith(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
