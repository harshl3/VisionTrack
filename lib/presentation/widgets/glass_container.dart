import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Core Glassmorphic Container with Gaussian blur, semi-transparent gradient/color,
/// glowing borders, and rounded corners.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.blur = 12.0,
    this.backgroundColor = AppColors.glassBackground,
    this.borderColor = AppColors.glassBorder,
    this.borderWidth = 1.0,
    this.gradient,
    this.boxShadow,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass Card helper widget for list items, stats cards, and dialogs.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = GlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: 16,
      blur: 14,
      backgroundColor: AppColors.glassCardBg,
      borderColor: borderColor ?? AppColors.glassBorder,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}

/// Item definition for [GlassBottomNavBar].
class GlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color activeColor;

  const GlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.activeColor = AppColors.accentBlue,
  });
}

/// Custom Frosted Floating Bottom Navigation Bar for Admin and Surveyor.
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassContainer(
          height: 68,
          borderRadius: 24,
          blur: 20,
          backgroundColor: AppColors.glassNavBg,
          borderColor: AppColors.glassBorderGlow,
          borderWidth: 1.2,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              final iconColor = isSelected ? item.activeColor : AppColors.textGrey;

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 14 : 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? item.activeColor.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? item.activeColor.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                        color: iconColor,
                        size: 24,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: item.activeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic Styled TextField
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onSubmitted;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.4), fontSize: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.accentBlue, size: 20) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.2),
        ),
      ),
    );
  }
}
