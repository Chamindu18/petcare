import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  void _goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (route) => false,
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 720;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _RegistrationSuccessBackground()),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 46),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isCompact ? 4 : 10),

                    // PetCare+ logo
                    SizedBox(
                      width: isCompact ? 125 : 140,
                      child: Image.asset(
                        'assets/branding/petcare_logo.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'PetCare+ logo',
                      ),
                    ),

                    SizedBox(height: isCompact ? 16 : 24),

                    // Success illustration
                    SizedBox(
                      width: isCompact ? 245 : 285,
                      height: isCompact ? 225 : 265,
                      child: Image.asset(
                        'assets/images/auth/password_reset_success.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel:
                            'Happy dog and cat with a success check mark',
                      ),
                    ),

                    SizedBox(height: isCompact ? 8 : 14),

                    // Heading
                    Text(
                      'Account Created!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppTheme.espresso,
                        fontSize: isCompact ? 30 : 34,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Supporting text
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Text(
                        'Welcome to PetCare+! Your account has been '
                        'created successfully. Let’s get started on a '
                        'healthier, happier journey together.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.deepBrown,
                          fontSize: isCompact ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: isCompact ? 20 : 28),

                    // You're all set card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.secondary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.24),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: AppTheme.deepBrown,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You’re all set!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.espresso,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Let’s get started on a healthier, '
                                  'happier life together.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.deepBrown,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isCompact ? 18 : 24),

                    // Go to Home
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _goToHome(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Go to Home',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward_rounded, size: 23),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Login link
                    TextButton(
                      onPressed: () => _goToLogin(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.deepBrown,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isCompact ? 18 : 28),

                    const _RegistrationSuccessFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Footer
// -----------------------------------------------------------------------------

class _RegistrationSuccessFooter extends StatelessWidget {
  const _RegistrationSuccessFooter();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.deepBrown,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              const Icon(
                Icons.pets_rounded,
                size: 21,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text('Small steps,\nhealthier days', style: textStyle),
              ),
            ],
          ),
        ),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  'Same love,\nbrighter days',
                  textAlign: TextAlign.right,
                  style: textStyle,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.favorite_border_rounded,
                size: 21,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Background
// -----------------------------------------------------------------------------

class _RegistrationSuccessBackground extends StatelessWidget {
  const _RegistrationSuccessBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RegistrationSuccessBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _RegistrationSuccessBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final softFill = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final strongerFill = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final primaryFill = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top-left organic shape.
    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.28, 0)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.04,
        size.width * 0.08,
        size.height * 0.10,
        0,
        size.height * 0.18,
      )
      ..close();

    canvas.drawPath(topLeft, softFill);

    // Top-right organic shape.
    final topRight = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.18,
        size.width * 0.84,
        size.height * 0.11,
        size.width * 0.78,
        size.height * 0.04,
      )
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.025,
        size.width * 0.77,
        size.height * 0.01,
        size.width * 0.77,
        0,
      )
      ..close();

    canvas.drawPath(topRight, strongerFill);

    // Top-right outline.
    final topRightCurve = Path()
      ..moveTo(size.width * 0.77, 0)
      ..cubicTo(
        size.width * 0.79,
        size.height * 0.06,
        size.width * 0.89,
        size.height * 0.12,
        size.width,
        size.height * 0.17,
      );

    canvas.drawPath(topRightCurve, linePaint);

    // Small top-left decorative circle.
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.20),
      13,
      primaryFill,
    );

    // Bottom-left organic curve.
    final bottomLeft = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.09,
        size.height * 0.78,
        size.width * 0.19,
        size.height * 0.78,
        size.width * 0.29,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.92,
        size.width * 0.44,
        size.height * 0.98,
        size.width * 0.52,
        size.height,
      )
      ..close();

    canvas.drawPath(bottomLeft, softFill);

    // Bottom-left outline.
    final bottomLeftCurve = Path()
      ..moveTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.09,
        size.height * 0.78,
        size.width * 0.19,
        size.height * 0.78,
        size.width * 0.29,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.92,
        size.width * 0.44,
        size.height * 0.98,
        size.width * 0.52,
        size.height,
      );

    canvas.drawPath(bottomLeftCurve, linePaint);

    // Bottom-right organic shape.
    final bottomRight = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.61, size.height)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.95,
        size.width * 0.80,
        size.height * 0.91,
        size.width * 0.89,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.79,
        size.width * 0.98,
        size.height * 0.74,
        size.width,
        size.height * 0.69,
      )
      ..close();

    canvas.drawPath(bottomRight, strongerFill);

    // Bottom decorative oval.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.99),
        width: size.width * 0.72,
        height: size.height * 0.18,
      ),
      primaryFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
