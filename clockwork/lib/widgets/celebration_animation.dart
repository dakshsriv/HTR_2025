import 'package:flutter/material.dart';
import 'dart:math';

/// Quick, attention-grabbing celebration animation for task completion.
/// Shows animated confetti-like particles that burst outward from center.
class CelebrationAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const CelebrationAnimation({
    this.onComplete,
    super.key,
  });

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late List<AnimationController> _particleControllers;

  @override
  void initState() {
    super.initState();

    // Main scale pulse animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    // Fade out animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    // Particle animations (6 particles bursting outward)
    _particleControllers = List.generate(
      6,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      )..forward(),
    );

    // Trigger callback when complete
    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main celebration circle with scale pulse
        ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
            ),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade400,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 80,
                    color: Colors.green.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Burst particles
        ..._buildParticles(),

        // Center celebration text with pulse
        ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.1).animate(
            CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Text(
                  'Actually did it 🔥',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build particle burst animations
  List<Widget> _buildParticles() {
    final particles = <Widget>[];
    final emojis = ['🎉', '⭐', '🚀', '💪', '🔥', '✨'];

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180); // Convert to radians
      final distance = 150.0;
      final endX = distance * cos(angle);
      final endY = distance * sin(angle);

      particles.add(
        Positioned(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0),
              end: Offset(endX / 100, endY / 100),
            ).animate(
              CurvedAnimation(
                parent: _particleControllers[i],
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                  parent: _particleControllers[i],
                  curve: const Interval(0.6, 1.0),
                ),
              ),
              child: Text(
                emojis[i],
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}
