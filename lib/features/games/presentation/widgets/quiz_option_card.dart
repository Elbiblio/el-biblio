import 'package:flutter/material.dart';

class QuizOptionCard extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool? isCorrect;
  final bool showResult;
  final int correctIndex;
  final VoidCallback? onTap;

  const QuizOptionCard({
    super.key,
    required this.text,
    required this.index,
    required this.correctIndex,
    this.isSelected = false,
    this.isCorrect,
    this.showResult = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;

    if (showResult) {
      if (index == correctIndex) {
        // This is the correct answer
        bgColor = Colors.green.withValues(alpha: 0.15);
        borderColor = Colors.green;
        textColor = isDark ? Colors.green.shade300 : Colors.green.shade800;
        trailingIcon = Icons.check_circle;
      } else if (isSelected && isCorrect == false) {
        // Selected but wrong
        bgColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red.shade300;
        textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
        trailingIcon = Icons.cancel;
      } else {
        // Not selected, not correct
        bgColor = isDark ? const Color(0xFF1e293b) : Colors.white;
        borderColor =
            isDark ? const Color(0xFF334155) : const Color(0xFFe0e0e0);
        textColor = isDark ? Colors.white38 : Colors.black38;
        trailingIcon = null;
      }
    } else {
      bgColor = isDark ? const Color(0xFF1e293b) : Colors.white;
      borderColor =
          isDark ? const Color(0xFF334155) : const Color(0xFFe0e0e0);
      textColor = isDark ? Colors.white : Colors.black87;
      trailingIcon = null;
    }

    final label = String.fromCharCode(65 + index); // A, B, C, D

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: showResult ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    color: index == correctIndex
                        ? Colors.green
                        : Colors.red,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
