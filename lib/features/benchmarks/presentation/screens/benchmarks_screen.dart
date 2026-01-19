import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';
import '../widgets/benchmark_category_card.dart';

/// Main Benchmarks screen with category grid menu
class BenchmarksScreen extends StatelessWidget {
  const BenchmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: GymGoColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: GymGoColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Benchmarks',
          style: GymGoTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Text(
                'Registra y sigue tu progreso',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
              const SizedBox(height: GymGoSpacing.xl),

              // Category Grid (2 columns)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: GymGoSpacing.md,
                    mainAxisSpacing: GymGoSpacing.md,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: BenchmarkCategory.categories.length,
                  itemBuilder: (context, index) {
                    final category = BenchmarkCategory.categories[index];
                    return BenchmarkCategoryCard(
                      category: category,
                      onTap: () => context.push(category.route),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
