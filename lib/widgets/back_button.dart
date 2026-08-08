import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}