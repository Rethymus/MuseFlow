import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';

/// Notifier for token audit state.
///
/// Follows the same AsyncNotifier pattern as WritingStatsNotifier.
/// Loads aggregated audit data from the repository.
class TokenAuditNotifier extends AsyncNotifier<TokenAuditSnapshot> {
  @override
  Future<TokenAuditSnapshot> build() async {
    final repository = await ref.watch(tokenAuditRepositoryProvider.future);
    return repository.buildSnapshot();
  }

  /// Refreshes the audit snapshot from the repository.
  Future<void> refresh() async {
    final repository = await ref.read(tokenAuditRepositoryProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.buildSnapshot);
  }

  /// Clears all audit records.
  Future<void> clearAll() async {
    final repository = await ref.read(tokenAuditRepositoryProvider.future);
    await repository.clearAll();
    state = const AsyncData(TokenAuditSnapshot());
  }
}
