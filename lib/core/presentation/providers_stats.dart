part of 'providers.dart';

/// Extracted from providers.dart to satisfy the 03-flutter-standards.md file-size cap.
/// Same library — providers reference each other via bare names unchanged.

final writingStatsRepositoryProvider = FutureProvider<WritingStatsRepository>((
  ref,
) async {
  final aggregateBox = await Hive.openBox<dynamic>('writing_stats');
  final dailyBox = await Hive.openBox<dynamic>('daily_writing_stats');
  final badgeBox = await Hive.openBox<dynamic>('achievement_badges');
  return WritingStatsRepository(aggregateBox, dailyBox, badgeBox);
});

final writingStatsCollectorProvider = FutureProvider<WritingStatsCollector>((
  ref,
) async {
  final repository = await ref.watch(writingStatsRepositoryProvider.future);
  final collector = WritingStatsCollector(repository);
  ref.onDispose(collector.dispose);
  return collector;
});

final writingStatsNotifierProvider =
    AsyncNotifierProvider<WritingStatsNotifier, StatsSnapshot>(
      WritingStatsNotifier.new,
    );

// Token Audit Providers
final tokenAuditRepositoryProvider = FutureProvider<TokenAuditRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('token_audit');
  return TokenAuditRepository(box);
});

final tokenAuditServiceProvider = FutureProvider<TokenAuditService>((
  ref,
) async {
  final repository = await ref.watch(tokenAuditRepositoryProvider.future);
  final calculator = TokenBudgetCalculator();
  final service = TokenAuditService(repository, calculator);
  ref.onDispose(service.dispose);
  return service;
});

final tokenAuditNotifierProvider =
    AsyncNotifierProvider<TokenAuditNotifier, TokenAuditSnapshot>(
      TokenAuditNotifier.new,
    );

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return const AchievementService();
});

final achievementNotifierProvider =
    AsyncNotifierProvider<AchievementNotifier, List<AchievementBadge>>(
      AchievementNotifier.new,
    );
