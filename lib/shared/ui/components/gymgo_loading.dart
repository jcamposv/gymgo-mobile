import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';

/// Loading overlay for full-screen loading states
class GymGoLoadingOverlay extends StatelessWidget {
  const GymGoLoadingOverlay({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GymGoColors.overlayDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(GymGoColors.primary),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: GymGoSpacing.lg),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline loading spinner
class GymGoLoadingSpinner extends StatelessWidget {
  const GymGoLoadingSpinner({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? GymGoColors.primary,
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder
class GymGoShimmer extends StatelessWidget {
  const GymGoShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: GymGoColors.shimmerBase,
      highlightColor: GymGoColors.shimmerHighlight,
      child: child,
    );
  }
}

/// Shimmer box for placeholder content
class GymGoShimmerBox extends StatelessWidget {
  const GymGoShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GymGoShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GymGoColors.shimmerBase,
          borderRadius: BorderRadius.circular(
            borderRadius ?? GymGoSpacing.radiusSm,
          ),
        ),
      ),
    );
  }
}

/// Loading state wrapper that shows loading or content
class GymGoLoadingState extends StatelessWidget {
  const GymGoLoadingState({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
  });

  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: GymGoLoadingSpinner(size: 32),
          );
    }
    return child;
  }
}
