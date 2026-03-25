import 'package:flutter/material.dart';

/// Animates text appearing word-by-word with fade and slide effects.
class VerseRevealAnimation extends StatefulWidget {
  const VerseRevealAnimation({
    super.key,
    required this.text,
    this.style,
    this.wordDuration = const Duration(milliseconds: 120),
    this.onComplete,
  });

  final String text;
  final TextStyle? style;
  final Duration wordDuration;
  final VoidCallback? onComplete;

  @override
  State<VerseRevealAnimation> createState() => VerseRevealAnimationState();
}

class VerseRevealAnimationState extends State<VerseRevealAnimation>
    with TickerProviderStateMixin {
  late List<String> _words;
  int _visibleCount = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(' ');
    _startReveal();
  }

  @override
  void didUpdateWidget(VerseRevealAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _words = widget.text.split(' ');
      _visibleCount = 0;
      _startReveal();
    }
  }

  void _startReveal() async {
    if (_isAnimating) return;
    _isAnimating = true;

    for (int i = 0; i < _words.length; i++) {
      if (!mounted) return;
      await Future.delayed(widget.wordDuration);
      if (!mounted) return;
      setState(() => _visibleCount = i + 1);
    }

    _isAnimating = false;
    widget.onComplete?.call();
  }

  void skipToEnd() {
    setState(() {
      _visibleCount = _words.length;
      _isAnimating = false;
    });
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w500,
            );

    return GestureDetector(
      onTap: _isAnimating ? skipToEnd : null,
      child: Wrap(
        children: List.generate(_words.length, (index) {
          final isVisible = index < _visibleCount;
          return AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 0.15),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  _words[index],
                  style: defaultStyle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
