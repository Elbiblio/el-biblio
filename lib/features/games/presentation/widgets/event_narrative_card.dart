import 'package:flutter/material.dart';

class EventNarrativeCard extends StatefulWidget {
  final String narrative;
  final Color themeColor;

  const EventNarrativeCard({
    super.key,
    required this.narrative,
    required this.themeColor,
  });

  @override
  State<EventNarrativeCard> createState() => _EventNarrativeCardState();
}

class _EventNarrativeCardState extends State<EventNarrativeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? widget.themeColor.withValues(alpha: 0.1)
              : widget.themeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.themeColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          widget.narrative,
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
