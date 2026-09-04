import 'package:flutter/material.dart';

import '../app_theme/app_colors.dart';
import '../app_theme/app_text_styles.dart';

enum AppMessageType { error, success, warning, info }

class AppMessage extends StatelessWidget {
  final String title;
  final String message;
  final AppMessageType type;
  final VoidCallback? onClose;

  const AppMessage({
    super.key,
    required this.title,
    required this.message,
    this.type = AppMessageType.error,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;

    switch (type) {
      case AppMessageType.success:
        iconColor = AppColors.primary;
        icon = Icons.check_circle_outline_rounded;
        break;

      case AppMessageType.warning:
        iconColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;

      case AppMessageType.info:
        iconColor = Colors.blue;
        icon = Icons.info_outline_rounded;
        break;

      case AppMessageType.error:
        iconColor = Colors.red.shade600;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
