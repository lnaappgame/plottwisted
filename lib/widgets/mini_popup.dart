import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MiniPopup extends StatelessWidget {
  final String text;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final AppColors colors;

  const MiniPopup({
    super.key,
    required this.text,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [colors.bgPanel2, colors.bgPanel]),
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: AppTextStyles.body(size: 13, color: colors.cream).copyWith(height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.muted,
                        side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(secondaryLabel, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: colors.muted)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF1A1410),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(primaryLabel, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: const Color(0xFF1A1410))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
