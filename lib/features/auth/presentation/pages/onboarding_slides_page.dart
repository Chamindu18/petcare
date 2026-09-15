import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class OnboardingSlidesPage extends StatefulWidget {
  const OnboardingSlidesPage({super.key});

  @override
  State<OnboardingSlidesPage> createState() => _OnboardingSlidesPageState();
}

class _OnboardingSlidesPageState extends State<OnboardingSlidesPage> {
  final PageController _pageController = PageController();

  static const int _totalPages = 3;

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    Navigator.pushReplacementNamed(context, AppRouter.register);
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRouter.register);
  }

  void _login() {
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _OnboardingBackground()),
            Column(
              children: [
                _TopBar(currentPage: _currentPage, onSkip: _skip),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: const [_SlideOne(), _SlideTwo(), _SlideThree()],
                  ),
                ),
                _BottomControls(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onNext: _nextPage,
                  onLogin: _login,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Top bar
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.currentPage, required this.onSkip});

  final int currentPage;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${currentPage + 1} / 3',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 1
// -----------------------------------------------------------------------------

class _SlideOne extends StatelessWidget {
  const _SlideOne();

  static const String _logoAsset = 'assets/branding/petcare_logo.png';

  static const String _heroAsset =
      'assets/images/onboarding/onboarding_slide_1.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isCompact = size.height < 720;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SizedBox(height: isCompact ? 2 : 8),

          SizedBox(
            width: isCompact ? 112 : 125,
            child: Image.asset(
              _logoAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'PetCare+ logo',
            ),
          ),

