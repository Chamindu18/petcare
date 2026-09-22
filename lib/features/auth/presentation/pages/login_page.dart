import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isAnyLoading => _isLoading || _isGoogleLoading;

  Future<void> _login() async {
    if (_isAnyLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.myPets,
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Unable to log in right now. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_isAnyLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _authRepository.signInWithGoogle();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.myPets,
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      if (error.message != 'Google Sign-In was cancelled.') {
        _showError(error.message);
      }
    } catch (_) {
      if (!mounted) return;

      _showError('Unable to continue with Google. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _forgotPassword() {
    Navigator.pushNamed(context, AppRouter.forgotPassword);
  }

  void _createAccount() {
    Navigator.pushNamed(context, AppRouter.register);
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
            const Positioned.fill(child: _LoginBackground()),
            Column(
              children: [
                _LoginTopBar(onBack: () => Navigator.pop(context)),
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
                          SizedBox(
                            width: isCompact ? 105 : 120,
                            child: Image.asset(
                              'assets/branding/petcare_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: 'PetCare+ logo',
                            ),
                          ),
                          SizedBox(height: isCompact ? 14 : 18),
                          Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppTheme.espresso,
                              fontSize: isCompact ? 32 : 36,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Care for your pets starts here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color.fromARGB(255, 142, 79, 45),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: isCompact ? 18 : 24),
                          const _FieldLabel(label: 'Email'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            validator: _validateEmail,
                            decoration: const InputDecoration(
                              hintText: 'your@email.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 21,
                                color: AppTheme.espresso,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel(label: 'Password'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
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
                                    _isPasswordVisible =
                                        !_isPasswordVisible;
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isAnyLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isAnyLoading ? null : _login,
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
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 21,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 16 : 20),
                          const _OrDivider(),
                          SizedBox(height: isCompact ? 14 : 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _isAnyLoading
                                  ? null
                                  : _continueWithGoogle,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.white,
                                foregroundColor: AppTheme.espresso,
                                side: BorderSide(
                                  color: AppTheme.espresso.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 21,
                                      height: 21,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppTheme.primary,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const _GoogleLogo(),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Continue with Google',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: AppTheme.espresso,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Don't have an account?",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.espresso,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _isAnyLoading ? null : _createAccount,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: isCompact ? 115 : 145,
                  child: Image.asset(
                    'assets/images/auth/login_bottom_pets.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                    semanticLabel:
                        'PetCare+ dog and cat illustration',
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

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar({required this.onBack});

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
            constraints:
                const BoxConstraints.tightFor(width: 48, height: 48),
            style: IconButton.styleFrom(
              backgroundColor:
                  AppTheme.secondary.withValues(alpha: 0.20),
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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.secondary.withValues(alpha: 0.35),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.espresso.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.secondary.withValues(alpha: 0.35),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/auth/google_logo.png',
      width: 25,
      height: 25,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Google logo',
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LoginBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.25, 0)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.05,
        size.width * 0.10,
        size.height * 0.08,
        0,
        size.height * 0.13,
      )
      ..close();

    canvas.drawPath(topLeft, fillPaint);

    final topRight = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.20)
      ..cubicTo(
        size.width * 0.91,
        size.height * 0.14,
        size.width * 0.84,
        size.height * 0.08,
        size.width * 0.76,
        0,
      )
      ..close();

    canvas.drawPath(topRight, fillPaint);

    final topRightCurve = Path()
      ..moveTo(size.width, size.height * 0.20)
      ..cubicTo(
        size.width * 0.91,
        size.height * 0.14,
        size.width * 0.84,
        size.height * 0.08,
        size.width * 0.76,
        0,
      );

    canvas.drawPath(topRightCurve, linePaint);

    final bottomLeft = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.80)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.76,
        size.width * 0.17,
        size.height * 0.78,
        size.width * 0.25,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.91,
        size.width * 0.35,
        size.height * 0.96,
        size.width * 0.42,
        size.height,
      )
      ..close();

    canvas.drawPath(bottomLeft, fillPaint);

    final bottomLeftCurve = Path()
      ..moveTo(0, size.height * 0.80)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.76,
        size.width * 0.17,
        size.height * 0.78,
        size.width * 0.25,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.91,
        size.width * 0.35,
        size.height * 0.96,
        size.width * 0.42,
        size.height,
      );

    canvas.drawPath(bottomLeftCurve, linePaint);

    final bottomRight = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.63, size.height)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.94,
        size.width * 0.79,
        size.height * 0.90,
        size.width * 0.87,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.94,
        size.height * 0.79,
        size.width * 0.98,
        size.height * 0.75,
        size.width,
        size.height * 0.70,
      )
      ..close();

    canvas.drawPath(bottomRight, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}