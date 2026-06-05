import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/templates/domain/world_template.dart';

void main() {
  group('WorldTemplate domain', () {
    test('parses library and converts sources to knowledge entities', () {
      final library = WorldTemplateLibrary.fromJson(_sampleLibraryJson());

      expect(library.templateSchemaVersion, 1);
      expect(library.language, 'zh-CN');
      expect(library.templates, hasLength(1));

      final template = library.templates.single;
      expect(template.channel, TemplateChannel.male);
      expect(template.displayTitle, '玄幻｜血脉觉醒');
      expect(template.matchesQuery('血脉'), isTrue);
      expect(template.matchesQuery('宗族'), isTrue);
      expect(template.matchesQuery('不存在'), isFalse);

      final setting = template.world.toWorldSetting();
      expect(setting.id, isEmpty);
      expect(setting.name, '断岳九州');

      final card = template.characters.first.toCharacterCard();
      expect(card.id, isEmpty);
      expect(card.name, '边地少年');
    });

    test('rejects unknown channel and opening sample style', () {
      expect(() => TemplateChannel.fromString('unknown'), throwsArgumentError);
      expect(
        () => OpeningSampleStyle.fromString('unknown'),
        throwsArgumentError,
      );
    });

    test('foreshadowing arc displays setup development payoff', () {
      const arc = ForeshadowingArc(
        setup: '起点',
        development: '发展',
        payoff: '回收',
      );

      expect(arc.displayText, '起点 -> 发展 -> 回收');
    });
  });
}

Map<String, dynamic> _sampleLibraryJson() {
  return {
    'templateSchemaVersion': 1,
    'language': 'zh-CN',
    'templates': [
      {
        'id': 'male-xuanhuan-bloodline',
        'channel': 'male',
        'sortOrder': 1,
        'genreName': '玄幻',
        'subtitle': '血脉觉醒',
        'description': '边地少年与宗族秘史。',
        'iconName': 'auto_awesome',
        'tags': ['血脉', '宗族', '逆袭', '秘境', '天命'],
        'review': {
          'sourceNote': 'reviewed',
          'reviewedAt': '2026-06-04T00:00:00.000Z',
          'qualityChecks': ['valid'],
        },
        'world': {
          'name': '断岳九州',
          'description': '九州被山脉分隔。',
          'rules': '血脉可共鸣。',
          'factions': '镇岳宗。',
          'geography': '北境雪岭。',
          'techLevel': '灵器。',
          'aliases': ['九州'],
        },
        'characters': [
          {
            'name': '边地少年',
            'personality': '倔强',
            'appearance': '旧皮甲',
            'backstory': '矿难中觉醒。',
            'aliases': ['少主'],
          },
        ],
        'foreshadowingArcs': [
          {'setup': '起点', 'development': '发展', 'payoff': '回收'},
        ],
        'openingSamples': [
          {'style': 'scene', 'text': '场景'},
          {'style': 'character', 'text': '人物'},
          {'style': 'suspense', 'text': '悬念'},
        ],
      },
    ],
  };
}
