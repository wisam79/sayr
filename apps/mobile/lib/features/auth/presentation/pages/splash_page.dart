import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Splash screen showing entry animation with S-road and high-speed trails.
class SplashPage extends StatefulWidget {
  /// Constructor for [SplashPage].
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _speedController;
  late final Animation<double> _shockwaveRadius;
  late final Animation<double> _shockwaveOpacity;
  late final Animation<double> _roadProgress;

  // Pre-computed path metrics (computed once, reused every frame)
  late final List<ui.PathMetric> _pathMetricsLeft;
  late final List<ui.PathMetric> _pathMetricsRight;

  // List of particles for the high-speed wind effect
  final List<_SpeedParticle> _particles = [];
  final int _particleCount = 25;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Pre-compute the S-road paths and cache their metrics to avoid
    // expensive repeated calls to computeMetrics() inside paint().
    _pathMetricsLeft = (Path()
          ..moveTo(256, 256)
          ..lineTo(208, 220)
          ..arcToPoint(
            const Offset(256, 76),
            radius: const Radius.circular(80),
          )
          ..lineTo(512, 76))
        .computeMetrics()
        .toList();

    _pathMetricsRight = (Path()
          ..moveTo(256, 256)
          ..lineTo(304, 292)
          ..arcToPoint(
            const Offset(256, 436),
            radius: const Radius.circular(80),
          )
          ..lineTo(0, 436))
        .computeMetrics()
        .toList();

    // Entry animation — 1.2s: fast enough to feel snappy,
    // long enough for the S-road to draw impressively.
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Speed particles & trails continuous controller
    _speedController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _speedController.repeat();
    }

    // Shockwave fires instantly and fades by 45% of entry duration
    _shockwaveRadius = Tween<double>(begin: 0, end: 220).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _shockwaveOpacity = Tween<double>(begin: 0.8, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );

    // Road draws from 0% to 75% — fast start, decelerates smoothly
    _roadProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // textOpacity field removed — progress bar not shown on short animation.

    _initializeParticles();

    // Delay animation start until after the very first frame is committed.
    // This allows the GPU (Impeller/Vulkan) to finish its warm-up so the
    // first animation frame does not trigger a Davey! jank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Navigate exactly when the entry animation completes —
      // zero freeze frames.
      _entryController.forward().then((_) => _navigateToNext());
    });
  }

  void _initializeParticles() {
    for (var i = 0; i < _particleCount; i++) {
      _particles.add(
        _SpeedParticle(
          startX: _random.nextDouble() * 1.5 - 0.25,
          startY: _random.nextDouble() * 1.5 - 0.25,
          speed: _random.nextDouble() * 1.5 + 0.5,
          length: _random.nextDouble() * 100 + 40,
          width: _random.nextDouble() * 2 + 1,
          opacity: _random.nextDouble() * 0.4 + 0.1,
          isBlue: _random.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _speedController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background High-Speed Light Trails and Particles
          AnimatedBuilder(
            animation: _speedController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _SpeedTunnelPainter(
                  particles: _particles,
                  progress: _speedController.value,
                ),
              );
            },
          ),

          // High-Speed Shockwave Ring
          AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) {
              return Opacity(
                opacity: _shockwaveOpacity.value,
                child: Container(
                  width: _shockwaveRadius.value,
                  height: _shockwaveRadius.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated Full-Width S-Road
          AnimatedBuilder(
            animation: _roadProgress,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _SRoadPainter(
                  progress: _roadProgress.value,
                  pathMetricsLeft: _pathMetricsLeft,
                  pathMetricsRight: _pathMetricsRight,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SpeedParticle {
  _SpeedParticle({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.length,
    required this.width,
    required this.opacity,
    required this.isBlue,
  });

  final double startX;
  final double startY;
  final double speed;
  final double length;
  final double width;
  final double opacity;
  final bool isBlue;
}

class _SpeedTunnelPainter extends CustomPainter {
  _SpeedTunnelPainter({
    required this.particles,
    required this.progress,
  });

  final List<_SpeedParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()..style = PaintingStyle.stroke;
    final bluePaint = Paint()..style = PaintingStyle.stroke;

    for (final p in particles) {
      final currentProgress = (progress * p.speed) % 1.0;
      final x = (p.startX + currentProgress * 0.8) * size.width;
      final y = (p.startY - currentProgress * 0.8) * size.height;

      final dx = p.length * 0.707;
      final dy = p.length * 0.707;

      final color = p.isBlue
          ? const Color(0xFF34D399).withValues(alpha: p.opacity)
          : AppColors.primary.withValues(alpha: p.opacity);

      final paint = (p.isBlue ? bluePaint : greenPaint)
        ..color = color
        ..strokeWidth = p.width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, y), Offset(x - dx, y + dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Paints the animated S-road shape using pre-computed path metrics.
///
/// Accepts cached [pathMetricsLeft] and [pathMetricsRight] to avoid the
/// expensive [Path.computeMetrics] call on every frame.
class _SRoadPainter extends CustomPainter {
  /// Creates the road painter with pre-computed path metrics.
  _SRoadPainter({
    required this.progress,
    required this.pathMetricsLeft,
    required this.pathMetricsRight,
  });

  /// Draw progress from 0.0 to 1.0.
  final double progress;

  /// Pre-computed metrics for the left road segment.
  final List<ui.PathMetric> pathMetricsLeft;

  /// Pre-computed metrics for the right road segment.
  final List<ui.PathMetric> pathMetricsRight;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 512.0;

    canvas
      ..save()
      ..translate(centerX, centerY)
      ..rotate(20 * math.pi / 180)
      ..scale(scale, scale)
      ..translate(-256, -256);

    // Road paint (thick green lane)
    final roadPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 64.0
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    // White dashed center line paint
    final dividerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.butt;

    _drawAnimatedMetrics(canvas, pathMetricsLeft, roadPaint);
    _drawAnimatedMetrics(canvas, pathMetricsRight, roadPaint);
    _drawAnimatedDashedMetrics(canvas, pathMetricsLeft, dividerPaint);
    _drawAnimatedDashedMetrics(canvas, pathMetricsRight, dividerPaint);

    canvas.restore();
  }

  void _drawAnimatedMetrics(
    Canvas canvas,
    List<ui.PathMetric> metrics,
    Paint paint,
  ) {
    for (final metric in metrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  void _drawAnimatedDashedMetrics(
    Canvas canvas,
    List<ui.PathMetric> metrics,
    Paint paint,
  ) {
    for (final metric in metrics) {
      final totalLength = metric.length * progress;
      const dashLength = 36.0;
      const gapLength = 16.0;
      var distance = 0.0;
      while (distance < totalLength) {
        final end = (distance + dashLength).clamp(0.0, totalLength);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SRoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
