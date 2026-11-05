import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class PetCareSecondaryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PetCareSecondaryAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: AppTheme.background,
      foregroundColor: AppTheme.espresso,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: canPop ? const BackButton() : null,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.espresso,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: actions,
    );
  }
}
