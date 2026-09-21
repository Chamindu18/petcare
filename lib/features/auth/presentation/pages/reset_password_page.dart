import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.authRepository, this.code});

  final AuthRepository? authRepository;

  /// Firebase password-reset action code.
  ///
  /// This is supplied by the reset email/deep-link flow.
  final String? code;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  bool get _hasEightCharacters => _passwordController.text.length >= 8;

  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);

  bool get _hasNumber => RegExp(r'\d').hasMatch(_passwordController.text);

  bool get _passwordIsValid =>
      _hasEightCharacters && _hasUppercase && _hasNumber;

  @override
  void initState() {
    super.initState();

    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = widget.code?.trim();

    if (code == null || code.isEmpty) {
      _showError('This reset link is missing or invalid.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.confirmPasswordReset(
        code: code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, AppRouter.passwordResetSuccess);
    } on AuthException catch (error) {
      if (!mounted) return;

      _showError(error.message);
    } catch (_) {
      if (!mounted) return;

      _showError('Unable to reset your password. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter a new password';
    }

    if (!_passwordIsValid) {
      return 'Password does not meet the requirements';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
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
            const Positioned.fill(child: _ResetPasswordBackground()),
            Column(
              children: [
                _ResetPasswordTopBar(onBack: _backToLogin),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: isCompact ? 0 : 4),

                          // PetCare+ logo
                          SizedBox(
                            width: isCompact ? 115 : 130,
                            child: Image.asset(
                              'assets/branding/petcare_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: 'PetCare+ logo',
                            ),
                          ),

                          SizedBox(height: isCompact ? 18 : 24),

                          // Heading
                          Text(
                            'Reset Your Password',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppTheme.espresso,
                              fontSize: isCompact ? 29 : 34,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.8,
                            ),
                          ),

                          const SizedBox(height: 7),

                          // Supporting text
                          Text(
                            'Create a new password for your account.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.espresso,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),

                          SizedBox(height: isCompact ? 16 : 20),

                          // Verified email card
                          const _VerifiedEmailCard(),

                          SizedBox(height: isCompact ? 16 : 20),

                          // New password
                          const _FieldLabel(label: 'New Password'),

                          const SizedBox(height: 7),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.next,
                            validator: _validatePassword,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 21,
                                color: AppTheme.espresso,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _isPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 21,
                                  color: AppTheme.espresso,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Password requirements
                          _PasswordRequirements(
                            hasEightCharacters: _hasEightCharacters,
                            hasUppercase: _hasUppercase,
                            hasNumber: _hasNumber,
                          ),

                          const SizedBox(height: 16),

                          // Confirm password
                          const _FieldLabel(label: 'Confirm New Password'),

                          const SizedBox(height: 7),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmPassword,
                            onFieldSubmitted: (_) => _resetPassword(),
                            decoration: InputDecoration(
                              hintText: 'Confirm new password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 21,
                                color: AppTheme.espresso,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _isConfirmPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 21,
                                  color: AppTheme.espresso,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Reset password button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
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
                                          'Reset Password',
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

                          SizedBox(height: isCompact ? 24 : 36),

                          // Bottom decorative content
                          const _BottomHint(),
                          SizedBox(height: isCompact ? 12 : 24),
                        ],
                      ),
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

// -----------------------------------------------------------------------------
// Top bar
// -----------------------------------------------------------------------------

class _ResetPasswordTopBar extends StatelessWidget {
  const _ResetPasswordTopBar({required this.onBack});

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
// Verified email information card
// -----------------------------------------------------------------------------

class _VerifiedEmailCard extends StatelessWidget {
  const _VerifiedEmailCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
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
                  'We\'ve verified your email',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Enter your new password below.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Password requirements
// -----------------------------------------------------------------------------

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({
    required this.hasEightCharacters,
    required this.hasUppercase,
    required this.hasNumber,
  });

  final bool hasEightCharacters;
  final bool hasUppercase;
  final bool hasNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.70),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must include:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.espresso,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          _RequirementRow(
            text: 'At least 8 characters',
            satisfied: hasEightCharacters,
          ),
          const SizedBox(height: 5),
          _RequirementRow(
            text: 'One uppercase letter',
            satisfied: hasUppercase,
          ),
          const SizedBox(height: 5),
          _RequirementRow(text: 'One number', satisfied: hasNumber),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.text, required this.satisfied});

  final String text;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: satisfied
                ? AppTheme.success
                : AppTheme.secondary.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: satisfied
                ? AppTheme.white
                : AppTheme.deepBrown.withValues(alpha: 0.55),
            size: 13,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.espresso,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom hint
// -----------------------------------------------------------------------------

class _BottomHint extends StatelessWidget {
  const _BottomHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DecorativeLine(alignment: Alignment.centerLeft)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: AppTheme.deepBrown.withValues(alpha: 0.68),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep your account secure',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepBrown,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _DecorativeLine(alignment: Alignment.centerRight)),
      ],
    );
  }
}

