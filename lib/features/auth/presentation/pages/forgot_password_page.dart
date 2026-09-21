import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();

    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _emailSent = false;
    });

    try {
      await _authRepository.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRouter.checkEmail,
        arguments: email,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _emailSent = false;
      });

      _showError(error.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _emailSent = false;
      });

      _showError('Unable to send the reset link. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _backToLogin() {
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
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
            const Positioned.fill(child: _ForgotPasswordBackground()),
            Column(
              children: [
                _ForgotPasswordTopBar(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: isCompact ? 2 : 6),

                          // PetCare+ logo
                          SizedBox(
                            width: isCompact ? 120 : 135,
                            child: Image.asset(
                              'assets/branding/petcare_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: 'PetCare+ logo',
                            ),
                          ),

                          SizedBox(height: isCompact ? 22 : 30),

                          // Heading
                          Text(
                            'Forgot Password?',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppTheme.espresso,
                              fontSize: isCompact ? 33 : 36,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.8,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Supporting text
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: Text(
                              'No worries! Enter your email and we’ll send '
                              'you a link to reset your password.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: const Color.fromARGB(255, 170, 102, 66),
                                fontSize: isCompact ? 15 : 16,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 24 : 32),

                          // Email label
                          const _FieldLabel(label: 'Email'),

                          const SizedBox(height: 8),

                          // Email input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            validator: _validateEmail,
                            onFieldSubmitted: (_) => _sendResetLink(),
                            decoration: const InputDecoration(
                              hintText: 'Enter your email address',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 22,
                                color: AppTheme.espresso,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Send reset link
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendResetLink,
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
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Send Reset Link',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 23,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Divider
                          const _OrDivider(),

                          const SizedBox(height: 22),

                          // Back to Login
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _backToLogin,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
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
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          // Email sent confirmation
                          if (_emailSent) ...[
                            const SizedBox(height: 20),
                            const _SuccessMessage(),
                          ],

                          const SizedBox(height: 180),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Pet artwork
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: isCompact ? 180 : 220,
                  child: Image.asset(
                    'assets/images/auth/forgot_password_pets.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'Golden retriever and cat together',
                  ),
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
// Top bar
// -----------------------------------------------------------------------------

class _ForgotPasswordTopBar extends StatelessWidget {
  const _ForgotPasswordTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: const Offset(-4, 0),
          child: IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.secondary.withValues(alpha: 0.20),
              shape: const CircleBorder(),
            ),
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 28,
              color: AppTheme.espresso,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Field label
// -----------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.espresso,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Or divider
// -----------------------------------------------------------------------------

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.secondary.withValues(alpha: 0.38),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.espresso,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.secondary.withValues(alpha: 0.38),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Success message
// -----------------------------------------------------------------------------

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'We sent a password reset link to your email.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.espresso,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
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

class _ForgotPasswordBackground extends StatelessWidget {
  const _ForgotPasswordBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ForgotPasswordBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ForgotPasswordBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final softFill = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final strongerFill = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // -------------------------------------------------------------------------
    // Top-left organic shape
    // -------------------------------------------------------------------------

    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.30, 0)
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

    // -------------------------------------------------------------------------
    // Top-right soft circular shape
    // -------------------------------------------------------------------------

    final topRightCenter = Offset(size.width * 0.94, size.height * 0.17);

    final topRightRadius = size.width * 0.24;

    canvas.drawCircle(topRightCenter, topRightRadius, strongerFill);

    // -------------------------------------------------------------------------
    // Top-right curved outline
    // -------------------------------------------------------------------------

    final topRightCurve = Path()
      ..moveTo(size.width * 0.74, 0)
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.07,
        size.width * 0.86,
        size.height * 0.12,
        size.width,
        size.height * 0.14,
      );

    canvas.drawPath(topRightCurve, linePaint);

    // -------------------------------------------------------------------------
    // Bottom-left large soft curve
    // -------------------------------------------------------------------------

    final bottomLeft = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.81)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.75,
        size.width * 0.18,
        size.height * 0.75,
        size.width * 0.29,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.89,
        size.width * 0.43,
        size.height * 0.96,
        size.width * 0.50,
        size.height,
      )
      ..close();

    canvas.drawPath(bottomLeft, softFill);

    // -------------------------------------------------------------------------
    // Bottom-left outline
    // -------------------------------------------------------------------------

    final bottomLeftCurve = Path()
      ..moveTo(0, size.height * 0.81)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.75,
        size.width * 0.18,
        size.height * 0.75,
        size.width * 0.29,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.89,
        size.width * 0.43,
        size.height * 0.96,
        size.width * 0.50,
        size.height,
      );

    canvas.drawPath(bottomLeftCurve, linePaint);

    // -------------------------------------------------------------------------
    // Bottom-right soft organic shape
    // -------------------------------------------------------------------------

    final bottomRight = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.63, size.height)
      ..cubicTo(
        size.width * 0.71,
        size.height * 0.94,
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

    // -------------------------------------------------------------------------
    // Small decorative circle
    // -------------------------------------------------------------------------

    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.76),
      26,
      softFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
