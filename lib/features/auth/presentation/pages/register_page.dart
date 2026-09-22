import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();

    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isAnyLoading => _isLoading || _isGoogleLoading;

  bool get _hasEightCharacters => _passwordController.text.length >= 8;

  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(
        _passwordController.text,
      );

  bool get _hasNumber => RegExp(r'\d').hasMatch(
        _passwordController.text,
      );

  bool get _passwordIsValid =>
      _hasEightCharacters && _hasUppercase && _hasNumber;

  Future<void> _createAccount() async {
    if (_isAnyLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.registerOwner(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
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

      _showError('Unable to create your account. Please try again.');
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

  void _login() {
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

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your full name';
    }

    if (name.length < 2) {
      return 'Please enter a valid name';
    }

    return null;
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

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }

    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length < 9 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please create a password';
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
            const Positioned.fill(child: _RegisterBackground()),
            Column(
              children: [
                _RegisterTopBar(
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: isCompact ? 0 : 2),
                          SizedBox(
                            width: isCompact ? 118 : 132,
                            child: Image.asset(
                              'assets/branding/petcare_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: 'PetCare+ logo',
                            ),
                          ),
                          SizedBox(height: isCompact ? 14 : 18),
                          Text(
                            'Create Your Account',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppTheme.espresso,
                              fontSize: isCompact ? 32 : 34,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 315),
                            child: Text(
                              'Join PetCare+ and give your pets '
                              'a healthier, happier tomorrow.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(
                                  255,
                                  142,
                                  86,
                                  56,
                                ),
                                fontSize: isCompact ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 14 : 18),
                          const _FieldLabel(label: 'Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _fullNameController,
                            textCapitalization:
                                TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _validateFullName,
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 21,
                                color: AppTheme.espresso,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _FieldLabel(label: 'Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType:
                                TextInputType.emailAddress,
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
                          const SizedBox(height: 10),
                          const _FieldLabel(label: 'Phone Number'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: _validatePhone,
                            decoration: const InputDecoration(
                              hintText: '+94 77 123 4567',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                size: 21,
                                color: AppTheme.espresso,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _FieldLabel(label: 'Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.next,
                            validator: _validatePassword,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Create a password',
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
                          const SizedBox(height: 7),
                          _PasswordRequirements(
                            hasEightCharacters:
                                _hasEightCharacters,
                            hasUppercase: _hasUppercase,
                            hasNumber: _hasNumber,
                          ),
                          const SizedBox(height: 10),
                          const _FieldLabel(
                            label: 'Confirm Password',
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller:
                                _confirmPasswordController,
                            obscureText:
                                !_isConfirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator:
                                _validateConfirmPassword,
                            onFieldSubmitted:
                                (_) => _createAccount(),
                            decoration: InputDecoration(
                              hintText: 'Confirm your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 21,
                                color: AppTheme.espresso,
                              ),
                              suffixIcon: IconButton(
                                tooltip:
                                    _isConfirmPasswordVisible
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
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isAnyLoading
                                  ? null
                                  : _createAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.white,
                                disabledBackgroundColor:
                                    AppTheme.primary.withValues(
                                  alpha: 0.55,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(28),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(
                                          AppTheme.white,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w800,
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
                          SizedBox(
                            height: isCompact ? 12 : 15,
                          ),
                          const _OrDivider(),
                          SizedBox(
                            height: isCompact ? 11 : 13,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isAnyLoading
                                  ? null
                                  : _continueWithGoogle,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.white,
                                foregroundColor:
                                    AppTheme.espresso,
                                side: BorderSide(
                                  color:
                                      AppTheme.espresso.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(28),
                                ),
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 21,
                                      height: 21,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(
                                          AppTheme.primary,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const _GoogleLogo(),
                                        const SizedBox(width: 9),
                                        Text(
                                          'Continue with Google',
                                          style: theme.textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                            color:
                                                AppTheme.espresso,
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style:
                                    theme.textTheme.bodySmall
                                        ?.copyWith(
                                  color: AppTheme.espresso,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: _isAnyLoading
                                    ? null
                                    : _login,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize
                                          .shrinkWrap,
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
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

class _RegisterTopBar extends StatelessWidget {
  const _RegisterTopBar({required this.onBack});

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
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must include:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.espresso,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          _RequirementRow(
            text: 'At least 8 characters',
            satisfied: hasEightCharacters,
          ),
          const SizedBox(height: 3),
          _RequirementRow(
            text: 'One uppercase letter',
            satisfied: hasUppercase,
          ),
          const SizedBox(height: 3),
          _RequirementRow(
            text: 'One number',
            satisfied: hasNumber,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.text,
    required this.satisfied,
  });

  final String text;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          satisfied
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 15,
          color: satisfied
              ? AppTheme.success
              : AppTheme.espresso.withValues(alpha: 0.50),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.espresso,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
      width: 21,
      height: 21,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Google logo',
    );
  }
}

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RegisterBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
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

    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.30, 0)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.04,
        size.width * 0.09,
        size.height * 0.10,
        0,
        size.height * 0.17,
      )
      ..close();

    canvas.drawPath(topLeft, softFill);

    final topRight = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.20)
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.15,
        size.width * 0.85,
        size.height * 0.09,
        size.width * 0.77,
        0,
      )
      ..close();

    canvas.drawPath(topRight, strongerFill);

    final topRightCurve = Path()
      ..moveTo(size.width * 0.77, 0)
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.05,
        size.width * 0.89,
        size.height * 0.12,
        size.width,
        size.height * 0.17,
      );

    canvas.drawPath(topRightCurve, linePaint);

    final bottomLeft = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.78,
        size.width * 0.18,
        size.height * 0.78,
        size.width * 0.28,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.93,
        size.width * 0.43,
        size.height * 0.98,
        size.width * 0.50,
        size.height,
      )
      ..close();

    canvas.drawPath(bottomLeft, softFill);

    final bottomLeftCurve = Path()
      ..moveTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.78,
        size.width * 0.18,
        size.height * 0.78,
        size.width * 0.28,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.93,
        size.width * 0.43,
        size.height * 0.98,
        size.width * 0.50,
        size.height,
      );

    canvas.drawPath(bottomLeftCurve, linePaint);

    final bottomRight = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.62, size.height)
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}