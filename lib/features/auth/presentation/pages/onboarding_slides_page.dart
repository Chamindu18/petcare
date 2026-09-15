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

  int _currentPage = 0;

  static const int _totalPages = 3;

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
                    children: const [
                      _SlideOne(),
                      _SlidePlaceholder(
                        title: 'Find Care When',
                        highlightedTitle: 'Your Pet Needs It.',
                      ),
                      _SlidePlaceholder(
                        title: 'Smarter Care.',
                        highlightedTitle: 'Every Day.',
                      ),
                    ],
                  ),
                ),

                _BottomControls(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onNext: _nextPage,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${currentPage + 1} / 3',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w600,
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

          // -------------------------------------------------------------------
          // Logo
          // -------------------------------------------------------------------
          SizedBox(
            width: isCompact ? 125 : 145,
            child: Image.asset(
              _logoAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'PetCare+ logo',
            ),
          ),

          SizedBox(height: isCompact ? 18 : 24),

          // -------------------------------------------------------------------
          // Heading
          // -------------------------------------------------------------------
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Your Pets.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: isCompact ? 35 : 40,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'One Simple Place.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: isCompact ? 35 : 40,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 10 : 12),

          // -------------------------------------------------------------------
          // Description
          // -------------------------------------------------------------------
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                'Manage multiple pet profiles, keep health records, '
                'track vaccinations and treatments all in one place.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.espresso,
                  fontSize: isCompact ? 14 : 15,
                  wordSpacing: isCompact ? 1 : 3,
                  fontWeight: FontWeight.w600,
                  height: 1.42,
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Hero image
          // -------------------------------------------------------------------
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
// Temporary placeholders for slides 2 and 3
// -----------------------------------------------------------------------------

class _SlidePlaceholder extends StatelessWidget {
  const _SlidePlaceholder({
    required this.title,
    required this.highlightedTitle,
  });

  final String title;
  final String highlightedTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets_rounded, size: 110, color: AppTheme.primary),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          Text(
            highlightedTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ],
      ),
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
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
      child: Column(
        children: [
          // Page indicator.
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

          const SizedBox(height: 22),

          // Next button.
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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

    // Top-left soft shape.
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

    // Top-left curved line.
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

    // Bottom-right soft shape.
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

    // Bottom-right curved line.
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
