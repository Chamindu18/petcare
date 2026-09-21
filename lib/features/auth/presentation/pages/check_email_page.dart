import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class CheckEmailPage extends StatefulWidget {
  const CheckEmailPage({super.key, required this.email, this.authRepository});

  final String email;
  final AuthRepository? authRepository;

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  late final AuthRepository _authRepository;

  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  Future<void> _openEmailApp() async {
    final emailUri = Uri(scheme: 'mailto', path: widget.email);

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'No email app is available on this device.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to open your email app.', isError: true);
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _authRepository.sendPasswordResetEmail(email: widget.email.trim());

      if (!mounted) return;

      _showMessage('A new reset link has been sent to your email.');
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to resend the reset link. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _backToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.login,
      (route) => false,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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
            const Positioned.fill(child: _CheckEmailBackground()),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isResending ? null : _backToLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.deepBrown,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      label: const Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                    child: Column(
                      children: [
                        SizedBox(height: isCompact ? 8 : 18),

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

                        SizedBox(height: isCompact ? 18 : 26),

                        // Check email illustration
                        SizedBox(
                          width: isCompact ? 170 : 190,
                          height: isCompact ? 135 : 150,
                          child: Image.asset(
                            'assets/images/auth/check_email_illustration.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'Dog with an envelope illustration',
                          ),
                        ),

                        SizedBox(height: isCompact ? 18 : 24),

                        // Heading
                        Text(
                          'Check Your Email',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppTheme.espresso,
                            fontSize: isCompact ? 31 : 34,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: -0.7,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Supporting text
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Text(
                            'We sent a password reset link to the email '
                            'address below. Open your inbox and follow '
                            'the link to continue.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.deepBrown,
                              fontSize: isCompact ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 20 : 26),

                        // Email display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.secondary.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.secondary.withValues(
                                      alpha: 0.65,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppTheme.deepBrown,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.email,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.espresso,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isCompact ? 18 : 22),

                        // Open Email App
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isResending ? null : _openEmailApp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.white,
                              disabledBackgroundColor: AppTheme.primary
                                  .withValues(alpha: 0.55),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mail_rounded, size: 21),
                                SizedBox(width: 10),
                                Text(
                                  'Open Email App',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Resend Email
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isResending ? null : _resendEmail,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.white,
                              foregroundColor: AppTheme.deepBrown,
                              side: const BorderSide(
                                color: AppTheme.deepBrown,
                                width: 1.2,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isResending
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.deepBrown,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 21),
                                      SizedBox(width: 10),
                                      Text(
                                        'Resend Email',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 18 : 22),

                        // Help information
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.white.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.secondary.withValues(alpha: 0.38),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.information,
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Didn’t receive the email? Check your '
                                  'spam or junk folder and make sure the '
                                  'email address is correct.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.espresso,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isCompact ? 22 : 34),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckEmailBackground extends StatelessWidget {
  const _CheckEmailBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _CheckEmailBackgroundPainter()),
    );
  }
}

class _CheckEmailBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.secondary.withValues(alpha: 0.10);

    final upperPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.13)
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.08,
        size.width * 0.45,
        size.height * 0.18,
        0,
        size.height * 0.10,
      )
      ..close();

    canvas.drawPath(upperPath, paint);

    final lowerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primary.withValues(alpha: 0.07);

    final lowerPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.91)
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.87,
        size.width * 0.42,
        size.height * 0.96,
        0,
        size.height * 0.89,
      )
      ..close();

    canvas.drawPath(lowerPath, lowerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
