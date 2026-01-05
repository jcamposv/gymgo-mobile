import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../providers/branding_providers.dart';

/// Logo variant types
enum GymLogoVariant {
  /// Full logo with text (default)
  full,
  /// Icon only (compact)
  icon,
}

/// Reusable gym logo widget that shows custom gym logo or default GymGo logo
class GymLogo extends ConsumerWidget {
  const GymLogo({
    super.key,
    this.height = 32,
    this.variant = GymLogoVariant.full,
    this.color,
  });

  /// Height of the logo (width adjusts automatically)
  final double height;

  /// Logo variant (full with text or icon only)
  final GymLogoVariant variant;

  /// Optional color override for the default logo
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandingAsync = ref.watch(gymBrandingProvider);

    return brandingAsync.when(
      data: (branding) {
        if (branding.hasCustomLogo) {
          return _buildNetworkLogo(branding.logoUrl!);
        }
        return _buildDefaultLogo();
      },
      loading: () => _buildDefaultLogo(),
      error: (_, __) => _buildDefaultLogo(),
    );
  }

  Widget _buildNetworkLogo(String url) {
    // Check if it's an SVG
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        height: height,
        placeholderBuilder: (_) => _buildDefaultLogo(),
      );
    }

    // Regular image (PNG, JPG, etc.)
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, __) => _buildDefaultLogo(),
      errorWidget: (_, __, ___) => _buildDefaultLogo(),
    );
  }

  Widget _buildDefaultLogo() {
    final assetPath = variant == GymLogoVariant.icon
        ? 'assets/images/gymgo_icon.svg'
        : 'assets/images/gymgo_logo.svg';

    return SvgPicture.asset(
      assetPath,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Simple version without Riverpod - for use in places where providers aren't available
class GymLogoStatic extends StatelessWidget {
  const GymLogoStatic({
    super.key,
    this.height = 32,
    this.variant = GymLogoVariant.full,
    this.logoUrl,
    this.color,
  });

  final double height;
  final GymLogoVariant variant;
  final String? logoUrl;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return _buildNetworkLogo(logoUrl!);
    }
    return _buildDefaultLogo();
  }

  Widget _buildNetworkLogo(String url) {
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        height: height,
        placeholderBuilder: (_) => _buildDefaultLogo(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, __) => _buildDefaultLogo(),
      errorWidget: (_, __, ___) => _buildDefaultLogo(),
    );
  }

  Widget _buildDefaultLogo() {
    final assetPath = variant == GymLogoVariant.icon
        ? 'assets/images/gymgo_icon.svg'
        : 'assets/images/gymgo_logo.svg';

    return SvgPicture.asset(
      assetPath,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Text-based gym name widget with dynamic branding
class GymName extends ConsumerWidget {
  const GymName({
    super.key,
    this.style,
  });

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymName = ref.watch(gymNameProvider);

    return Text(
      gymName,
      style: style ?? TextStyle(
        color: GymGoColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
