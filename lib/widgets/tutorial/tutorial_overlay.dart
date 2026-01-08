import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Étape du tutoriel
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final IconData icon;
  final Alignment tooltipAlignment;
  final bool showArrow;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetKey,
    required this.icon,
    this.tooltipAlignment = Alignment.center,
    this.showArrow = true,
  });
}

/// Overlay de tutoriel qui met en surbrillance les éléments
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    await _animController.reverse();

    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      await _animController.forward();
    } else {
      widget.onComplete();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      await _animController.reverse();
      setState(() {
        _currentStep--;
      });
      await _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final targetRect = _getTargetRect(step.targetKey);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Fond sombre avec découpe
          _buildOverlay(targetRect),

          // Tooltip
          _buildTooltip(step, targetRect),

          // Bouton Skip
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TextButton(
                onPressed: widget.onSkip ?? widget.onComplete,
                child: const Text(
                  'Passer',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect? _getTargetRect(GlobalKey? key) {
    if (key == null) return null;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  Widget _buildOverlay(Rect? targetRect) {
    return ListenableBuilder(
      listenable: _fadeAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _OverlayPainter(
            targetRect: targetRect,
            opacity: _fadeAnimation.value * 0.85,
          ),
        );
      },
    );
  }

  Widget _buildTooltip(TutorialStep step, Rect? targetRect) {
    final screenSize = MediaQuery.of(context).size;

    // Calculer la position du tooltip
    double top;
    const double left = 24;
    const double right = 24;

    if (targetRect != null) {
      // Positionner le tooltip au-dessus ou en dessous de l'élément
      if (targetRect.center.dy > screenSize.height / 2) {
        top = targetRect.top - 200;
      } else {
        top = targetRect.bottom + 20;
      }
    } else {
      top = screenSize.height / 2 - 100;
    }

    return Positioned(
      top: top.clamp(100, screenSize.height - 300),
      left: left,
      right: right,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Titre
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Indicateur de progression
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.steps.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentStep
                            ? AppColors.primary
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Boutons navigation
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Précédent'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 1,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _currentStep == widget.steps.length - 1
                              ? 'Commencer !'
                              : 'Suivant',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter pour dessiner l'overlay avec découpe
class _OverlayPainter extends CustomPainter {
  final Rect? targetRect;
  final double opacity;

  _OverlayPainter({
    this.targetRect,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      // Créer un trou avec des bords arrondis
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            targetRect!.inflate(8),
            const Radius.circular(12),
          ),
        );

      path.addPath(holePath, Offset.zero);
      canvas.drawPath(
        Path.combine(PathOperation.difference, path, holePath),
        paint,
      );

      // Dessiner une bordure autour de l'élément ciblé
      final borderPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          targetRect!.inflate(8),
          const Radius.circular(12),
        ),
        borderPaint,
      );
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.opacity != opacity;
  }
}
