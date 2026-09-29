import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const String _logoAsset = 'assets/branding/petcare_logo.png';
  static const String _loadingMessage = "Preparing your pet's care...";

  @override
  void initState() {
    super.initState();

    final auth = widget.auth ?? FirebaseAuth.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final user = auth.currentUser;
      final target = user != null ? AppRouter.home : AppRouter.onboarding;

      Navigator.pushNamedAndRemoveUntil(context, target, (route) => false);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SplashBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 700;

                return Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isCompact ? 250 : 300,
                            child: Image.asset(
                              _logoAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: 'PetCare+ logo',
                            ),
                          ),
                          SizedBox(height: isCompact ? 24 : 32),
                          const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 18 : 22),
                          Text(
                            _loadingMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.espresso,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SplashBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = AppTheme.background
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final softShapePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final curvePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // Top-left soft organic shape.
    final topLeftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.42, 0)
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.11,
        size.width * 0.27,
        size.height * 0.16,
        size.width * 0.18,
        size.height * 0.19,
      )
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.22,
        size.width * 0.04,
        size.height * 0.26,
        0,
        size.height * 0.27,
      )
      ..close();

    canvas.drawPath(topLeftPath, softShapePaint);

    // Top-left flowing line.
    final topCurve = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.12,
        size.width * 0.13,
        size.height * 0.07,
        size.width * 0.23,
        size.height * 0.055,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.042,
        size.width * 0.36,
        size.height * 0.018,
        size.width * 0.37,
        0,
      );

    canvas.drawPath(topCurve, curvePaint);

    // Bottom-right soft organic shape.
    final bottomRightPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.59, size.height)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.91,
        size.width * 0.72,
        size.height * 0.86,
        size.width * 0.82,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.80,
        size.width * 0.96,
        size.height * 0.77,
        size.width,
        size.height * 0.74,
      )
      ..close();

    canvas.drawPath(bottomRightPath, softShapePaint);

    // Bottom-right flowing line.
    final bottomCurve = Path()
      ..moveTo(size.width * 0.60, size.height)
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.90,
        size.width * 0.77,
        size.height * 0.87,
        size.width * 0.85,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.79,
        size.width * 0.96,
        size.height * 0.75,
        size.width,
        size.height * 0.72,
      );

    canvas.drawPath(bottomCurve, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
