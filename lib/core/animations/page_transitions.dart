import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Types de transitions disponibles
enum TransitionType {
  fade,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  scale,
  scaleWithFade,
  rotation,
  none,
}

/// Durées d'animation
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
}

/// Courbes d'animation personnalisées
class AnimationCurves {
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bouncy = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutQuart;
  static const Curve sharp = Curves.easeInOutQuart;
}

/// Builders de transitions
class TransitionBuilders {
  // Transition Fade
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AnimationCurves.defaultCurve,
      ),
      child: child,
    );
  }

  // Slide depuis la droite (navigation forward)
  static Widget slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    final curvedSecondaryAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AnimationCurves.smooth,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(curvedSecondaryAnimation),
        child: child,
      ),
    );
  }

  // Slide depuis la gauche (navigation back)
  static Widget slideLeftTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }

  // Slide depuis le bas (modals, overlays)
  static Widget slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  // Slide depuis le haut
  static Widget slideDownTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, -1.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }

  // Scale (zoom in)
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
      child: child,
    );
  }

  // Scale avec fade
  static Widget scaleWithFadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  // Rotation
  static Widget rotationTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationCurves.smooth,
    );

    return RotationTransition(
      turns: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // Pas de transition
  static Widget noTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  /// Récupère le builder pour un type de transition
  static RouteTransitionsBuilder getBuilder(TransitionType type) {
    switch (type) {
      case TransitionType.fade:
        return fadeTransition;
      case TransitionType.slideRight:
        return slideRightTransition;
      case TransitionType.slideLeft:
        return slideLeftTransition;
      case TransitionType.slideUp:
        return slideUpTransition;
      case TransitionType.slideDown:
        return slideDownTransition;
      case TransitionType.scale:
        return scaleTransition;
      case TransitionType.scaleWithFade:
        return scaleWithFadeTransition;
      case TransitionType.rotation:
        return rotationTransition;
      case TransitionType.none:
        return noTransition;
    }
  }
}

/// Crée une page avec transition personnalisée pour go_router
CustomTransitionPage<T> buildTransitionPage<T>({
  required Widget child,
  required LocalKey? key,
  TransitionType type = TransitionType.slideRight,
  Duration transitionDuration = AnimationDurations.normal,
  Duration reverseTransitionDuration = AnimationDurations.normal,
  String? name,
  Object? arguments,
  String? restorationId,
}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionsBuilder: TransitionBuilders.getBuilder(type),
  );
}

/// Helper pour créer des GoRoutes avec transitions
GoRoute transitionRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  TransitionType transition = TransitionType.slideRight,
  Duration duration = AnimationDurations.normal,
  String? name,
  List<RouteBase>? routes,
}) {
  return GoRoute(
    path: path,
    name: name,
    routes: routes ?? [],
    pageBuilder: (context, state) => buildTransitionPage(
      key: state.pageKey,
      name: name,
      child: builder(context, state),
      type: transition,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    ),
  );
}

/// Transitions spécifiques par type de page
class PageTransitions {
  /// Transition pour les écrans principaux (tabs)
  static TransitionType get main => TransitionType.fade;

  /// Transition pour la navigation forward
  static TransitionType get forward => TransitionType.slideRight;

  /// Transition pour les modals/dialogs
  static TransitionType get modal => TransitionType.slideUp;

  /// Transition pour les formulaires
  static TransitionType get form => TransitionType.slideRight;

  /// Transition pour les détails
  static TransitionType get detail => TransitionType.scaleWithFade;

  /// Transition pour les paramètres
  static TransitionType get settings => TransitionType.slideRight;

  /// Transition pour le premium/paywall
  static TransitionType get premium => TransitionType.slideUp;
}
