import 'package:flutter/material.dart';

import '../../domain/models/graduated_commitment.dart';

/// The visual state of a level node on the roadmap.
enum LevelNodeState { completed, current, locked }

/// Individual level node displayed on the journey roadmap.
class LevelNode extends StatefulWidget {
  const LevelNode({
    super.key,
    required this.level,
    required this.nodeState,
    required this.tier,
    this.onTap,
    this.size = 48,
  });

  final int level;
  final LevelNodeState nodeState;
  final CommitmentTier tier;
  final VoidCallback? onTap;
  final double size;

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.nodeState == LevelNodeState.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nodeState == LevelNodeState.current &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.nodeState != LevelNodeState.current) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget node = _buildNode(theme);

    if (widget.nodeState == LevelNodeState.current) {
      node = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: node,
      );
    }

    return GestureDetector(
      onTap: widget.nodeState != LevelNodeState.locked ? widget.onTap : null,
      child: node,
    );
  }

  Widget _buildNode(ThemeData theme) {
    switch (widget.nodeState) {
      case LevelNodeState.completed:
        return _CompletedNode(
          size: widget.size,
          color: widget.tier.color,
          level: widget.level,
        );
      case LevelNodeState.current:
        return _CurrentNode(
          size: widget.size,
          color: widget.tier.color,
          level: widget.level,
        );
      case LevelNodeState.locked:
        return _LockedNode(
          size: widget.size,
          level: widget.level,
        );
    }
  }
}

class _CompletedNode extends StatelessWidget {
  const _CompletedNode({
    required this.size,
    required this.color,
    required this.level,
  });

  final double size;
  final Color color;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

class _CurrentNode extends StatelessWidget {
  const _CurrentNode({
    required this.size,
    required this.color,
    required this.level,
  });

  final double size;
  final Color color;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

class _LockedNode extends StatelessWidget {
  const _LockedNode({
    required this.size,
    required this.level,
  });

  final double size;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.dividerColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            fontWeight: FontWeight.w500,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
