/// Tests for [DialogueActClassifier] — CI-01 PATHs dialogue-act recognition.
///
/// Per Mysore et al. (EMNLP 2025 SAC Highlight): human-AI creative collaboration
/// falls into 5 recurring dialogue acts. Recognizing the act lets the AI adapt
/// its response strategy (style requests need restraint, exploration needs
/// options, intent revision needs clarification, follow-ups need depth,
/// injection needs faithful insertion).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/dialogue_act.dart';
import 'package:museflow/features/ai/application/dialogue_act_classifier.dart';

void main() {
  const classifier = DialogueActClassifier();

  group('DialogueActClassifier CI-01 PATHs dialogue acts', () {
    test('style adjustment: user asks to change tone/style', () {
      expect(
        classifier.classify('帮我把这段改得更正式一点').act,
        DialogueAct.styleAdjustment,
      );
      expect(classifier.classify('换个口语化的语气').act, DialogueAct.styleAdjustment);
    });

    test('content exploration: user explores alternatives ("what if")', () {
      expect(
        classifier.classify('如果他这个时候没有出现会怎样').act,
        DialogueAct.contentExploration,
      );
      expect(
        classifier.classify('试试另一个方向，让主角直接离开').act,
        DialogueAct.contentExploration,
      );
    });

    test('intent revision: user corrects the AI', () {
      expect(
        classifier.classify('不对，我要的不是这个意思').act,
        DialogueAct.intentRevision,
      );
      expect(
        classifier.classify('我的意思是让他更狠一点，重新理解一下').act,
        DialogueAct.intentRevision,
      );
    });

    test('follow-up: user asks for more depth', () {
      expect(classifier.classify('为什么他会这么做？展开说说').act, DialogueAct.followUp);
      expect(classifier.classify('这里的具体细节能再详细一点吗').act, DialogueAct.followUp);
    });

    test('injection: user asks to insert/add content', () {
      expect(classifier.classify('在这里加入一段环境描写').act, DialogueAct.injection);
      expect(
        classifier.classify('补充一段对话，写两人在月下的交谈').act,
        DialogueAct.injection,
      );
    });

    test('ambiguous / unmatched message defaults to followUp', () {
      // A bare prompt with no clear act signal — safest default is to give
      // more (followUp) rather than mis-route to injection/style.
      expect(classifier.classify('嗯，还行吧').act, DialogueAct.followUp);
    });
  });

  group('DialogueActClassification metadata', () {
    test('exposes matched signal keywords (explainability)', () {
      final result = classifier.classify('在这里加入一段描写');
      expect(result.act, DialogueAct.injection);
      expect(result.matchedKeywords, isNotEmpty);
    });

    test('confidence is in [0, 1]', () {
      for (final msg in ['改语气', '如果他没来', '不对', '为什么', '加一段', '嗯']) {
        final c = classifier.classify(msg).confidence;
        expect(c, greaterThanOrEqualTo(0));
        expect(c, lessThanOrEqualTo(1));
      }
    });
  });

  group('DialogueAct labels', () {
    test('every act has a Chinese display label', () {
      for (final act in DialogueAct.values) {
        expect(act.label, isNotEmpty);
      }
    });
  });
}
