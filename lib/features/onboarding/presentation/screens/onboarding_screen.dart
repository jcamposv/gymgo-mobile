import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/gymgo_primary_button.dart';
import '../providers/onboarding_providers.dart';

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _slides = [
  _SlideData(
    icon: LucideIcons.calendarCheck,
    title: 'Reserva tus clases',
    description: 'Consulta el horario y reserva tu lugar con un solo tap',
  ),
  _SlideData(
    icon: LucideIcons.dumbbell,
    title: 'Sigue tu rutina',
    description:
        'Entrenamientos personalizados día a día para alcanzar tus objetivos',
  ),
  _SlideData(
    icon: LucideIcons.layoutDashboard,
    title: 'Todo en un lugar',
    description: 'Membresía, progreso y métricas al alcance de tu mano',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await completeOnboarding(ref);
    if (!mounted) return;
    context.go(Routes.login);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: GymGoSpacing.sm,
                  right: GymGoSpacing.md,
                ),
                child: GymGoTextButton(
                  text: 'Saltar',
                  onPressed: _finish,
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _SlideContent(slide: slide);
                },
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _DotIndicator(isActive: index == _currentPage),
                ),
              ),
            ),

            // Next / Comenzar button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
              ),
              child: GymGoPrimaryButton(
                text: _currentPage == _slides.length - 1
                    ? 'Comenzar'
                    : 'Siguiente',
                onPressed: _next,
              ),
            ),

            const SizedBox(height: GymGoSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: GymGoColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 56,
              color: GymGoColors.primary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xl),
          Text(
            slide.title,
            style: GymGoTypography.displaySmall.copyWith(
              color: GymGoColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            slide.description,
            style: GymGoTypography.bodyLarge.copyWith(
              color: GymGoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? GymGoColors.primary : GymGoColors.textDisabled,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
    );
  }
}
