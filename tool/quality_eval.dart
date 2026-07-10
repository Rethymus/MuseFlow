import 'dart:convert';
import 'dart:io';

import 'package:museflow/features/editor/application/literary_quality_balancer.dart';
import 'package:museflow/features/editor/application/literary_quality_evaluator.dart';

const _corpusPath = 'quality/literary_quality_corpus.json';
const _baselinePath = 'quality/literary_quality_baseline.json';

Future<void> main(List<String> args) async {
  final modes = args.where((arg) => arg.startsWith('--')).toList();
  if (modes.length != 1 ||
      !const {
        '--check',
        '--balance',
        '--update-baseline',
      }.contains(modes.single)) {
    stderr.writeln(
      'Usage: dart run tool/quality_eval.dart '
      '<--check|--balance|--update-baseline>',
    );
    exitCode = 64;
    return;
  }

  final corpus = _readCorpus();
  final mode = modes.single;
  switch (mode) {
    case '--check':
      _check(corpus);
    case '--balance':
      _balance(corpus);
    case '--update-baseline':
      await _updateBaseline(corpus);
  }
}

LiteraryQualityCorpus _readCorpus() {
  final json = jsonDecode(File(_corpusPath).readAsStringSync());
  return LiteraryQualityCorpus.fromJson(json as Map<String, dynamic>);
}

LiteraryQualityBaseline _readBaseline() {
  final json = jsonDecode(File(_baselinePath).readAsStringSync());
  return LiteraryQualityBaseline.fromJson(json as Map<String, dynamic>);
}

void _check(LiteraryQualityCorpus corpus) {
  final baseline = _readBaseline();
  if (baseline.corpusVersion != corpus.version) {
    stderr.writeln(
      'FAIL corpus version ${corpus.version} does not match baseline '
      '${baseline.corpusVersion}',
    );
    exitCode = 1;
    return;
  }
  const evaluator = LiteraryQualityEvaluator();
  final evaluation = evaluator.evaluate(
    corpus: corpus,
    config: baseline.config,
  );
  final check = baseline.compare(
    config: evaluation.config,
    metrics: evaluation.metrics,
  );
  _printMetrics('check', evaluation.metrics);
  if (!check.passed) {
    for (final failure in check.failures) {
      stderr.writeln('FAIL $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('PASS literary quality baseline is stable');
}

void _balance(LiteraryQualityCorpus corpus) {
  final baseline = _readBaseline();
  const balancer = LiteraryQualityBalancer();
  final result = balancer.balance(corpus: corpus);
  _printMetrics(
    'balance (${result.candidateCount} candidates)',
    result.metrics,
  );
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(result.config.toJson()),
  );
  if (result.config != baseline.config) {
    stderr.writeln(
      'FAIL committed config is not the deterministic balance recommendation',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('PASS committed config matches balance recommendation');
}

Future<void> _updateBaseline(LiteraryQualityCorpus corpus) async {
  const balancer = LiteraryQualityBalancer();
  final result = balancer.balance(corpus: corpus);
  final baseline = LiteraryQualityBaseline(
    corpusVersion: corpus.version,
    config: result.config,
    metrics: result.metrics,
    minimumBalancedAccuracy: 0.85,
    minimumRecall: 0.75,
    maximumFalsePositiveRate: 0.1,
  );
  final output =
      '${const JsonEncoder.withIndent('  ').convert(baseline.toJson())}\n';
  await File(_baselinePath).writeAsString(output);
  _printMetrics('updated baseline', result.metrics);
  stdout.writeln('WROTE $_baselinePath');
}

void _printMetrics(String label, LiteraryQualityMetrics metrics) {
  stdout.writeln(
    '$label: balancedAccuracy=${metrics.balancedAccuracy.toStringAsFixed(3)} '
    'recall=${metrics.recall.toStringAsFixed(3)} '
    'falsePositiveRate=${metrics.falsePositiveRate.toStringAsFixed(3)} '
    'separation=${metrics.scoreSeparation.toStringAsFixed(1)}',
  );
}
