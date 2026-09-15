import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

import '../../../../app/theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const String _logoAsset = 'assets/branding/petcare_logo.png';
  static const String _petsAsset =
      'assets/images/onboarding/onboarding_pets.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isCompact = size.height < 720;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _BackgroundDecoration()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: isCompact ? 22 : 32),

                  // Logo
                  SizedBox(
                    width: isCompact ? 150 : 175,
                    child: Image.asset(
                      _logoAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'PetCare+ logo',
                    ),
                  ),

                  SizedBox(height: isCompact ? 26 : 38),

                  // Heading
                  Text(
                    'Better Care',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppTheme.espresso,
                      fontSize: isCompact ? 36 : 42,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Text(
                    'Starts Here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primary,
                      fontSize: isCompact ? 36 : 42,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -1.0,
                    ),
                  ),

                  SizedBox(height: isCompact ? 14 : 18),

                  // Supporting text
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Text(
                      'Trusted support, expert care, and a healthier, '
                      'happier life for your pet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.espresso,
                        fontSize: isCompact ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),

                  // Hero image
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 12 : 18,
                      ),
                      child: Image.asset(
                        _petsAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'Golden retriever and orange tabby cat',
                      ),
                    ),
                  ),

                  // Get Started
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        // IMPORTANT:
                        // Use pushNamed so this Welcome screen remains
                        // underneath the onboarding slides.
                        Navigator.pushNamed(
                          context,
                          AppRouter.onboardingSlides,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Get Started'),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Existing account
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        side: const BorderSide(
                          color: AppTheme.deepBrown,
                          width: 1.2,
                        ),
                      ),
                      onPressed: () {
                        // Use pushNamed so Welcome remains underneath Login.
                        Navigator.pushNamed(context, AppRouter.login);
                      },
                      child: const Text('Already have an account?'),
                    ),
                  ),

                  SizedBox(height: isCompact ? 16 : 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundDecorationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BackgroundDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Top-left organic shape.
    final topLeftShape = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.44, 0)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.06,
        size.width * 0.28,
        size.height * 0.11,
        size.width * 0.17,
        size.height * 0.15,
      )
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.19,
        size.width * 0.03,
        size.height * 0.22,
        0,
        size.height * 0.25,
      )
      ..close();

    canvas.drawPath(topLeftShape, fillPaint);

    // Top-left curved outline.
    final topCurve = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.12,
        size.width * 0.15,
        size.height * 0.07,
        size.width * 0.24,
        size.height * 0.045,
      )
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.025,
        size.width * 0.38,
        size.height * 0.01,
        size.width * 0.41,
        0,
      );

    canvas.drawPath(topCurve, linePaint);

    // Bottom-right organic shape.
    final bottomRightShape = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.60, size.height)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.93,
        size.width * 0.76,
        size.height * 0.89,
        size.width * 0.85,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.94,
        size.height * 0.80,
        size.width * 0.98,
        size.height * 0.76,
        size.width,
        size.height * 0.71,
      )
      ..close();

    canvas.drawPath(bottomRightShape, fillPaint);

    // Bottom-right curved outline.
    final bottomCurve = Path()
      ..moveTo(size.width * 0.61, size.height)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.92,
        size.width * 0.77,
        size.height * 0.88,
        size.width * 0.86,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.93,
        size.height * 0.79,
        size.width * 0.98,
        size.height * 0.75,
        size.width,
        size.height * 0.71,
      );

    canvas.drawPath(bottomCurve, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
