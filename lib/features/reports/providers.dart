import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/reports/application/pain_point_report_service.dart';
import 'package:museflow/features/reports/application/token_cost_report_service.dart';
import 'package:museflow/features/reports/domain/pain_point_report.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';

final tokenCostReportServiceProvider = FutureProvider<TokenCostReportService>((
  ref,
) async {
  final auditRepository = await ref.watch(tokenAuditRepositoryProvider.future);
  final chapterRepository = await ref.watch(chapterRepositoryProvider.future);
  return TokenCostReportService(
    auditRepository: auditRepository,
    chapterRepository: chapterRepository,
  );
});

final tokenCostReportProvider =
    AsyncNotifierProvider<TokenCostReportNotifier, TokenCostReport>(
      TokenCostReportNotifier.new,
    );

class TokenCostReportNotifier extends AsyncNotifier<TokenCostReport> {
  @override
  Future<TokenCostReport> build() async {
    final service = await ref.watch(tokenCostReportServiceProvider.future);
    return service.generate();
  }

  Future<void> refresh() async {
    final service = await ref.read(tokenCostReportServiceProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(service.generate);
  }
}

final painPointReportServiceProvider = Provider<PainPointReportService>((ref) {
  return const PainPointReportService();
});

final painPointReportProvider =
    AsyncNotifierProvider<PainPointReportNotifier, PainPointReport>(
      PainPointReportNotifier.new,
    );

class PainPointReportNotifier extends AsyncNotifier<PainPointReport> {
  @override
  Future<PainPointReport> build() async {
    return ref.watch(painPointReportServiceProvider).generate();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => ref.read(painPointReportServiceProvider).generate(),
    );
  }
}
