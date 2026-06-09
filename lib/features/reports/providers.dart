import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/reports/application/blind_read_service.dart';
import 'package:museflow/features/reports/application/consistency_analysis_service.dart';
import 'package:museflow/features/reports/application/pain_point_report_service.dart';
import 'package:museflow/features/reports/application/token_cost_report_service.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';
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

final blindReadServiceProvider = FutureProvider<BlindReadService>((ref) async {
  final chapterRepository = await ref.watch(chapterRepositoryProvider.future);
  return BlindReadService(chapterRepository: chapterRepository);
});

final blindReadProvider = NotifierProvider<BlindReadNotifier, BlindReadState>(
  BlindReadNotifier.new,
);

class BlindReadState {
  const BlindReadState({
    this.excerpts = const [],
    this.currentIndex = 0,
    this.result,
  });

  final List<BlindReadExcerpt> excerpts;
  final int currentIndex;
  final BlindReadResult? result;

  bool get hasStarted => excerpts.isNotEmpty;
  bool get isComplete => result != null;
  BlindReadExcerpt? get currentExcerpt =>
      currentIndex >= 0 && currentIndex < excerpts.length
      ? excerpts[currentIndex]
      : null;

  BlindReadState copyWith({
    List<BlindReadExcerpt>? excerpts,
    int? currentIndex,
    BlindReadResult? result,
    bool clearResult = false,
  }) {
    return BlindReadState(
      excerpts: excerpts ?? this.excerpts,
      currentIndex: currentIndex ?? this.currentIndex,
      result: clearResult ? null : result ?? this.result,
    );
  }
}

class BlindReadNotifier extends Notifier<BlindReadState> {
  @override
  BlindReadState build() => const BlindReadState();

  Future<void> startEvaluation({String? manuscriptId}) async {
    final service = await ref.read(blindReadServiceProvider.future);
    final excerpts = service.selectExcerpts(manuscriptId: manuscriptId);
    state = BlindReadState(excerpts: excerpts);
    if (excerpts.isEmpty) {
      state = state.copyWith(result: service.computeResult(excerpts));
    }
  }

  void judgeExcerpt(bool verdict) {
    final index = state.currentIndex;
    if (index < 0 || index >= state.excerpts.length || state.isComplete) return;
    final updated = state.excerpts
        .asMap()
        .entries
        .map(
          (entry) => entry.key == index
              ? entry.value.copyWith(humanVerdict: verdict)
              : entry.value,
        )
        .toList(growable: false);
    _advance(updated);
  }

  void skipExcerpt() {
    if (state.isComplete) return;
    _advance(state.excerpts);
  }

  void reset() {
    state = const BlindReadState();
  }

  void _advance(List<BlindReadExcerpt> excerpts) {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= excerpts.length) {
      final service = ref.read(blindReadServiceProvider).requireValue;
      state = state.copyWith(
        excerpts: excerpts,
        result: service.computeResult(excerpts),
      );
      return;
    }
    state = state.copyWith(excerpts: excerpts, currentIndex: nextIndex);
  }
}

final consistencyReportServiceProvider =
    FutureProvider<ConsistencyAnalysisService>((ref) async {
      final characterRepository = await ref.watch(
        characterCardRepositoryProvider.future,
      );
      final worldSettingRepository = await ref.watch(
        worldSettingRepositoryProvider.future,
      );
      final skillRepository = await ref.watch(skillRepositoryProvider.future);
      final chapterRepository = await ref.watch(
        chapterRepositoryProvider.future,
      );
      final nameIndex = ref.watch(nameIndexServiceProvider);
      return ConsistencyAnalysisService(
        characterCardRepository: characterRepository,
        worldSettingRepository: worldSettingRepository,
        skillRepository: skillRepository,
        chapterRepository: chapterRepository,
        nameIndex: nameIndex,
      );
    });

final consistencyReportProvider =
    AsyncNotifierProvider<ConsistencyReportNotifier, ConsistencyReport>(
      ConsistencyReportNotifier.new,
    );

class ConsistencyReportNotifier extends AsyncNotifier<ConsistencyReport> {
  @override
  Future<ConsistencyReport> build() async {
    final service = await ref.watch(consistencyReportServiceProvider.future);
    return service.analyze();
  }

  Future<void> refresh({String? manuscriptId}) async {
    final service = await ref.read(consistencyReportServiceProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => service.analyze(manuscriptId));
  }
}
