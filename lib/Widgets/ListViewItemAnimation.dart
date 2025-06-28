import 'package:flutter/material.dart';

class ListViewItemAnimation extends StatefulWidget {
  final int index;
  final Widget child;

  const ListViewItemAnimation(
      {super.key, required this.index, required this.child});

  @override
  _ListViewItemAnimationState createState() => _ListViewItemAnimationState();
}

class _ListViewItemAnimationState extends State<ListViewItemAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Staggered timing based on item index
    final double delay = 0.2 * widget.index;
    final curve = Curves.easeOutQuint;

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, delay + 0.4, curve: curve),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, delay + 0.5, curve: curve),
      ),
    );

    // Slight delay before starting the animation for a staggered effect
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 50,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
