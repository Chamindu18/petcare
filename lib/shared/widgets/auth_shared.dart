import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// A field label widget used in authentication forms.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({required this.label, super.key});

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

/// An 'or' divider widget used between authentication options.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({
    super.key,
    this.text = 'or continue with',
    this.dividerAlpha = 0.35,
    this.horizontalPadding = 12,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
  });

  final String text;
  final double dividerAlpha;
  final double horizontalPadding;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.secondary.withValues(alpha: dividerAlpha),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.espresso.withValues(alpha: 0.65),
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.secondary.withValues(alpha: dividerAlpha),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Google logo widget used in authentication buttons.
class AuthGoogleLogo extends StatelessWidget {
  const AuthGoogleLogo({super.key});

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

/// Password requirements widget showing validation criteria.
class AuthPasswordRequirements extends StatelessWidget {
  const AuthPasswordRequirements({
    required this.hasEightCharacters,
    required this.hasUppercase,
    required this.hasNumber,
    super.key,
    this.variant = AuthPasswordRequirementsVariant.register,
  });

  final bool hasEightCharacters;
  final bool hasUppercase;
  final bool hasNumber;
  final AuthPasswordRequirementsVariant variant;

  @override
  Widget build(BuildContext context) {
    final isReset = variant == AuthPasswordRequirementsVariant.resetPassword;

    return Container(
      width: double.infinity,
      padding: isReset
          ? const EdgeInsets.fromLTRB(14, 10, 14, 11)
          : const EdgeInsets.fromLTRB(12, 8, 12, 9),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: isReset ? 0.70 : 0.55),
        borderRadius: isReset
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              )
            : BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: isReset ? 0.24 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must include:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.espresso,
              fontSize: isReset ? 11 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isReset ? 7 : 5),
          AuthRequirementRow(
            text: 'At least 8 characters',
            satisfied: hasEightCharacters,
            variant: variant,
          ),
          SizedBox(height: isReset ? 5 : 3),
          AuthRequirementRow(
            text: 'One uppercase letter',
            satisfied: hasUppercase,
            variant: variant,
          ),
          SizedBox(height: isReset ? 5 : 3),
          AuthRequirementRow(
            text: 'One number',
            satisfied: hasNumber,
            variant: variant,
          ),
        ],
      ),
    );
  }
}

/// Variant for AuthPasswordRequirements to support different screen designs.
enum AuthPasswordRequirementsVariant { register, resetPassword }

/// Individual requirement row for password validation.
class AuthRequirementRow extends StatelessWidget {
  const AuthRequirementRow({
    required this.text,
    required this.satisfied,
    super.key,
    this.variant = AuthPasswordRequirementsVariant.register,
  });

  final String text;
  final bool satisfied;
  final AuthPasswordRequirementsVariant variant;

  @override
  Widget build(BuildContext context) {
    final isReset = variant == AuthPasswordRequirementsVariant.resetPassword;

    if (isReset) {
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

/// Circular back button used in authentication screens.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    required this.onPressed,
    super.key,
    this.offset = const Offset(-4, 0),
    this.tooltip,
  });

  final VoidCallback onPressed;
  final Offset offset;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
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
    );
  }
}

/// Shows an error SnackBar with consistent styling across auth screens.
void showAuthErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.error,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}
