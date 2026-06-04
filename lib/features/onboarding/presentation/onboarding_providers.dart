import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/onboarding/infrastructure/onboarding_progress_repository.dart';

/// Provides an [OnboardingProgressRepository] backed by a Hive box.
///
/// This provider is scoped to the onboarding feature to avoid coupling
/// to the shared providers.dart (which has unresolved imports from Phase 7).
///
/// In production, the wizard page uses this provider directly.
/// The shared onboardingProgressProvider in providers.dart is also
/// registered for redirect guard access.
final onboardingRepositoryProvider =
    FutureProvider<OnboardingProgressRepository>((ref) async {
  final box = await Hive.openBox('settings');
  return OnboardingProgressRepository(box);
});
