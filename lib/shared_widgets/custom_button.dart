import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable custom button widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final bool isExpanded;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  /// Primary button constructor
  const CustomButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  }) : style = null;

  /// Secondary button constructor
  const CustomButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  }) : style = const ButtonStyle();

  /// Outlined button constructor
  const CustomButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  }) : style = const ButtonStyle();

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final content = _buildButtonContent();

    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: icon!,
            label: content,
            style: buttonStyle,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: content,
          );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  /// Build button content with loading state
  Widget _buildButtonContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppConstants.textOnPrimaryColor,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  /// Get button style based on type
  ButtonStyle _getButtonStyle() {
    if (style != null) {
      return style!;
    }

    // Default primary button style
    return ElevatedButton.styleFrom(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: AppConstants.textOnPrimaryColor,
      textStyle: AppConstants.buttonTextMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      elevation: AppConstants.elevationS,
    );
  }
}

/// Secondary button widget
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isExpanded;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppConstants.secondaryColor,
      foregroundColor: AppConstants.textOnPrimaryColor,
      textStyle: AppConstants.buttonTextMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      elevation: AppConstants.elevationS,
    );

    final content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.textOnPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(text),
            ],
          )
        : Text(text);

    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: icon!,
            label: content,
            style: buttonStyle,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: content,
          );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Outlined button widget
class OutlinedCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? borderColor;
  final Color? textColor;

  const OutlinedCustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: textColor ?? AppConstants.primaryColor,
      textStyle: AppConstants.buttonTextMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      side: BorderSide(
        color: borderColor ?? AppConstants.primaryColor,
        width: 1.5,
      ),
    );

    final content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppConstants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(text),
            ],
          )
        : Text(text);

    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: icon!,
            label: content,
            style: buttonStyle,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: content,
          );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Text button widget
class TextCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final Color? textColor;

  const TextCustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: textColor ?? AppConstants.primaryColor,
      textStyle: AppConstants.buttonTextMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
    );

    final content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppConstants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(text),
            ],
          )
        : Text(text);

    return icon != null
        ? TextButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: icon!,
            label: content,
            style: buttonStyle,
          )
        : TextButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: content,
          );
  }
}