          SizedBox(height: isCompact ? 12 : 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Your Pets.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: isCompact ? 38 : 44,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'One Simple Place.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: isCompact ? 38 : 42,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 10 : 12),

          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                'Manage multiple pet profiles, keep health records, '
                'track vaccinations and treatments all in one place.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.espresso,
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  height: 1.42,
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isCompact ? 4 : 8,
                bottom: isCompact ? 0 : 4,
              ),
              child: Center(
                child: SizedBox(
                  width: isCompact ? 400 : 440,
                  child: Image.asset(
                    _heroAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel:
                        'Golden retriever and orange tabby resting together',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 2
// -----------------------------------------------------------------------------

class _SlideTwo extends StatelessWidget {
  const _SlideTwo();

  static const String _logoAsset = 'assets/branding/petcare_logo.png';

  static const String _heroAsset =
      'assets/images/onboarding/onboarding_slide_2.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isCompact = size.height < 720;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SizedBox(height: isCompact ? 2 : 8),

          SizedBox(
            width: isCompact ? 112 : 125,
            child: Image.asset(
              _logoAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'PetCare+ logo',
            ),
          ),

          SizedBox(height: isCompact ? 12 : 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Care When',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: isCompact ? 38 : 44,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'Your Pet Needs It.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: isCompact ? 38 : 42,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 10 : 14),

          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                'Discover nearby veterinary hospitals, book appointments '
                'and track your live queue — stress-free.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.espresso,
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  height: 1.42,
                ),
              ),
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: isCompact ? 12 : 18,
                  child: const _FeatureItem(
                    icon: Icons.location_on_rounded,
                    title: 'Multiple Hospitals',
                    subtitle: 'Near You',
                  ),
                ),
                Positioned(
                  left: 0,
                  top: isCompact ? 72 : 84,
                  child: const _FeatureItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Easy Appointment',
                    subtitle: 'Booking',
                  ),
                ),
                Positioned(
                  left: 0,
                  top: isCompact ? 132 : 150,
                  child: const _FeatureItem(
                    icon: Icons.groups_rounded,
                    title: 'Live Queue',
                    subtitle: 'Tracking',
                  ),
                ),
                Positioned(
                  right: -18,
                  bottom: isCompact ? 0 : 2,
                  child: SizedBox(
                    width: isCompact ? 255 : 295,
                    child: Image.asset(
                      _heroAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Dog representing veterinary care and nearby services',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 3
// -----------------------------------------------------------------------------

class _SlideThree extends StatelessWidget {
  const _SlideThree();

  static const String _logoAsset = 'assets/branding/petcare_logo.png';

  static const String _heroAsset =
      'assets/images/onboarding/onboarding_slide_3.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isCompact = size.height < 720;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SizedBox(height: isCompact ? 2 : 8),

          SizedBox(
            width: isCompact ? 112 : 125,
            child: Image.asset(
              _logoAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'PetCare+ logo',
            ),
          ),

          SizedBox(height: isCompact ? 14 : 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smarter Care.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: isCompact ? 38 : 44,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'Every Day.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: isCompact ? 38 : 42,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 10 : 14),

          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 335),
              child: Text(
                'Get AI-powered pet care guidance, view health summaries, '
                'receive preventive insights and even find pets in need '
                'of a loving home.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.espresso,
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -18,
                  bottom: isCompact ? 0 : 2,
                  child: SizedBox(
                    width: isCompact ? 250 : 285,
                    child: Image.asset(
                      _heroAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel:
                          'Gray and white kitten representing smarter pet care',
                    ),
                  ),
                ),

                // -------------------------------------------------------------------------
                // Feature 1
                // -------------------------------------------------------------------------
                Positioned(
                  left: 0,
                  top: isCompact ? 8 : 14,
                  child: const _FeatureItem(
                    icon: Icons.psychology_rounded,
                    title: 'AI Pet Care',
                    subtitle: 'Assistant',
                  ),
                ),

                // -------------------------------------------------------------------------
                // Feature 2
                // -------------------------------------------------------------------------
                Positioned(
                  left: 0,
                  top: isCompact ? 66 : 78,
                  child: const _FeatureItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Health Insights',
                    subtitle: '& Reminders',
                  ),
                ),

                // -------------------------------------------------------------------------
                // Feature 3
                // -------------------------------------------------------------------------
                Positioned(
                  left: 0,
                  top: isCompact ? 124 : 142,
                  child: const _FeatureItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Preventive Care',
                    subtitle: 'Support',
                  ),
                ),

                // -------------------------------------------------------------------------
                // Feature 4
                // -------------------------------------------------------------------------
                Positioned(
                  left: 0,
                  top: isCompact ? 182 : 206,
                  child: const _FeatureItem(
                    icon: Icons.home_outlined,
                    title: 'Find Pets for',
                    subtitle: 'Adoption',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Feature item
// -----------------------------------------------------------------------------

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 24, color: AppTheme.deepBrown),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.espresso,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.espresso,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom controls
// -----------------------------------------------------------------------------

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onLogin,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isActive ? 10 : 8,
                height: isActive ? 10 : 8,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.espresso : AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: onNext,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLastPage ? 'Get Started' : 'Next'),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),

          if (isLastPage) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.espresso,
                  ),
                  children: [
                    TextSpan(text: 'Already have an account?  '),
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Background
// -----------------------------------------------------------------------------

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OnboardingBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OnboardingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final topLeftShape = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.42, 0)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.07,
        size.width * 0.27,
        size.height * 0.11,
        size.width * 0.17,
        size.height * 0.15,
      )
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.18,
        size.width * 0.03,
        size.height * 0.22,
        0,
        size.height * 0.25,
      )
      ..close();

    canvas.drawPath(topLeftShape, fillPaint);

    final topCurve = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.09,
        size.height * 0.12,
        size.width * 0.14,
        size.height * 0.07,
        size.width * 0.24,
        size.height * 0.04,
      )
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.02,
        size.width * 0.38,
        size.height * 0.01,
        size.width * 0.41,
        0,
      );

    canvas.drawPath(topCurve, linePaint);

    final bottomRightShape = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.60, size.height)
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.93,
        size.width * 0.77,
        size.height * 0.89,
        size.width * 0.86,
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
        size.width * 0.94,
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