class _DecorativeLine extends StatelessWidget {
  const _DecorativeLine({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: double.infinity,
        height: 1,
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Background
// -----------------------------------------------------------------------------

class _ResetPasswordBackground extends StatelessWidget {
  const _ResetPasswordBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ResetPasswordBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ResetPasswordBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final softFill = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final strongerFill = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final primaryFill = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Top-left organic shape.
    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.28, 0)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.035,
        size.width * 0.08,
        size.height * 0.10,
        0,
        size.height * 0.18,
      )
      ..close();

    canvas.drawPath(topLeft, softFill);

    // Top-right soft organic shape.
    final topRight = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.21)
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.17,
        size.width * 0.84,
        size.height * 0.11,
        size.width * 0.78,
        size.height * 0.04,
      )
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.025,
        size.width * 0.77,
        size.height * 0.012,
        size.width * 0.77,
        0,
      )
      ..close();

    canvas.drawPath(topRight, strongerFill);

    // Top-right curved outline.
    final topRightCurve = Path()
      ..moveTo(size.width * 0.78, 0)
      ..cubicTo(
        size.width * 0.79,
        size.height * 0.06,
        size.width * 0.89,
        size.height * 0.12,
        size.width,
        size.height * 0.17,
      );

    canvas.drawPath(topRightCurve, linePaint);

    // Small decorative circle.
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.20),
      12,
      primaryFill,
    );

    // Bottom-left soft curve.
    final bottomLeft = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.83)
      ..cubicTo(
        size.width * 0.09,
        size.height * 0.77,
        size.width * 0.18,
        size.height * 0.79,
        size.width * 0.27,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.93,
        size.width * 0.42,
        size.height * 0.98,
        size.width * 0.50,
        size.height,
      )
      ..close();

    canvas.drawPath(bottomLeft, softFill);

    // Bottom-left outline.
    final bottomLeftCurve = Path()
      ..moveTo(0, size.height * 0.83)
      ..cubicTo(
        size.width * 0.09,
        size.height * 0.77,
        size.width * 0.18,
        size.height * 0.79,
        size.width * 0.27,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.93,
        size.width * 0.42,
        size.height * 0.98,
        size.width * 0.50,
        size.height,
      );

    canvas.drawPath(bottomLeftCurve, linePaint);

    // Bottom-right soft organic shape.
    final bottomRight = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.61, size.height)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.95,
        size.width * 0.79,
        size.height * 0.91,
        size.width * 0.88,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.79,
        size.width * 0.98,
        size.height * 0.74,
        size.width,
        size.height * 0.68,
      )
      ..close();

    canvas.drawPath(bottomRight, strongerFill);

    // Very subtle center-bottom shading.
    final centerBottom = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.98),
        width: size.width * 0.72,
        height: size.height * 0.18,
      ),
      centerBottom,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
